////////`timescale 1ns/1ps

////////module tb_ei_mac10_8x8_pipe;

////////    reg clk = 0;
////////    always #5 clk = ~clk;   // 100 MHz

////////    reg rst, en, valid_in, clr_acc;

////////    reg [79:0] a_vec;
////////    reg [79:0] b_vec;
////////    wire [31:0] acc_out;
////////    wire        valid_out;

////////    ei_mac10_8x8_pipe dut (
////////        .clk       (clk),
////////        .rst       (rst),
////////        .en        (en),
////////        .valid_in  (valid_in),
////////        .clr_acc   (clr_acc),
////////        .a_vec     (a_vec),
////////        .b_vec     (b_vec),
////////        .acc_out   (acc_out),
////////        .valid_out (valid_out)
////////    );

////////    integer i;

////////    initial begin
////////        rst = 1; en = 1; valid_in = 0; clr_acc = 0;
////////        a_vec = 0; b_vec = 0;
////////        #20 rst = 0;

////////        //============= Test 1: clear accumulator =============
////////        clr_acc = 1;
////////        #10 clr_acc = 0;

////////        //============= Test 2: gửi 10 cặp số =============
////////        valid_in = 1;

////////        // a[i] = i, b[i] = 2*i
////////        for (i=0; i<10; i=i+1) begin
////////            a_vec[8*i +: 8] = i;
////////            b_vec[8*i +: 8] = 2*i;
////////        end

////////        #10 valid_in = 0;

////////        // chờ latency cho output
////////        repeat(10) @(posedge clk);

////////        if (valid_out)
////////            $display("MAC10 OUTPUT = %0d", acc_out);
////////        else
////////            $display("ERROR: no valid output");

////////        #50 $finish;
////////    end

////////endmodule


//`timescale 1ns/1ps

//module tb_ei_mac10_8x8_pipe;

//localparam LAT = 3;

//reg clk;
//reg rst;
//reg en;
//reg valid_in;
//reg clr_acc;

//reg  [79:0] a_vec;
//reg  [79:0] b_vec;

//wire [31:0] acc_out;
//wire        valid_out;

//// DECLARE integer AT MODULE SCOPE to avoid syntax error
//integer i;

////====================================
//// DUT
////====================================
//ei_mac10_8x8_pipe #(.LAT(LAT)) dut (
//    .clk(clk),
//    .rst(rst),
//    .en(en),
//    .valid_in(valid_in),
//    .clr_acc(clr_acc),
//    .a_vec(a_vec),
//    .b_vec(b_vec),
//    .acc_out(acc_out),
//    .valid_out(valid_out)
//);

////====================================
//// Clock 100 MHz
////====================================
//initial begin
//    clk = 0;
//    forever #5 clk = ~clk;
//end

////====================================
//// Task: gửi 10 cặp số
////====================================
//task send_10_pairs(
//    input [7:0] a0, input [7:0] b0,
//    input [7:0] a1, input [7:0] b1,
//    input [7:0] a2, input [7:0] b2,
//    input [7:0] a3, input [7:0] b3,
//    input [7:0] a4, input [7:0] b4,
//    input [7:0] a5, input [7:0] b5,
//    input [7:0] a6, input [7:0] b6,
//    input [7:0] a7, input [7:0] b7,
//    input [7:0] a8, input [7:0] b8,
//    input [7:0] a9, input [7:0] b9
//);
//begin
//    // Ghép thành vector 80 bit (LSB = a0)
//    a_vec = {a9,a8,a7,a6,a5,a4,a3,a2,a1,a0};
//    b_vec = {b9,b8,b7,b6,b5,b4,b3,b2,b1,b0};

//    @(negedge clk);
//    valid_in = 1;

//    @(posedge clk);

//    @(negedge clk);
//    valid_in = 0;
//end
//endtask

////====================================
//// MAIN TEST
////====================================
//initial begin
//    rst = 1;
//    en = 1;
//    valid_in = 0;
//    clr_acc  = 0;
//    a_vec    = 0;
//    b_vec    = 0;

//    #20 rst = 0;

//    //=======================
//    // Test 1: clear acc
//    //=======================
//    @(negedge clk) clr_acc = 1;
//    @(negedge clk) clr_acc = 0;

//    //=======================
//    // Test 2: Test vector cố định
//    //=======================
//    send_10_pairs(
//        3,4,   10,2,   5,5,   1,7,   2,9,
//        4,6,   8,1,    3,3,   9,0,   2,2
//    );

