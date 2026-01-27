`timescale 1ns / 1ps

module tb_pe_fp16;

    // --- 1. Khai báo tín hiệu ---
    reg clk;
    reg rst;
    reg load_en;
    reg [15:0] ifmap_in;
    reg [15:0] weight_in;
    reg [15:0] psum_in;

    wire [15:0] ifmap_out;
    wire [15:0] psum_out;

    // --- 2. Kết nối Unit Under Test (UUT) ---
    pe_fp16 uut (
        .clk(clk),
        .rst(rst),
        .load_en(load_en),
        .ifmap_in(ifmap_in),
        .weight_in(weight_in),
        .psum_in(psum_in),
        .ifmap_out(ifmap_out),
        .psum_out(psum_out)
    );

    // --- 3. Tạo xung Clock (100MHz) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 4. Các Helper Task (Quan trọng) ---

    // Task 1: Nạp trọng số (Load Weight)
    task load_weight(input [15:0] w_val);
        begin
            @(posedge clk); #1; // Đồng bộ cạnh lên
            load_en = 1;
            weight_in = w_val;
            
            @(posedge clk); #1; // Giữ 1 chu kỳ
            load_en = 0;
            weight_in = 0;
            $display("\n[%0t] === LOAD WEIGHT: %h ===", $time, w_val);
        end
    endtask

    // Task 2: Đẩy dữ liệu đơn lẻ (Single Pulse) - Dùng cho Kịch bản 1 & 2
    // Task này sẽ giữ input 1 chu kỳ rồi tự về 0 -> Không lo bị ghi đè
    task drive_single(input [15:0] ifmap, input [15:0] psum, input [8*40:1] desc);
        begin
            @(posedge clk); #1;
            ifmap_in = ifmap;
            psum_in = psum;
            $display("[%0t] IN  -> Ifmap: %h, Psum: %h | %s", $time, ifmap, psum, desc);

            @(posedge clk); #1; // CHỜ 1 CHU KỲ ĐỂ MẠCH KỊP NHẬN
            ifmap_in = 0;
            psum_in = 0;
        end
    endtask

    // --- 5. Chương trình Test Chính ---
    initial begin
        // Khởi tạo giá trị ban đầu
        rst = 1; load_en = 0; ifmap_in = 0; psum_in = 0; weight_in = 0;
        
        // Reset hệ thống
        #20; rst = 0; #10;
        $display("--- SIMULATION START ---");

        // ============================================================
        // KỊCH BẢN 1: WEIGHT = 1.0 (Hex: 3C00)
        // ============================================================
        load_weight(16'h3C00); 
        #20; 

        // Test 1.1: 0.0 * 1.0 + 5.0 = 5.0
        drive_single(16'h0000, 16'h4500, "Zero Check: Expect 5.0 (4500)");
        #50; // Chờ kết quả chảy ra hết

        // Test 1.2: 2.0 * 1.0 + 3.0 = 5.0
        drive_single(16'h4000, 16'h4200, "Basic Add: Expect 5.0 (4500)");
        #50;

        // Test 1.3: -2.0 * 1.0 + 3.0 = 1.0 (Lỗi cũ của bạn ở đây)
        // Bây giờ drive_single đã tự giữ tín hiệu, nên sẽ chạy đúng.
        drive_single(16'hC000, 16'h4200, "Neg Input: Expect 1.0 (3C00)");
        #50;

        // ============================================================
        // KỊCH BẢN 2: WEIGHT = -0.5 (Hex: B800)
        // ============================================================
        load_weight(16'hB800);
        #20;

        // Test 2.1: 4.0 * -0.5 + 10.0 = -2.0 + 10.0 = 8.0
        drive_single(16'h4400, 16'h4900, "Pos*Neg: Expect 8.0 (4800)");
        #50;

        // Test 2.2: -4.0 * -0.5 + 0.0 = 2.0 + 0.0 = 2.0 (Lỗi Neg*Neg)
        drive_single(16'hC400, 16'h0000, "Neg*Neg: Expect 2.0 (4000)");
        #50;

        // ============================================================
        // KỊCH BẢN 3: STRESS TEST (Weight = 2.0 -> 4000)
        // Bơm dữ liệu liên tục (Streaming)
        // ============================================================
        $display("\n[%0t] === START PIPELINE STRESS TEST ===", $time);
        load_weight(16'h4000); 
        #10;

        // Bơm liên tục (Không về 0 giữa chừng)
        @(posedge clk); #1; ifmap_in = 16'h3C00; psum_in = 16'h0000; // T1: 1.0 * 2 + 0 = 2.0
        @(posedge clk); #1; ifmap_in = 16'h4000; psum_in = 16'h0000; // T2: 2.0 * 2 + 0 = 4.0
        @(posedge clk); #1; ifmap_in = 16'h4200; psum_in = 16'h3C00; // T3: 3.0 * 2 + 1 = 7.0
        @(posedge clk); #1; ifmap_in = 16'h3800; psum_in = 16'h3800; // T4: 0.5 * 2 + 0.5 = 1.5
        
        // Dừng bơm
        @(posedge clk); #1; ifmap_in = 0; psum_in = 0;

        #200; // Chờ cho kết quả pipeline chảy ra hết
        $display("--- SIMULATION FINISHED ---");
        $stop;
    end

    // --- 6. Monitor Tự động ---
    // In kết quả mỗi khi có output khác 0
    always @(posedge clk) begin
        // Chờ 1 chút sau cạnh lên để lấy giá trị ổn định
        #2; 
        if (psum_out != 0 || ifmap_out != 0) begin
            $display("[%0t] OUT -> Ifmap_out: %h, Psum_out: %h", $time, ifmap_out, psum_out);
        end
    end

endmodule