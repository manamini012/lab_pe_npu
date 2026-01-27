`timescale 1ns/1ps

module tb_adder_tree_49_fixed_pipelined;

    logic clk = 0;
    logic rst = 1;
    logic en  = 1;

    // 49 giá trị 32-bit Q16.16
    logic signed [49*32-1:0] in_flat;
    wire  signed [37:0] sum_out;

    // DUT
    adder_tree_49_fixed_pipelined dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .in_flat(in_flat),
        .sum_out(sum_out)
    );

    // clock 10ns
    always #5 clk = ~clk;

    // Convert Q22.16 → real
    function real q22_16_to_real(input signed [37:0] x);
        return x / 65536.0;
    endfunction

    integer i;

    initial begin
        $display("============================================");
        $display("     TESTBENCH FOR ADDER TREE 49 (Q16.16)");
        $display("============================================");

        rst = 1;
        in_flat = '0;
        #30 rst = 0;

        // ------------------------------------------------------
        // TEST 1: 49 × 1.0 = 49.0
        // Q16.16 của 1.0 = 65536 = 0x0001_0000
        // ------------------------------------------------------
        $display("\n=== TEST 1: 49 × 1.0 ===");

        for (i=0; i<49; i++)
            in_flat[i*32 +: 32] = 32'sd65536; // 1.0

        #400;

        $display("Output   = %f", q22_16_to_real(sum_out));
        $display("Expected = 49.000000");


        // ------------------------------------------------------
        // TEST 2: 49 × 0.5 = 24.5
        // Q16.16 của 0.5 = 32768 = 0x0000_8000
        // ------------------------------------------------------
        $display("\n=== TEST 2: 49 × 0.5 ===");

        for (i=0; i<49; i++)
            in_flat[i*32 +: 32] = 32'sd32768; // 0.5

        #400;

        $display("Output   = %f", q22_16_to_real(sum_out));
        $display("Expected = 24.500000");


        // ------------------------------------------------------
        // TEST 3 - Mixed (5 giá trị đầu → expected = 1.5)
        // ------------------------------------------------------
        $display("\n=== TEST 3: Mixed (expect = 1.5) ===");

        in_flat[0*32 +: 32] = 32'sd65536;   // 1.0
        in_flat[1*32 +: 32] = 32'sd32768;   // 0.5
        in_flat[2*32 +: 32] = -32'sd65536;  // -1.0
        in_flat[3*32 +: 32] = 32'sd98304;   // 1.5  (1.5 * 65536)
        in_flat[4*32 +: 32] = -32'sd32768;  // -0.5

        for (i=5; i<49; i++)
            in_flat[i*32 +: 32] = 32'sd0;

        #400;

        $display("Output   = %f", q22_16_to_real(sum_out));
        $display("Expected = 1.500000");


        $display("\n=== END TEST ===");
        #50 $finish;
    end

endmodule
