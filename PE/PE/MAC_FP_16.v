`timescale 1ns / 1ps

module MAC_FP_16 (
    input wire clk,
    input wire rst,
    input wire [15:0] A,    // Ifmap
    input wire [15:0] B,    // Weight
    input wire [15:0] C,    // Psum_in
    output wire [15:0] Acc_Out // Psum_out
);

    // --- 1. Bộ Nhân (Latency thực tế = 6 chu kỳ) ---
    wire [15:0] product_res;
    FP_Mul_16 u_multiplier (
        .clk(clk), 
        .rst(rst), 
        .A(A), 
        .B(B), 
        .Mul_Out(product_res)
    );

    // --- 2. Shift Register cho C (SỬA LẠI: TĂNG LÊN 6) ---
    // Vì Mul mất 6 nhịp, C cũng phải chờ 6 nhịp mới được cộng
    reg [15:0] r1, r2, r3, r4, r5, r6; // Thêm r5, r6
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r1 <= 0; r2 <= 0; r3 <= 0; r4 <= 0; r5 <= 0; r6 <= 0;
        end else begin
            r1 <= C;      // T+1
            r2 <= r1;     // T+2
            r3 <= r2;     // T+3
            r4 <= r3;     // T+4
            r5 <= r4;     // T+5
            r6 <= r5;     // T+6 (Khớp với product_res)
        end
    end

    wire [15:0] C_sync = r6; // Lấy đầu ra ở nhịp thứ 6

    // --- 3. Bộ Cộng ---
    wire [15:0] sum_res;
    FP_Add_16 u_adder (
        .clk(clk),          
        .rst(rst),          
        .A(product_res), 
        .B(C_sync),      // Đã đồng bộ ở nhịp thứ 6
        .Sum_Out(sum_res)
    );

    // --- 4. Output Register (+1 chu kỳ) ---
    reg [15:0] acc_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) acc_reg <= 0;
        else     acc_reg <= sum_res;
    end

    assign Acc_Out = acc_reg;

endmodule