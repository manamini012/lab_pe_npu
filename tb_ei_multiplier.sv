`timescale 1ns/1ps

module tb_ei_multiplier;

    reg clk;
    reg rst;
    reg en;
    reg [7:0] a_in, b_in;
    wire [15:0] c_out;

    // DUT
    ei_multiplier dut (
        .clk   (clk),
        .rst   (rst),
        .en    (en),
        .a_in  (a_in),
        .b_in  (b_in),
        .c_out (c_out)
    );

    // Clock 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Main stimulus
    initial begin
        // init
        rst  = 1;
        en   = 1;
        a_in = 0;
        b_in = 0;

        // reset phase
        #20;
        rst = 0;

        // ---- Test 1 ----
        @(posedge clk);
        en   = 1;
        a_in = 8'd3;
        b_in = 8'd4;

        @(posedge clk);  // giữ thêm 1 chu kỳ để dễ xem
        en = 1;

        // ---- Test 2 ----
        #20;
        @(posedge clk);
        en   = 1;
        a_in = 8'd10;
        b_in = 8'd20;

        @(posedge clk);
        en = 1;

        // ---- Test 3: random ----
        #20;
        repeat (5) begin
            @(posedge clk);
            en   = 1;
            a_in = $random;
            b_in = $random;

            @(posedge clk);
            @(posedge clk);
            en = 1;
        end

        #100;
        $finish;
    end

endmodule


