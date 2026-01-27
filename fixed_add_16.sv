// ===============================================================
// 16-bit Q8.8 adder with saturation (Verilog-2001 version)
// ===============================================================
module fixed_add_16 (
    input  signed [15:0] A,     // Q8.8
    input  signed [15:0] B,     // Q8.8
    output reg signed [15:0] Sum_Out
);

    wire signed [16:0] sum_ext;

    assign sum_ext = A + B; // 17-bit extended addition

    always @(*) begin
        if (sum_ext > 17'sd32767)
            Sum_Out = 16'sd32767;
        else if (sum_ext < -17'sd32768)
            Sum_Out = -17'sd32768;
        else
            Sum_Out = sum_ext[15:0];
    end

endmodule
