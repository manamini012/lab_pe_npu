`timescale 1ns / 1ps

module tb_tpu_top;

    // --- Khai báo tín hiệu ---
    reg clk;
    reg rst;
    reg load_en;
    reg [63:0] ifmap_in;
    reg [383:0] weights_in;
    wire [95:0] psum_out;

    integer k;

    // --- Gọi Module Tổng (DUT) ---
    TPU_Top dut (
        .clk(clk),
        .rst(rst),
        .load_en(load_en),
        .ifmap_in(ifmap_in),
        .weights_in(weights_in),
        .psum_out(psum_out)
    );

    // --- Tạo Clock ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Task hỗ trợ ---
    task drive_input(input [15:0] r3, input [15:0] r2, input [15:0] r1, input [15:0] r0);
        begin
            ifmap_in = {r3, r2, r1, r0};
            @(posedge clk); #1;
        end
    endtask

    // --- Chương trình chính ---
    initial begin
        // 1. Khởi tạo
        rst = 1; load_en = 0; ifmap_in = 0; weights_in = 0;
        #20; rst = 0;

        // 2. Nạp Weight (1.0 = 16'h3C00)
        $display("--- LOADING WEIGHTS ---");
        load_en = 1;
        for (k = 0; k < 24; k = k + 1) begin
            weights_in[(k*16) +: 16] = 16'h3C00; 
        end
        @(posedge clk); #1;
        load_en = 0;
        #20;

        // 3. Chạy dữ liệu (Input = 2.0 = 16'h4000)
        $display("--- STREAMING DATA ---");
        drive_input(16'h4000, 16'h4000, 16'h4000, 16'h4000); // Nhịp 1
        drive_input(16'h4000, 16'h4000, 16'h4000, 16'h4000); // Nhịp 2
        ifmap_in = 0;

        // 4. Chờ kết quả
        #600;
        $stop;
    end

    // --- Monitor ---
    always @(posedge clk) begin
        #2;
        if (!rst && psum_out != 0) begin
            $display("[%0t] OUTPUT: %h | %h | %h | %h | %h | %h", 
                     $time, 
                     psum_out[15:0], psum_out[31:16], psum_out[47:32], 
                     psum_out[63:48], psum_out[79:64], psum_out[95:80]);
        end
    end

endmodule