`timescale 1ns / 1ps

module TPU_Top (
    input wire clk,
    input wire rst,
    input wire load_en,                 // Tín hiệu nạp trọng số
    input wire [63:0] ifmap_in,         // Input thô (chưa skew)
    input wire [383:0] weights_in,      // Input trọng số
    output wire [95:0] psum_out         // Kết quả tính toán
);

    // --- Dây nối nội bộ (Internal Wire) ---
    // Dây này nối output của Buffer vào input của Array
    wire [63:0] ifmap_skewed_internal;

    // --- 1. Nhúng module Data Skew Buffer ---
    Data_Skew_Buffer u_buffer (
        .clk(clk),
        .rst(rst),
        .ifmap_in(ifmap_in),
        .ifmap_skewed(ifmap_skewed_internal) // Nối vào dây nội bộ
    );

    // --- 2. Nhúng module Systolic Array ---
    Systolic_Array_4x6 u_array (
        .clk(clk),
        .rst(rst),
        .load_en(load_en),
        .ifmap_west_in(ifmap_skewed_internal), // Lấy từ dây nội bộ
        .weights_in(weights_in),
        .psum_south_out(psum_out)
    );

endmodule