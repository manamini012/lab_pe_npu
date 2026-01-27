module mac_fixed_q8_8 (
    input  logic clk,
    input  logic rst,
    input  logic signed [15:0] A,  // Q8.8
    input  logic signed [15:0] B,  // Q8.8
    output logic signed [31:0] Acc_Out   // Q16.16
);

    // Multiply → Q16.16
    logic signed [31:0] prod;
    assign prod = A * B;

    // Optional rounding (not required)
    logic signed [31:0] rounded;
    assign rounded = prod;  // no rounding needed for full precision

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            Acc_Out <= 32'sd0;
        else
            Acc_Out <= rounded;
    end

endmodule
