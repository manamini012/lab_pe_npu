//`timescale 1ns/1ps

//module tb_top49;

//    logic clk = 0;
//    logic rst = 1;
//    logic en  = 1;

//    logic signed [3*16-1:0] A_pack, B_pack;
//    logic signed [37:0] Sum_Out;

//    top #(3) dut (
//        .clk(clk),
//        .rst(rst),
//        .en(en),
//        .A_pack(A_pack),
//        .B_pack(B_pack),
//        .Sum_Out(Sum_Out)
//    );

//    always #5 clk = ~clk;

//    // Convert real → Q8.8 (không làm tròn, giữ nguyên độ chính xác)
//    function int q8_8(input real x);
//        return $rtoi(x * 256.0);
//    endfunction

//    // Convert Q22.16 → real (giữ nguyên độ chính xác)
//    function real q22_16_to_real(input signed [37:0] x);
//        return x / 65536.0;
//    endfunction

//    real A_real[0:2];
//    real B_real[0:2];
//    real expected_sum;
//    real out_real;

//    integer i;

//    initial begin
//        // In ra giá trị ban đầu của A_pack và B_pack
//        $display("Initial A_pack: %h", A_pack);
//        $display("Initial B_pack: %h", B_pack);

//        rst = 1; #20; rst = 0;

//        expected_sum = 0.0;

//        // Assign new values to A and B
//        A_real[0] = 4.2;
//        B_real[0] = -1.3;

//        A_real[1] = -3.1;
//        B_real[1] = 2.5;

//        A_real[2] = 1.75;
//        B_real[2] = -0.8;

//        // Convert to Q8.8 and assign to A_pack and B_pack
//        A_pack[0*16 +: 16] = q8_8(A_real[0]);
//        B_pack[0*16 +: 16] = q8_8(B_real[0]);

//        A_pack[1*16 +: 16] = q8_8(A_real[1]);
//        B_pack[1*16 +: 16] = q8_8(B_real[1]);

//        A_pack[2*16 +: 16] = q8_8(A_real[2]);
//        B_pack[2*16 +: 16] = q8_8(B_real[2]);

//        // In ra giá trị sau khi gán
//        $display("Updated A_pack: %h", A_pack);
//        $display("Updated B_pack: %h", B_pack);

//        // Calculate expected sum with high precision
//        expected_sum = (A_real[0] * B_real[0]) + (A_real[1] * B_real[1]) + (A_real[2] * B_real[2]);

//        // Wait for pipeline latency to settle
//        #350;

//        // Convert DUT output back to real for comparison
//        out_real = q22_16_to_real(Sum_Out);

//        // Display results
//        $display("\n=========================================");
//        $display("       TOP 3 MAC - FINAL TEST (New Values)");
//        $display("=========================================");
//        $display("Expected Sum (real) = %f", expected_sum);
//        $display("DUT Output   (real) = %f", out_real);
//        $display("=========================================\n");

//        #50 $finish;
//    end

//endmodule


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

