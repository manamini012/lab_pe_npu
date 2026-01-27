`timescale 1ns / 1ps

module Data_Skew_Buffer (
    input wire clk,
    input wire rst,
    input wire [63:0] ifmap_in, 
    output wire [63:0] ifmap_skewed
);

    // QUAN TRỌNG: Cấu hình độ trễ bằng đúng latency của MAC (9 cycles)
    parameter LATENCY = 9; 

    wire [15:0] row0 = ifmap_in[15:0];
    wire [15:0] row1 = ifmap_in[31:16];
    wire [15:0] row2 = ifmap_in[47:32];
    wire [15:0] row3 = ifmap_in[63:48];

    // Tạo các hàng đợi (Shift Register)
    // Hàng 1 trễ 9 nhịp, Hàng 2 trễ 18 nhịp, Hàng 3 trễ 27 nhịp
    reg [15:0] d1 [0:LATENCY-1];        // Mảng lưu 9 giá trị
    reg [15:0] d2 [0:(LATENCY*2)-1];    // Mảng lưu 18 giá trị
    reg [15:0] d3 [0:(LATENCY*3)-1];    // Mảng lưu 27 giá trị
    
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset tất cả về 0
            for(i=0; i<LATENCY; i=i+1) d1[i] <= 0;
            for(i=0; i<LATENCY*2; i=i+1) d2[i] <= 0;
            for(i=0; i<LATENCY*3; i=i+1) d3[i] <= 0;
        end else begin
            // Shift data cho Hàng 1
            d1[0] <= row1;
            for(i=1; i<LATENCY; i=i+1) d1[i] <= d1[i-1];

            // Shift data cho Hàng 2
            d2[0] <= row2;
            for(i=1; i<LATENCY*2; i=i+1) d2[i] <= d2[i-1];

            // Shift data cho Hàng 3
            d3[0] <= row3;
            for(i=1; i<LATENCY*3; i=i+1) d3[i] <= d3[i-1];
        end
    end

    // Output lấy từ phần tử cuối cùng của hàng đợi
    assign ifmap_skewed[15:0]  = row0; // Không delay
    assign ifmap_skewed[31:16] = d1[LATENCY-1];
    assign ifmap_skewed[47:32] = d2[(LATENCY*2)-1];
    assign ifmap_skewed[63:48] = d3[(LATENCY*3)-1];

endmodule