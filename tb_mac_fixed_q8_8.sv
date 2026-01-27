`timescale 1ns/1ps

module tb_mac_fixed_q8_8;

    logic clk = 0;
    logic rst = 1;
    logic signed [15:0] A, B;
    logic signed [31:0] P;

    mac_fixed_q8_8 dut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .P(P)
    );

    always #5 clk = ~clk;

    function real q16_16_to_real(input signed [31:0] x);
        return x / 65536.0;
    endfunction

    initial begin
        rst = 1; #20; rst = 0;

        // Test 1
        A = 16'd256;    // 1.0
        B = 16'd256;    // 1.0
        #20;
        $display("1.0 x 1.0 = %f", q16_16_to_real(P));

        // Test 2
        A = 16'd512;    // 2.0
        B = 16'd128;    // 0.5
        #20;
        $display("2.0 x 0.5 = %f", q16_16_to_real(P));

        // Test 3
        A = 16'sd32767; // max Q8.8 value
        B = 16'sd32767;
        #20;
        $display("max x max = %f", q16_16_to_real(P));

        #50 $finish;
    end

endmodule
