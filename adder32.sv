module adder32 (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] sum,
    output        cout
);
    wire [32:0] c;  // carry chain: c[0] = cin, c[32] = final carry

    assign c[0] = 1'b0;  // không có carry-in ban đầu

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : ADD32_CHAIN
            full_adder fa_inst (
                .a   (a[i]),
                .b   (b[i]),
                .cin (c[i]),
                .sum (sum[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

    assign cout = c[32];  // carry-out cuối cùng
endmodule
