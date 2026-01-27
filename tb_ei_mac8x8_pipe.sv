`timescale 1ns/1ps

module tb_ei_mac8x8_pipe;

    //====================================
    // Parameter
    //====================================
    localparam LAT = 3;    // latency của multiplier

    //====================================
    // DUT signals
    //====================================
    reg         clk;
    reg         rst;
    reg         en;

    reg         valid_in;
    reg         clr_acc;

    reg  [7:0]  a_in;
    reg  [7:0]  b_in;

    wire [31:0] acc_out;
    wire        valid_out;

    //====================================
    // Instantiate DUT
    //====================================
    ei_mac8x8_pipe #(.LAT(LAT)) dut (
        .clk       (clk),
        .rst       (rst),
        .en        (en),

        .valid_in  (valid_in),
        .clr_acc   (clr_acc),

        .a_in      (a_in),
        .b_in      (b_in),

        .acc_out   (acc_out),
        .valid_out (valid_out)
    );

    //====================================
    // Clock 100 MHz
    //====================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //====================================
    // Task: Gửi 1 cặp (a,b)
    //====================================
    task send_ab(input [7:0] a, input [7:0] b);
    begin
        @(negedge clk);
        valid_in = 1;
        a_in     = a;
        b_in     = b;

        @(posedge clk);

        @(negedge clk);
        valid_in = 0;
    end
    endtask

    //====================================
    // MAIN TEST
    //====================================
    initial begin
        // init
        rst      = 1;
        en       = 1;      // bật enable toàn thời gian
        valid_in = 0;
        clr_acc  = 0;

        a_in = 0;
        b_in = 0;

        // reset 20ns
        #20;
        rst = 0;

        //===========================
        // Test 1: clear accumulator
        //===========================
        @(negedge clk);
        clr_acc = 1;

        @(posedge clk);
        @(negedge clk);
        clr_acc = 0;

        //===========================
        // Test 2: gửi 3 cặp (a,b)
        //===========================
        send_ab( 8'd3 , 8'd4  );  // 12
        send_ab( 8'd10, 8'd2  );  // +20 = 32
        send_ab( 8'd5 , 8'd5  );  // +25 = 57

        repeat (10) @(posedge clk);

        //===========================
        // Test 3: random 5 lần
        //===========================
        repeat (5) begin
            send_ab($random, $random);
        end

        repeat (20) @(posedge clk);

        $finish;
    end

endmodule
