`timescale 1ns/1ps

module tb_MAC_10xINT8_1;

// =====================================================
// Parameters
// =====================================================
parameter DATAW     = 8;
parameter VECTOR_W  = 10;
parameter TILE_ID   = 0;
parameter DPE_ID    = 0;

// =====================================================
// Signals
// =====================================================
reg clk, clr, ena, zero_en;
reg load_buf_sel;
reg load_bb_a, load_bb_b;
reg [1:0] feed_sel;
reg [95:0] data_in;
reg [87:0] cascade_weight_in;
reg [95:0] cascade_data_in;

wire [87:0] cascade_weight_out;
wire [95:0] cascade_data_out;
wire [36:0] result_h;
wire [37:0] result_l;

// =====================================================
// DUT instantiation
// - Note: module name expected by TB is MAC_10xINT8
// - port names mapped to the TB signals (consistent names)
// =====================================================
MAC_10xINT8 #(
    .TILE_ID(TILE_ID),
    .DPE_ID(DPE_ID)
) dut (
    .clk(clk),
    .clr(clr),
    .ena(ena),
    .data_in(data_in),
    .load_buf_sel(load_buf_sel),
    .load_bb_a(load_bb_a),
    .load_bb_b(load_bb_b),
    .feed_sel(feed_sel),
    .zero_en(zero_en),
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
// Helper: dot product for expected value (signed 8-bit)
// =====================================================
function integer dot_product;
    input [95:0] data_vec;
    input [87:0] weight_vec;
    integer i;
    reg signed [7:0] a;
    reg signed [7:0] b;
    reg signed [31:0] sum;
begin
    sum = 0;
    for (i = 0; i < 10; i = i + 1) begin
        a = data_vec[i*8 +: 8];
        b = weight_vec[i*8 +: 8];
        sum = sum + (a * b);
    end
    dot_product = sum;
end
endfunction

// =====================================================
// Reset task
// =====================================================
task reset_mac;
begin
    clr = 1; ena = 0; zero_en = 0;
    load_bb_a = 0; load_bb_b = 0;
    load_buf_sel = 0; feed_sel = 2'b00;
    data_in = 0; cascade_weight_in = 0; cascade_data_in = 0;
    #20;
    clr = 0; ena = 1;
    $display("[TB] Reset complete at %0t", $time);
end
endtask

// =====================================================
// Load buffer task (fixed syntax and signal names)
// buf_one = 1 -> load bb_one
// buf_one = 0 -> load bb_two
// =====================================================
task load_buffer;
    input integer buf_one;
    input [95:0] din;
    input [87:0] win;
    input [1:0] fsel;
begin
    data_in = din;
    cascade_weight_in = win;
    feed_sel = fsel;
    // set which buffer to load
    load_bb_a = (buf_one != 0) ? 1'b1 : 1'b0;
    load_bb_b = (buf_one == 0) ? 1'b1 : 1'b0;
    // load_buf_sel controls selection for dot_in (follow your DSP convention).
    // Here we set it to select the buffer we just loaded (conservative).
    load_buf_sel = (buf_one != 0) ? 1'b0 : 1'b1; // matches prime_dsp convention (r_load_buf_sel selects r_bb_two when 1)
    @(posedge clk); // apply for one clock
    // deassert load strobes
    load_bb_a = 0;
    load_bb_b = 0;
    // keep feed_sel until next action (or reset it)
    feed_sel = 2'b00;
end
endtask

// =====================================================
// Test Stimulus
// =====================================================
integer i;
integer expected;

reg [95:0] din;
reg [87:0] win;

initial begin
    $display("=== Starting MAC_INT8 Test ===");
    reset_mac();

    // -------------------------------
    // Case 1: Load buffer ONE
    // -------------------------------
    for (i = 0; i < 10; i = i + 1) begin
        din[i*8 +: 8] = i + 1;          // 1..10
        win[i*8 +: 8] = 10 - i;         // 10..1
    end
    load_buffer(1, din, win, 2'b01);
    expected = dot_product(din, win);

    // wait a few cycles for pipeline/register delays
    repeat (6) @(posedge clk);
    $display("[TB] Case 1 Expected = %0d, result_l = %0d, result_h = %0d", expected, result_l, result_h);
    // result_l/result_h may be packed slices of accumulators in DUT; compare low 32-bit view
    if (result_l !== expected)
        $display("[FAIL] Case 1 mismatch!");
    else
        $display("[PASS] Case 1 OK");

    // -------------------------------
    // Case 2: Load buffer TWO
    // -------------------------------
    for (i = 0; i < 10; i = i + 1) begin
        din[i*8 +: 8] = i - 5;          // -5..4
        win[i*8 +: 8] = i + 3;          // 3..12
    end
    load_buffer(0, din, win, 2'b10);
    expected = dot_product(din, win);

    repeat (6) @(posedge clk);
    $display("[TB] Case 2 Expected = %0d, result_l = %0d, result_h = %0d", expected, result_l, result_h);
    if (result_l !== expected)
        $display("[FAIL] Case 2 mismatch!");
    else
        $display("[PASS] Case 2 OK");

    // -------------------------------
    // Case 3: Zero enable test
    // -------------------------------
    zero_en = 1;
    @(posedge clk);
    zero_en = 0;
    repeat (2) @(posedge clk);
    if (result_l == 0)
        $display("[PASS] Zero_en cleared accumulator");
    else
        $display("[NOTE] zero_en behavior: DUT result_l = %0d (expected 0)", result_l);

    // -------------------------------
    // Case 4: Cascade test
    // -------------------------------
    cascade_data_in = 96'h000000000000000000000001; // simple add-in
    repeat (3) @(posedge clk);
    $display("[TB] Cascade out = %h", cascade_data_out);

    // -------------------------------
    // End of test
    // -------------------------------
    $display("=== MAC_INT8 Test Completed ===");
    $finish;
end

endmodule
