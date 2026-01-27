module csa #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] op1, // Số hạng 1
    input  [WIDTH-1:0] op2, // Số hạng 2
    input  [WIDTH-1:0] op3, // Số hạng 3
    output [WIDTH-1:0] sum,   // Vector Tổng (S)
    output [WIDTH-1:0] carry  // Vector Nhớ (C)
);
    // 1. Tính Sum: Là phép cộng không nhớ (XOR)
    assign sum   = op1 ^ op2 ^ op3;

    // 2. Tính Carry: Là khi có ít nhất 2 bit đầu vào là 1
    assign carry = (op1 & op2) | (op1 & op3) | (op2 & op3);
endmodule