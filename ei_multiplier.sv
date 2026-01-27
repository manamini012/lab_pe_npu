//module ei_multiplier(
//    input         clk,
//    input         rst,
//    input         en,
//    input  [7:0]  a_in,
//    input  [7:0]  b_in,
//    output reg [15:0] c_out
//);

//    wire [15:0] r0,r1,r2,r3,r4,r5,r6,r7;

//    assign r0 = b_in[0] ? {8'b0, a_in}        : 16'b0;
//    assign r1 = b_in[1] ? {7'b0, a_in,1'b0}   : 16'b0;
//    assign r2 = b_in[2] ? {6'b0, a_in,2'b0}   : 16'b0;
//    assign r3 = b_in[3] ? {5'b0, a_in,3'b0}   : 16'b0;
//    assign r4 = b_in[4] ? {4'b0, a_in,4'b0}   : 16'b0;
//    assign r5 = b_in[5] ? {3'b0, a_in,5'b0}   : 16'b0;
//    assign r6 = b_in[6] ? {2'b0, a_in,6'b0}   : 16'b0;
//    assign r7 = b_in[7] ? {1'b0, a_in,7'b0}   : 16'b0;

//    wire [15:0] r8, r9, r10, r11, r12, r13, r14;

//    adder16 add0(.a(r0), .b(r1), .sum(r8), .cout());
//    adder16 add1(.a(r2), .b(r3), .sum(r9), .cout());
//    adder16 add2(.a(r4), .b(r5), .sum(r10), .cout());
//    adder16 add3(.a(r6), .b(r7), .sum(r11), .cout());
//    adder16 add4(.a(r8), .b(r9), .sum(r12), .cout());
//    adder16 add5(.a(r10), .b(r11), .sum(r13), .cout());
//    adder16 add6(.a(r12), .b(r13), .sum(r14), .cout());

//    always @(posedge clk or posedge rst) begin
//        if (rst)
//            c_out <= 16'd0;
//        else if (en)
//            c_out <= r14;
//    end

//endmodule

`timescale 1ns / 1ps

module ei_multiplier (
    input         clk,
    input         rst,      // reset đồng bộ, active-high
    input         en,       // enable pipeline
    input  [7:0]  a_in,
    input  [7:0]  b_in,
    output [15:0] c_out
);
    //========================
    // Stage 0: latch input a,b
    //========================
    wire [7:0] a_s0, b_s0;

    regN #(.WIDTH(8)) reg_a_s0 (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .d   (a_in),
        .q   (a_s0)
    );

    regN #(.WIDTH(8)) reg_b_s0 (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .d   (b_in),
        .q   (b_s0)
    );

    //========================
    // Stage 1: partial products + cộng tầng 1
    //========================
    wire [15:0] r0,r1,r2,r3,r4,r5,r6,r7;
    wire [15:0] r8_s1, r9_s1, r10_s1, r11_s1;

    assign r0 = b_s0[0] ? {8'b0, a_s0}        : 16'b0;
    assign r1 = b_s0[1] ? {7'b0, a_s0,1'b0}   : 16'b0;
    assign r2 = b_s0[2] ? {6'b0, a_s0,2'b0}   : 16'b0;
    assign r3 = b_s0[3] ? {5'b0, a_s0,3'b0}   : 16'b0;
    assign r4 = b_s0[4] ? {4'b0, a_s0,4'b0}   : 16'b0;
    assign r5 = b_s0[5] ? {3'b0, a_s0,5'b0}   : 16'b0;
    assign r6 = b_s0[6] ? {2'b0, a_s0,6'b0}   : 16'b0;
    assign r7 = b_s0[7] ? {1'b0, a_s0,7'b0}   : 16'b0;

    adder16 add0 (.a(r0), .b(r1), .sum(r8_s1),  .cout());
    adder16 add1 (.a(r2), .b(r3), .sum(r9_s1),  .cout());
    adder16 add2 (.a(r4), .b(r5), .sum(r10_s1), .cout());
    adder16 add3 (.a(r6), .b(r7), .sum(r11_s1), .cout());

    // Pipeline giữa tầng 1 và 2
    wire [15:0] r8_s2, r9_s2, r10_s2, r11_s2;
    regN #(.WIDTH(16)) reg_r8_s2  (.clk(clk), .rst(rst), .en(en), .d(r8_s1),  .q(r8_s2));
    regN #(.WIDTH(16)) reg_r9_s2  (.clk(clk), .rst(rst), .en(en), .d(r9_s1),  .q(r9_s2));
    regN #(.WIDTH(16)) reg_r10_s2 (.clk(clk), .rst(rst), .en(en), .d(r10_s1), .q(r10_s2));
    regN #(.WIDTH(16)) reg_r11_s2 (.clk(clk), .rst(rst), .en(en), .d(r11_s1), .q(r11_s2));

    //========================
    // Stage 2: cộng tầng 2
    //========================
    wire [15:0] r12_s2, r13_s2;
    adder16 add4 (.a(r8_s2),  .b(r9_s2),  .sum(r12_s2), .cout());
    adder16 add5 (.a(r10_s2), .b(r11_s2), .sum(r13_s2), .cout());

    // Pipeline giữa tầng 2 và 3
    wire [15:0] r12_s3, r13_s3;
    regN #(.WIDTH(16)) reg_r12_s3 (.clk(clk), .rst(rst), .en(en), .d(r12_s2), .q(r12_s3));
    regN #(.WIDTH(16)) reg_r13_s3 (.clk(clk), .rst(rst), .en(en), .d(r13_s2), .q(r13_s3));

    //========================
    // Stage 3: cộng tầng 3 + latch output
    //========================
    wire [15:0] c_comb;
    adder16 add6 (.a(r12_s3), .b(r13_s3), .sum(c_comb), .cout());
    regN  #(.WIDTH(16)) reg_c_out (.clk(clk), .rst(rst), .en(en), .d(c_comb), .q(c_out));

endmodule
