`timescale 1ns/1ps

module tb_MAC_10xINT8;

// =====================================================
// Thông số
// =====================================================
parameter DATAW = 8;
parameter VECTOR_W = 10;
parameter ACCUMW = 20;
parameter PIPELINE_STAGES = 3;


// =====================================================
// Tín hiệu mô phỏng
// =====================================================
reg clk, clr, zero_en;
reg load_buf_sel;
reg load_bb_one, load_bb_two;
reg [1:0] feed_sel;
reg [DATAW*VECTOR_W-1:0] data_in;
reg [DATAW*VECTOR_W-1:0] cascade_weight_in;
reg [ACCUMW*PIPELINE_STAGES-1:0] cascade_data_in;
wire [DATAW*VECTOR_W-1:0] cascade_weight_out;
wire [ACCUMW*PIPELINE_STAGES-1:0] cascade_data_out;
wire [24:0] result_h, result_l;
reg [24:0] r_dot_out [0:3];
reg [24:0] r_acc_out [0:3];
reg signed [DATAW*2-1:0] mult_out0 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out1 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out2 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out3 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out4 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out5 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out6 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out7 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out8 [0:2]; // 16-bit [0:2]
reg signed [DATAW*2-1:0] mult_out9 [0:2]; // 16-bit [0:2]

wire [79:0] r_bb_a [0:2]; // Bộ đệm A [0:2]
wire [79:0] r_bb_b [0:2]; // Bộ đệm B [0:2]
wire [79:0] dot_in [0:2]; // Trọng số được chọn [0:2]

// Thanh ghi dữ liệu
wire [79:0] r_data_in; // Thanh ghi cho data_in (Activations)
wire [59:0] r_cascade_data_in;

// =====================================================
// Khởi tạo module DUT (Design Under Test)
// =====================================================
prime_dsp_tensor_int8 #(
    .DATAW(DATAW),
    .VECTOR_W(VECTOR_W)
) dut (
    .clk(clk),
    .clr(clr),
    .ena(ena),
    .zero_en(zero_en),
    .load_buf_sel(load_buf_sel),
    .load_bb_one(load_bb_one),
    .load_bb_two(load_bb_two),
    .feed_sel(feed_sel),
    .data_in(data_in),
    .cascade_weight_in(cascade_weight_in),
    .cascade_weight_out(cascade_weight_out),
    .cascade_data_in(cascade_data_in),
    .cascade_data_out(cascade_data_out),
    .result_h(result_h),
    .result_l(result_l)
);

// =====================================================
// Clock
// =====================================================
initial clk = 0;
always #5 clk = ~clk; // 100 MHz

// =====================================================
// Stimulus
// =====================================================
integer i;

initial begin
    $display("=== Simulation Start ===");
    clr = 1; ena = 0; zero_en = 0;
    load_bb_one = 0; load_bb_two = 0;
    load_buf_sel = 0; feed_sel = 2'b00;
    data_in = 0;
    cascade_weight_in = 0;
    cascade_data_in = 0;

    // Reset
    #20 clr = 0; ena = 1;
    
    // Gán dữ liệu input và trọng số ban đầu
    // data_in = [a0,a1,...,a9]; mỗi phần tử là 8-bit signed
    // cascade_weight_in = [w0,w1,...,w9]
    for (i = 0; i < VECTOR_W; i = i + 1) begin
        data_in[i*8 +: 8] = i + 1;         // data_in = 1..10
        cascade_weight_in[i*8 +: 8] = 10 - i; // weight_in = 10..1
    end

    // Nạp trọng số vào buffer A
    #10 load_bb_one = 1; load_buf_sel = 0; feed_sel = 2'b01;
    #10 load_bb_one = 0;

    // Giữ enable = 1, cho data_in cố định
    #10;
    $display("[TB] Start computation...");

    // Cho phép tính 10 chu kỳ clock
    repeat (10) begin
        @(posedge clk);
        $display("Time=%0t | result_l=%0d | result_h=%0d",
                 $time, result_l, result_h);
    end

    // Thay đổi buffer (nạp B)
    #10;
    for (i = 0; i < VECTOR_W; i = i + 1) begin
        data_in[i*8 +: 8] = i;        // data_in = 0..9
        cascade_weight_in[i*8 +: 8] = i + 2; // weight = 2..11
    end
    load_bb_two = 1; load_buf_sel = 1;
    #10 load_bb_two = 0;

    // Quan sát kết quả mới
    repeat (10) @(posedge clk);
    $display("[TB] End computation.");

    $finish;
end

endmodule
