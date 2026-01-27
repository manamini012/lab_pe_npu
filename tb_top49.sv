`timescale 1ns/1ps

module tb_top49;

    logic clk = 0;
    logic rst = 1;
    logic en  = 1;

    logic signed [49*16-1:0] A_pack, B_pack;
    logic signed [37:0] Sum_Out;

    top #(49) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .A_pack(A_pack),
        .B_pack(B_pack),
        .Sum_Out(Sum_Out)
    );

    always #5 clk = ~clk;

    function int q8_8(input real x);
        return $rtoi(x * 256.0);
    endfunction

    function real q22_16_to_real(input signed [37:0] x);
        return x / 65536.0;
    endfunction

    real A_real[0:48];
    real B_real[0:48];
    real expected_sum;
    real out_real;

    integer i;

    initial begin
        rst = 1; #20; rst = 0;

        expected_sum = 0.0;

        for (i=0; i<49; i++) begin
            A_real[i] = i*2.37 - 11.125;
            B_real[i] = 6.832 - i*0.173;

            A_pack[i*16 +: 16] = q8_8(A_real[i]);
            B_pack[i*16 +: 16] = q8_8(B_real[i]);

            expected_sum += A_real[i] * B_real[i];
        end

        #350;

        out_real = q22_16_to_real(Sum_Out);

        $display("=========================================");
        $display("     TOP 49 MAC - FINAL TEST");
        $display("=========================================");
        $display("Expected Sum (real) = %f", expected_sum);
        $display("DUT Output   (real) = %f", out_real);
        $display("=========================================");

        #50 $finish;
    end

endmodule