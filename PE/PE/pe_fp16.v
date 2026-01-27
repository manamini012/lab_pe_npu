`timescale 1ns / 1ps

module pe_fp16 (
    input wire clk,
    input wire rst,        
    input wire load_en,
    input wire [15:0] ifmap_in,
    input wire [15:0] weight_in,
    input wire [15:0] psum_in,
    
    output reg [15:0] ifmap_out, // Dùng reg trực tiếp cho logic 1 cycle
    output wire [15:0] psum_out
);

    // ==========================================
    // 1. Lưu trọng số (Weight Stationary)
    // ==========================================
    reg [15:0] stored_weight;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stored_weight <= 16'd0;
        end else if (load_en) begin
            stored_weight <= weight_in;
        end
    end

    // ==========================================
    // 2. Gọi khối MAC (Latency = 9 Cycles)
    // ==========================================
    // MAC nhận input mới mỗi chu kỳ, và đẩy psum ra sau 9 chu kỳ
    MAC_FP_16 u_mac (
        .clk(clk),
        .rst(rst),
        .A(ifmap_in),
        .B(stored_weight),
        .C(psum_in),        
        .Acc_Out(psum_out) 
    );

    // ==========================================
    // 3. Xử lý trễ cho ifmap (Forwarding)
    // ==========================================
    // SỬA LẠI: Chỉ cần delay 1 chu kỳ để truyền sang PE bên phải.
    // Vì MAC là Pipelined, PE bên phải sẽ xử lý phần tử tiếp theo 
    // ngay ở chu kỳ sau, không cần chờ PE này tính xong.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ifmap_out <= 16'd0;
        end else begin
            ifmap_out <= ifmap_in; // Register Slice (1 Cycle Delay)
        end
    end

endmodule