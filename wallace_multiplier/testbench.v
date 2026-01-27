`timescale 1ns/1ps

module testbench;

    // 1. Khai báo tín hiệu 32-BIT
    reg clk;
    reg rst_n;
    reg valid_in;
    
    // Tham số
    parameter WIDTH = 32;

    reg signed [WIDTH-1:0] A, B;       // Input 32-bit
    wire signed [2*WIDTH-1:0] P;       // Output 64-bit
    wire valid_out;

    integer error_count = 0;

    // 2. Kết nối Module (Đúng tên wallace_multiplier)
    // Truyền tham số WIDTH = 32 vào
    wallace_multiplier #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .A(A),
        .B(B),
        .P(P)
    );

    // 3. Clock 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Mô hình Tham chiếu (Pipeline Delay = 3 CLK)
    reg signed [WIDTH-1:0] A_d1, B_d1;
    reg signed [WIDTH-1:0] A_d2, B_d2;
    reg signed [WIDTH-1:0] A_d3, B_d3;
    wire signed [2*WIDTH-1:0] expected_P;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_d1 <= 0; B_d1 <= 0;
            A_d2 <= 0; B_d2 <= 0;
            A_d3 <= 0; B_d3 <= 0;
        end else begin
            // Shift Register luôn chạy
            A_d1 <= A;    B_d1 <= B;
            A_d2 <= A_d1; B_d2 <= B_d1;
            A_d3 <= A_d2; B_d3 <= B_d2;
        end
    end
    
    assign expected_P = A_d3 * B_d3; // So sánh với quá khứ 3 nhịp

    // 5. Checker
    always @(posedge clk) begin
        if (rst_n && valid_out) begin
            if (P !== expected_P) begin
                $display("[FAIL] Time %0t: %d x %d = %d (Expected: %d)", 
                         $time, A_d3, B_d3, P, expected_P);
                error_count = error_count + 1;
            end
        end
    end

    // 6. Test Case
    initial begin
        rst_n = 0; valid_in = 0; A = 0; B = 0;
        #20 rst_n = 1;

        $display("=== START 32-BIT TEST ===");

        // Test cơ bản
        @(posedge clk); valid_in = 1; A = 100; B = 200;
        @(posedge clk); valid_in = 1; A = -50; B = 100;
        
        // Test Số lớn (Max Positive 32-bit)
        // 2,147,483,647
        @(posedge clk); valid_in = 1; A = 2147483647; B = 2; 

        // Test Số cực nhỏ (Min Negative 32-bit)
        // -2,147,483,648
        @(posedge clk); valid_in = 1; A = -2147483648; B = 1;

        // Random Test
        repeat (20) begin
            @(posedge clk);
            A = $random; 
            B = $random;
        end

        @(posedge clk); valid_in = 0;
        #100;
        
        if (error_count == 0) 
            $display("SUCCESS: 32-BIT OK!");
        else
            $display("FAILURE: %d Errors found", error_count);
            
        $stop;
    end

endmodule