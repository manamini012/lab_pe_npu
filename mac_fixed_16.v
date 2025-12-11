// ===============================================================
// Fixed-point MAC for Q8.8 format
// A,B: Q8.8
// Product: Q16.16
// Rounded + saturated output: Q8.8
// ===============================================================
module mac_fixed_q8_8 (
    input  logic clk,
    input  logic rst,
    input  logic signed [15:0] A,  // Q8.8
    input  logic signed [15:0] B,  // Q8.8
    output logic signed [15:0] Acc_Out
);

    // Multiply Q8.8 × Q8.8 → Q16.16
    logic signed [31:0] prod;
    assign prod = A * B;

    // Round Q16.16 → Q8.8 (shift right 8)
    logic signed [31:0] rounded;
    assign rounded = prod + 32'sd128; // add 2^7 for rounding

    logic signed [15:0] q8_8;
    assign q8_8 = rounded[31:8];

    // Saturate to int16
    always_comb begin
        if (q8_8 > 16'sd32767)
            Acc_Out = 16'sd32767;
        else if (q8_8 < -16'sd32768)
            Acc_Out = -16'sd32768;
        else
            Acc_Out = q8_8;
    end

endmodule
