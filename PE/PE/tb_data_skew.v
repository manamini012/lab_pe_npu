`timescale 1ns / 1ps

module tb_data_skew;

    // --- 1. Khai báo tín hiệu ---
    reg clk;
    reg rst;
    reg [63:0] ifmap_in;
    wire [63:0] ifmap_skewed;

    // Tách output ra để monitor
    wire [15:0] out_row0 = ifmap_skewed[15:0];
    wire [15:0] out_row1 = ifmap_skewed[31:16];
    wire [15:0] out_row2 = ifmap_skewed[47:32];
    wire [15:0] out_row3 = ifmap_skewed[63:48];

    // --- 2. Kết nối DUT ---
    Data_Skew_Buffer uut (
        .clk(clk),
        .rst(rst),
        .ifmap_in(ifmap_in),
        .ifmap_skewed(ifmap_skewed)
    );

    // --- 3. Tạo xung Clock ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 4. Task Drive Data ---
    // Task này giúp code gọn hơn
    task drive_data(input [15:0] r3, input [15:0] r2, input [15:0] r1, input [15:0] r0);
        begin // <--- Mở BEGIN của task
            ifmap_in = {r3, r2, r1, r0};
            @(posedge clk); #1;
        end   // <--- Đóng END của task (KIỂM TRA KỸ DÒNG NÀY)
    endtask

    // --- 5. Chương trình chính (Main Test) ---
    initial begin // <--- Mở BEGIN của initial
        // Reset
        rst = 1; ifmap_in = 0;
        #20;
        rst = 0;
        $display("--- SIMULATION START ---");

        // Test Case 1: Nạp 1111, 2222, 3333, 4444
        drive_data(16'h4444, 16'h3333, 16'h2222, 16'h1111);

        // Test Case 2: Nạp 5555, 6666, 7777, 8888
        drive_data(16'h8888, 16'h7777, 16'h6666, 16'h5555);

        // Dừng nạp
        ifmap_in = 0;
        @(posedge clk); #1;

        // Chờ kết quả
        #100;
        $display("--- SIMULATION FINISHED ---");
        $stop;
    end // <--- Đóng END của initial (Lỗi thường ở đây nếu thiếu)

    // --- 6. Monitor ---
    always @(posedge clk) begin // <--- Mở BEGIN của always
        #2;
        if (rst == 0) begin // <--- Mở BEGIN của if
            $display("[%0t] Out -> R0:%h | R1:%h | R2:%h | R3:%h", 
                     $time, out_row0, out_row1, out_row2, out_row3);
        end // <--- Đóng END của if
    end // <--- Đóng END của always

endmodule // <--- Kết thúc module