module mac_fixed_q8_8 (
    input  clk,
    input  rst,
    input  signed [15:0] A,      // Q8.8
    input  signed [15:0] B,      // Q8.8
    output reg signed [31:0] Acc_Out  // Q16.16
);

    wire signed [31:0] prod;
    wire signed [31:0] rounded;

    // Nhân → Q16.16
    assign prod = A * B;

    // Không làm tròn
    assign rounded = prod;

    // Thanh ghi output (Verilog)
    always @(posedge clk or posedge rst) begin
        if (rst)
            Acc_Out <= 32'sd0;
        else
            Acc_Out <= rounded;
    end

endmodule
