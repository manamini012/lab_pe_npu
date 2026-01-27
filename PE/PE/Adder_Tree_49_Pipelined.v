`timescale 1ns / 1ps

module Adder_Tree_49_Pipelined(
    input wire clk,
    input wire rst,
    input wire [16*49-1:0] in_flat_data, 
    output reg [15:0] final_sum
);

    // --- UNPACK INPUT DATA ---
    wire [15:0] level0 [0:48];
    genvar i;
    generate
        for (i = 0; i < 49; i = i + 1) begin : unpack
            assign level0[i] = in_flat_data[(i*16)+15 : (i*16)];
        end
    endgenerate

    integer k;

    // --- STAGE 1 ---
    wire [15:0] s1_sum [0:23];
    reg  [15:0] s1_reg [0:24];
    generate
        for (i = 0; i < 24; i = i + 1) begin : st1_adders
            FP_Add_16 u_add1 (.A(level0[2*i]), .B(level0[2*i+1]), .Sum_Out(s1_sum[i]));
        end
    endgenerate
    always @(posedge clk or posedge rst) begin
        if (rst) for (k=0; k<25; k=k+1) s1_reg[k] <= 16'd0;
        else begin
            for (k=0; k<24; k=k+1) s1_reg[k] <= s1_sum[k];
            s1_reg[24] <= level0[48]; 
        end
    end

    // --- STAGE 2 ---
    wire [15:0] s2_sum [0:11];
    reg  [15:0] s2_reg [0:12];
    generate
        for (i = 0; i < 12; i = i + 1) begin : st2_adders
            FP_Add_16 u_add2 (.A(s1_reg[2*i]), .B(s1_reg[2*i+1]), .Sum_Out(s2_sum[i]));
        end
    endgenerate
    always @(posedge clk or posedge rst) begin
        if (rst) for (k=0; k<13; k=k+1) s2_reg[k] <= 16'd0;
        else begin
            for (k=0; k<12; k=k+1) s2_reg[k] <= s2_sum[k];
            s2_reg[12] <= s1_reg[24]; 
        end
    end

    // --- STAGE 3 ---
    wire [15:0] s3_sum [0:5];
    reg  [15:0] s3_reg [0:6];
    generate
        for (i = 0; i < 6; i = i + 1) begin : st3_adders
            FP_Add_16 u_add3 (.A(s2_reg[2*i]), .B(s2_reg[2*i+1]), .Sum_Out(s3_sum[i]));
        end
    endgenerate
    always @(posedge clk or posedge rst) begin
        if (rst) for (k=0; k<7; k=k+1) s3_reg[k] <= 16'd0;
        else begin
            for (k=0; k<6; k=k+1) s3_reg[k] <= s3_sum[k];
            s3_reg[6] <= s2_reg[12]; 
        end
    end

    // --- STAGE 4 ---
    wire [15:0] s4_sum [0:2];
    reg  [15:0] s4_reg [0:3];
    generate
        for (i = 0; i < 3; i = i + 1) begin : st4_adders
            FP_Add_16 u_add4 (.A(s3_reg[2*i]), .B(s3_reg[2*i+1]), .Sum_Out(s4_sum[i]));
        end
    endgenerate
    always @(posedge clk or posedge rst) begin
        if (rst) for (k=0; k<4; k=k+1) s4_reg[k] <= 16'd0;
        else begin
            for (k=0; k<3; k=k+1) s4_reg[k] <= s4_sum[k];
            s4_reg[3] <= s3_reg[6]; 
        end
    end

    // --- STAGE 5 ---
    wire [15:0] s5_sum [0:1];
    reg  [15:0] s5_reg [0:1];
    generate
        for (i = 0; i < 2; i = i + 1) begin : st5_adders
            FP_Add_16 u_add5 (.A(s4_reg[2*i]), .B(s4_reg[2*i+1]), .Sum_Out(s5_sum[i]));
        end
    endgenerate
    always @(posedge clk or posedge rst) begin
        if (rst) begin s5_reg[0] <= 16'd0; s5_reg[1] <= 16'd0; end
        else begin s5_reg[0] <= s5_sum[0]; s5_reg[1] <= s5_sum[1]; end
    end

    // --- STAGE 6 ---
    wire [15:0] final_comb_sum;
    FP_Add_16 u_final_add (.A(s5_reg[0]), .B(s5_reg[1]), .Sum_Out(final_comb_sum));
    
    always @(posedge clk or posedge rst) begin
        if (rst) final_sum <= 16'd0;
        else final_sum <= final_comb_sum;
    end

endmodule