//    // chờ kết quả (LAT chu kỳ + 2 safety)
//    repeat (LAT+3) @(posedge clk);

//    $display("Expected = 127, Output = %0d, valid_out=%0b", acc_out, valid_out);

////=======================
//////     Test 3: Random (mask $random to 8 bits)
////=======================
//    for (i = 0; i < 5; i = i + 1) begin
//        send_10_pairs(
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF),
//            ($random & 8'hFF), ($random & 8'hFF)
//        );

//        repeat (LAT+3) @(posedge clk);
//        $display("Random test %0d: acc_out=%0d valid=%0b", i, acc_out, valid_out);
//    end

//    $finish;
//end

//endmodule


`timescale 1ns/1ps

module tb_ei_mac10_8x8_pipe;

localparam LAT = 3;

reg clk;
reg rst;
reg en;
reg valid_in;
reg clr_acc;

reg  [79:0] a_vec;
reg  [79:0] b_vec;

wire [31:0] acc_out;
wire        valid_out;

integer i;

//====================================
// DUT
//====================================
ei_mac10_8x8_pipe #(.LAT(LAT)) dut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .valid_in(valid_in),
    .clr_acc(clr_acc),
    .a_vec(a_vec),
    .b_vec(b_vec),
    .acc_out(acc_out),
    .valid_out(valid_out)
);

//====================================
// Clock 100 MHz
//====================================
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//====================================
// Task: gửi 10 cặp số
//====================================
task send_10_pairs(
    input [7:0] a0, input [7:0] b0,
    input [7:0] a1, input [7:0] b1,
    input [7:0] a2, input [7:0] b2,
    input [7:0] a3, input [7:0] b3,
    input [7:0] a4, input [7:0] b4,
    input [7:0] a5, input [7:0] b5,
    input [7:0] a6, input [7:0] b6,
    input [7:0] a7, input [7:0] b7,
    input [7:0] a8, input [7:0] b8,
    input [7:0] a9, input [7:0] b9
);
begin
    a_vec = {a9,a8,a7,a6,a5,a4,a3,a2,a1,a0};
    b_vec = {b9,b8,b7,b6,b5,b4,b3,b2,b1,b0};

    @(negedge clk);
    valid_in = 1;

    @(posedge clk);

    @(negedge clk);
    valid_in = 0;
end
endtask

//====================================
// MAIN TEST
//====================================
initial begin
    rst = 1;
    en = 1;
    valid_in = 0;
    clr_acc  = 0;
    a_vec    = 0;
    b_vec    = 0;

    #20 rst = 0;

    //=======================
    // Clear ACC
    //=======================
    @(negedge clk) clr_acc = 1;
    @(negedge clk) clr_acc = 0;

    //=======================
    // Test 1 (giống test 2 cũ)
    // Expected = 127
    //=======================
    send_10_pairs(
        3,4, 10,2, 5,5, 1,7, 2,9,
        4,6, 8,1,  3,3, 9,0, 2,2
    );
    repeat (LAT+3) @(posedge clk);
    $display("TEST 1 Expected=127 | Output=%0d | valid=%0b", acc_out, valid_out);

    //=======================
    // Test 2
    //=======================
    send_10_pairs(
        1,1,  2,2,  3,3,  4,4,  5,5,
        6,6,  7,7,  8,8,  9,9,  10,10
    );
    repeat (LAT+3) @(posedge clk);
    $display("TEST 2 Expected=385 | Output=%0d | valid=%0b", acc_out, valid_out);

    //=======================
    // Test 3
    //=======================
    send_10_pairs(
        5,10,  4,8,   3,6,   2,4,   1,2,
        10,5,  8,4,   6,3,   4,2,   2,1
    );
    // Expected = 5*10+4*8+... = 170
    repeat (LAT+3) @(posedge clk);
    $display("TEST 3 Expected=170 | Output=%0d | valid=%0b", acc_out, valid_out);

    //=======================
    // Test 4
    //=======================
    send_10_pairs(
        9,1,  8,2,  7,3,  6,4,  5,5,
        4,6,  3,7,  2,8,  1,9,  0,10
    );
    // Expected = 165
    repeat (LAT+3) @(posedge clk);
    $display("TEST 4 Expected=165 | Output=%0d | valid=%0b", acc_out, valid_out);

    $finish;
end

endmodule




