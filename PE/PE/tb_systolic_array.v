`timescale 1ns / 1ps

module tb_systolic_array;

    // --- 1. KHAI BÁO TÍN HIỆU ---
    reg clk;
    reg rst;
    reg load_en;

    // Dữ liệu Input thô (Chưa skew) từ Testbench nạp vào
    reg [63:0] ifmap_raw; 

    // Dữ liệu đã Skew (Từ Buffer -> đi vào Array)
    wire [63:0] ifmap_skewed_wire;

    // Trọng số (Weights) - 24 PE x 16 bit
    reg [383:0] weights_in;

    // Output cuối cùng (6 cột x 16 bit)
    wire [95:0] psum_south_out;

    // Biến hỗ trợ vòng lặp
    integer k;

    // --- 2. KẾT NỐI MODULE (TOP LEVEL) ---

    // A. Module Skew Buffer (Làm lệch thời gian input)
    Data_Skew_Buffer u_skew_buffer (
        .clk(clk),
        .rst(rst),
        .ifmap_in(ifmap_raw),           // Nhận từ TB
        .ifmap_skewed(ifmap_skewed_wire) // Xuất ra dây nối
    );

    // B. Module Systolic Array (Module chính)
    Systolic_Array_4x6 u_array (
        .clk(clk),
        .rst(rst),
        .load_en(load_en),
        .ifmap_west_in(ifmap_skewed_wire), // Nhận từ dây nối (đã skew)
        .weights_in(weights_in),
        .psum_south_out(psum_south_out)
    );

    // --- 3. TẠO CLOCK (100MHz) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Chu kỳ 10ns
    end

    // --- 4. TASK HỖ TRỢ NẠP DỮ LIỆU NHANH ---
    task drive_input(input [15:0] r3, input [15:0] r2, input [15:0] r1, input [15:0] r0);
        begin
            ifmap_raw = {r3, r2, r1, r0};
            @(posedge clk); #1; // Chờ 1 clock + 1 chút delay
        end
    endtask

    // --- 5. CHƯƠNG TRÌNH TEST (MAIN) ---
    initial begin
        // === BƯỚC 1: KHỞI TẠO & RESET ===
        $display("--- SIMULATION START ---");
        rst = 1;
        load_en = 0;
        ifmap_raw = 0;
        weights_in = 0;
        
        // Reset trong 20ns
        #20;
        rst = 0;

        // === BƯỚC 2: NẠP TRỌNG SỐ (WEIGHT LOADING) ===
        // Ta sẽ nạp giá trị 1.0 (FP16 = 0x3C00) cho tất cả các PE
        $display("--- STEP 1: LOADING WEIGHTS (All 1.0) ---");
        
        load_en = 1; // Bật chế độ nạp
        for (k = 0; k < 24; k = k + 1) begin
            // 16'h3C00 là biểu diễn Hex của 1.0 trong chuẩn FP16
            weights_in[(k*16) +: 16] = 16'h3C00; 
        end
        
        @(posedge clk); #1; // Chờ nạp xong
        load_en = 0;        // Tắt chế độ nạp -> Chuyển sang tính toán
        #20;                // Nghỉ một chút trước khi tính

        // === BƯỚC 3: ĐẨY DỮ LIỆU VÀO (STREAMING) ===
        $display("--- STEP 2: STREAMING INPUT DATA ---");
        
        // Kịch bản: 
        // Array có 4 hàng. Mỗi hàng có Weight = 1.0.
        // Ta nạp Input = 2.0 (FP16 = 0x4000).
        // Phép tính mỗi hàng: Psum_mới = Psum_cũ + (2.0 * 1.0) = Psum_cũ + 2.0
        // Sau khi qua 4 hàng: Tổng = 2.0 + 2.0 + 2.0 + 2.0 = 8.0
        // Giá trị Hex kỳ vọng của 8.0 là: 16'h4800

        // Nhịp 1: Nạp cột toàn số 2.0
        drive_input(16'h4000, 16'h4000, 16'h4000, 16'h4000);

        // Nhịp 2: Nạp cột toàn số 2.0 tiếp (để test pipeline)
        drive_input(16'h4000, 16'h4000, 16'h4000, 16'h4000);

        // Nhịp 3: Dừng nạp (Input về 0)
        ifmap_raw = 0;
        
        // === BƯỚC 4: CHỜ KẾT QUẢ ===
        // Cần chờ khoảng 10-15 nhịp clock để dữ liệu đi hết qua các tầng
        #200; 
        
        $display("--- SIMULATION FINISHED ---");
        $stop;
    end

    // --- 6. MONITOR (HIỂN THỊ KẾT QUẢ RA MÀN HÌNH) ---
    always @(posedge clk) begin
        #2; // Chờ tín hiệu ổn định sau cạnh lên
        if (!rst && psum_south_out != 0) begin
            // Hiển thị dạng Hex để dễ so sánh với chuẩn FP16
            $display("[%0t] OUTPUT (Hex): %h | %h | %h | %h | %h | %h", 
                     $time, 
                     psum_south_out[15:0],   // Cột 0
                     psum_south_out[31:16],  // Cột 1
                     psum_south_out[47:32],  // Cột 2
                     psum_south_out[63:48],  // Cột 3
                     psum_south_out[79:64],  // Cột 4
                     psum_south_out[95:80]); // Cột 5
        end
    end

endmodule