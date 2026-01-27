`timescale 1ns / 1ps

module tb_FP_Add_16;

    // --- 1. KHAI BÁO TÍN HIỆU ---
    reg clk;            // [MỚI] Clock
    reg rst;            // [MỚI] Reset
    reg [15:0] in_numA;
    reg [15:0] in_numB;

    wire [15:0] out_data;
    
    integer errors;

    // --- 2. KẾT NỐI MODULE (UUT) ---
    // Gọi module với Clock và Reset
    FP_Add_16 uut (
        .clk(clk),      // [MỚI]
        .rst(rst),      // [MỚI]
        .A(in_numA), 
        .B(in_numB), 
        .Sum_Out(out_data)
    );

    // --- 3. TẠO CLOCK (10ns) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 4. TASK KIỂM TRA (SỬA ĐỔI CHO PIPELINE) ---
    task display_check;
        input [15:0] expect_val;
        input [8*40:1] test_desc;
        begin
            // 1. Đồng bộ input với cạnh lên clock
            @(posedge clk); 
            #1; // Delay xíu để tránh race condition
            
            // (Input in_numA, in_numB đã được gán trước khi gọi task này)

            // 2. CHỜ ĐỘ TRỄ (LATENCY)
            // Mạch tuần tự của bạn tốn 2 chu kỳ để ra kết quả
            // (1 nhịp stage 1 + 1 nhịp output reg)
            repeat(2) @(posedge clk); 
            
            #1; // Đợi sau cạnh lên để đọc kết quả ổn định

            // 3. So sánh
            if (expect_val !== 16'hxxxx && out_data !== expect_val) begin
                $display("[FAIL] %s", test_desc);
                $display("       A: %h | B: %h | Out: %h | Expect: %h", 
                         in_numA, in_numB, out_data, expect_val);
                errors = errors + 1;
            end else if (expect_val != 16'hxxxx) begin
                $display("[PASS] %s | Out: %h", test_desc, out_data);
            end
            
            // Đưa input về 0 để chuẩn bị cho test sau (tùy chọn)
            // in_numA = 0; in_numB = 0; 
        end
    endtask

    // --- 5. CHƯƠNG TRÌNH CHÍNH ---
    initial begin
        $display("==================================================");
        $display("   TESTBENCH FOR FP_ADD_16 (SEQUENTIAL/PIPELINE)  ");
        $display("==================================================");
        
        // Khởi tạo
        in_numA = 0; in_numB = 0; errors = 0;
        
        // RESET HỆ THỐNG
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);
        
        // ---------------------------------------------------------
        // CASE 1: 1.0 + 2.0 = 3.0
        // ---------------------------------------------------------
        in_numA = 16'h3C00; in_numB = 16'h4000;
        display_check(16'h4200, "1.0 + 2.0 = 3.0");

        // ---------------------------------------------------------
        // CASE 2: 1.5 - 1.0 = 0.5
        // ---------------------------------------------------------
        in_numA = 16'h3E00; in_numB = 16'hBC00;
        display_check(16'h3800, "1.5 + (-1.0) = 0.5");

        // ---------------------------------------------------------
        // CASE 3: Cộng với 0
        // ---------------------------------------------------------
        in_numA = 16'h4500; in_numB = 16'h0000;
        display_check(16'h4500, "5.0 + 0.0 = 5.0");
        
        in_numA = 16'h0000; in_numB = 16'h4500;
        display_check(16'h4500, "0.0 + 5.0 = 5.0");

        // ---------------------------------------------------------
        // CASE 4: Triệt tiêu (2.0 - 2.0 = 0)
        // ---------------------------------------------------------
        in_numA = 16'h4000; in_numB = 16'hC000;
        display_check(16'h0000, "2.0 + (-2.0) = 0");

        // ---------------------------------------------------------
        // CASE 5: Số nhỏ (6.0 + 0.125)
        // ---------------------------------------------------------
        in_numA = 16'h4600; in_numB = 16'h3000;
        display_check(16'h4620, "6.0 + 0.125 = 6.125");

        // ==========================================
        // TỔNG KẾT
        // ==========================================
        repeat(5) @(posedge clk); // Đợi thêm chút
        
        $display("==================================================");
        if (errors == 0) 
            $display("   FINAL RESULT: ALL TESTS PASSED (SUCCESS)       ");
        else 
            $display("   FINAL RESULT: FOUND %0d ERRORS (FAILURE)       ", errors);
        $display("==================================================");
        $stop;
    end
      
endmodule