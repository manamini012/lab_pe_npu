module adder_tree_3(
    input  logic clk,
    input  logic rst,
    input  logic en,

    input  logic signed [3*32-1:0] in_flat,
    output logic signed [37:0] sum_out
);

    logic signed [31:0] level0 [0:2];
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin
            assign level0[i] = in_flat[i*32 +: 32];
        end
    endgenerate

    logic signed [37:0] sum;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            sum_out <= 38'sd0;
        else if (en)
            sum_out <= level0[0] + level0[1] + level0[2];
    end

endmodule
