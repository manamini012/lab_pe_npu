`timescale 1ns / 1ps

module Systolic_Array_4x6 (
    input wire clk,
    input wire rst,
    input wire load_en,
    
    // --- INPUT PORTS ---
    // 1. IFMAP: 4 dòng đi vào từ bên trái (mỗi dòng 16 bit)
    // Để đơn giản, ta gộp thành 1 bus lớn: 4 * 16 = 64 bit
    input wire [63:0] ifmap_west_in, 
    
    // 2. WEIGHT: 24 PE cần nạp weight. 
    // Trong thực tế sẽ dùng Shift Register, nhưng ở đây ta dùng Parallel Load 
    // để dễ hiểu. Input là mảng lớn chứa weight cho toàn bộ 24 PE.
    // 4 hàng x 6 cột x 16 bit = 384 bit
    input wire [383:0] weights_in,

    // --- OUTPUT PORTS ---
    // 3. PSUM: 6 cột đi ra ở bên dưới
    // 6 * 16 = 96 bit
    output wire [95:0] psum_south_out
);

    // Tham số kích thước
    parameter ROWS = 4;
    parameter COLS = 6;

    // Mảng dây nối nội bộ (Internal Wires)
    // Wire nối ngang (Ifmap): [ROWS][COLS+1] (+1 để có chỗ cho dây output cuối cùng)
    wire [15:0] ifmap_wires [0:ROWS-1][0:COLS];
    
    // Wire nối dọc (Psum): [ROWS+1][COLS] (+1 để có chỗ cho dây input đầu tiên và output cuối cùng)
    wire [15:0] psum_wires  [0:ROWS][0:COLS-1];

    // Biến sinh code
    genvar i, j;

    // =================================================================
    // 1. GÁN INPUT BAN ĐẦU (BOUNDARY CONDITIONS)
    // =================================================================
    generate
        // a. Gán Ifmap Input vào cột đầu tiên (Cột 0) của các dây ngang
        for (i = 0; i < ROWS; i = i + 1) begin : LEFT_INPUTS
            assign ifmap_wires[i][0] = ifmap_west_in[(i*16) +: 16];
        end

        // b. Gán Psum Input = 0 vào hàng đầu tiên (Hàng 0) của các dây dọc
        for (j = 0; j < COLS; j = j + 1) begin : TOP_INPUTS
            assign psum_wires[0][j] = 16'h0000; // Giá trị khởi tạo là 0
        end
    endgenerate

    // =================================================================
    // 2. KHỞI TẠO MA TRẬN 24 PE (PE INSTANTIATION)
    // =================================================================
    generate
        for (i = 0; i < ROWS; i = i + 1) begin : ROW_LOOP
            for (j = 0; j < COLS; j = j + 1) begin : COL_LOOP
                
                // Tính index phẳng để lấy weight từ input bus lớn
                // Ví dụ: PE tại hàng 0, cột 1 là vị trí số 1
                localparam integer w_idx = (i * COLS) + j;

                pe_fp16 u_pe (
                    .clk(clk),
                    .rst(rst),
                    .load_en(load_en),
                    
                    // Input ngang: Lấy từ dây bên trái (j)
                    .ifmap_in(ifmap_wires[i][j]),
                    
                    // Input dọc: Lấy từ dây bên trên (i)
                    .psum_in(psum_wires[i][j]),
                    
                    // Weight: Lấy cắt từ bus lớn
                    .weight_in(weights_in[(w_idx*16) +: 16]),
                    
                    // Output ngang: Nối sang dây bên phải (j+1)
                    .ifmap_out(ifmap_wires[i][j+1]),
                    
                    // Output dọc: Nối xuống dây bên dưới (i+1)
                    .psum_out(psum_wires[i+1][j])
                );
            end
        end
    endgenerate

    // =================================================================
    // 3. GÁN OUTPUT CUỐI CÙNG
    // =================================================================
    generate
        // Lấy Psum ra từ hàng cuối cùng (ROWS)
        for (j = 0; j < COLS; j = j + 1) begin : SOUTH_OUTPUTS
            assign psum_south_out[(j*16) +: 16] = psum_wires[ROWS][j];
        end
    endgenerate

endmodule