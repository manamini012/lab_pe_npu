module top #(
    parameter N = 49
)(
    input  logic clk,
    input  logic rst,
    input  logic en,

    input  logic signed [N*16-1:0] A_pack,  // Q8.8
    input  logic signed [N*16-1:0] B_pack,  // Q8.8

    output logic signed [37:0] Sum_Out      // Q22.16
);

    logic signed [31:0] mac_out [0:N-1];
    logic signed [N*32-1:0] tree_in;

    genvar i;
    generate
        for (i=0; i<N; i++) begin
            mac_fixed_q8_8 mac_i (
                .clk(clk),
                .rst(rst),
                .A(A_pack[i*16 +: 16]),
                .B(B_pack[i*16 +: 16]),
                .Acc_Out(mac_out[i])
            );
            assign tree_in[i*32 +: 32] = mac_out[i];
        end
    endgenerate

    adder_tree_49_fixed_pipelined tree (
        .clk(clk),
        .rst(rst),
        .en(en),
        .in_flat(tree_in),
        .sum_out(Sum_Out)
    );

endmodule
