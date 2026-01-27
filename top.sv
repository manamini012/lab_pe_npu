`timescale 1ns/1ps

module top #
(
    parameter N = 49
)
(
    input  clk,
    input  rst,
    input  en,

    input  signed [N*16-1:0] A_pack,   // 3 × Q8.8
    input  signed [N*16-1:0] B_pack,   // 3 × Q8.8

    output signed [37:0] Sum_Out       // Q22.16
);

    // Array signals in Verilog (use reg for sequential)
    wire signed [31:0] mac_out [0:N-1];
    wire signed [N*32-1:0] mac_flat;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : MACS

            mac_fixed_q8_8 u_mac (
                .clk(clk),
                .rst(rst),
                .A( A_pack[i*16 +: 16] ),
                .B( B_pack[i*16 +: 16] ),
                .Acc_Out( mac_out[i] )
            );

            assign mac_flat[i*32 +: 32] = mac_out[i];

        end
    endgenerate

    adder_tree_49_fixed_pipelined u_tree (
        .clk(clk),
        .rst(rst),
        .en(en),
        .in_flat(mac_flat),
        .sum_out(Sum_Out)
    );

endmodule
