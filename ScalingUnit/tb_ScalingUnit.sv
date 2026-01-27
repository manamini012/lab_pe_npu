
`timescale 1ns/1ps

module testbench;

    // --- Thong so ---
    parameter CLK_PERIOD = 10;
    logic clk;
    logic rst_n;

    logic signed [31:0] tb_data_in;
    logic signed [31:0] tb_scale_M;
    logic [4:0]         tb_scale_N;
    logic               tb_valid_in;
    
    logic signed [7:0]  tb_data_out;
    logic               tb_valid_out;

    // --- Hang doi (Queue) de luu ket qua mong doi ---
    // Day la mau chot cua testbench back-to-back
    logic signed [7:0] expected_results[$];

    // --- Bien dem Thong ke ---
    integer error_count = 0;
    integer pass_count = 0;
    integer test_count = 0;

    // --- Khoi tao DUT (Design Under Test) ---
    ScalingUnit dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (tb_data_in),
        .scale_M    (tb_scale_M),
        .scale_N    (tb_scale_N),
        .valid_in   (tb_valid_in),
        .data_out   (tb_data_out),
        .valid_out  (tb_valid_out)
    );

    // --- Tao Clock ---
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2);
        clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // --- Khoi Gui Du lieu (Stimulus) ---
    initial begin
        $display("--- Bat dau Testbench Nang cao ---");
        
        // 1. Khoi tao va Reset
        tb_valid_in = 1'b0;
        rst_n = 1'b0; // Kich hoat reset
        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1; // Nha reset
        @(posedge clk);

        // 2. Nap (Load) cac ket qua mong doi vao hang doi (Queue)
        // Day la 11 test case chung ta se gui
        expected_results.push_back(12);   // Case 1:  Smoke Test 1 (100 * 0.123)
        expected_results.push_back(127);  // Case 2:  Smoke Test 2 (Saturate Pos)
        expected_results.push_back(-128); // Case 3:  Smoke Test 3 (Saturate Neg)
        //
        // <<< SUA LOI TAI DAY >>>
        // Sua tu 20 thanh 40.
        //
        expected_results.push_back(40);   // Case 4:  Smoke Test 4 (Neg * Neg)
        //
        expected_results.push_back(70);   // Case 5:  PRIO 1 (N=0)
        expected_results.push_back(127);  // Case 6:  PRIO 3.1 (Boundary Max)
        expected_results.push_back(127);  // Case 7:  PRIO 3.2 (Boundary Max+)
        expected_results.push_back(-128); // Case 8:  PRIO 3.3 (Boundary Min)
        expected_results.push_back(-128); // Case 9:  PRIO 3.4 (Boundary Min-)
        expected_results.push_back(1);    // Case 10: PRIO 4.1 (Round Up)
        expected_results.push_back(0);    // Case 11: PRIO 4.2 (Round Down)

        $display("[Stimulus] Da nap %0d test case vao hang doi.", expected_results.size());

        // 3. Gui 11 Test Case Lien tuc (Back-to-Back)
        $display("[Stimulus] Bat dau gui chuoi du lieu (back-to-back)...");
        
        // --- Case 1: Smoke Test 1 ---
        test_count++;
        tb_data_in  = 100;
        tb_scale_M  = 126;  // ~0.123
        tb_scale_N  = 10;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 2: Smoke Test 2 (Saturate Pos) ---
        test_count++;
        tb_data_in  = 123456;
        tb_scale_M  = 126;
        tb_scale_N  = 10;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 3: Smoke Test 3 (Saturate Neg) ---
        test_count++;
        tb_data_in  = -123456;
        tb_scale_M  = 126;
        tb_scale_N  = 10;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 4: Smoke Test 4 (Neg * Neg) ---
        test_count++;
        tb_data_in  = -20;
        tb_scale_M  = -2048; // -2.0
        tb_scale_N  = 10;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 5: PRIO 1 (N=0) ---
        test_count++;
        tb_data_in  = 70;
        tb_scale_M  = 1;
        tb_scale_N  = 0;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 6: PRIO 3.1 (Boundary Max) ---
        test_count++;
        tb_data_in  = 127;
        tb_scale_M  = 1;
        tb_scale_N  = 0;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 7: PRIO 3.2 (Boundary Max+) ---
        test_count++;
        tb_data_in  = 128;
        tb_scale_M  = 1;
        tb_scale_N  = 0;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 8: PRIO 3.3 (Boundary Min) ---
        test_count++;
        tb_data_in  = -128;
        tb_scale_M  = 1;
        tb_scale_N  = 0;
        tb_valid_in = 1'b1;
        @(posedge clk);
        
        // --- Case 9: PRIO 3.4 (Boundary Min-) ---
        test_count++;
        tb_data_in  = -129;
        tb_scale_M  = 1;
        tb_scale_N  = 0;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 10: PRIO 4.1 (Round Up) ---
        test_count++;
        tb_data_in  = 17;   // (17*1 + 16) >> 5 = 33 >> 5 = 1
        tb_scale_M  = 1;
        tb_scale_N  = 5;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // --- Case 11: PRIO 4.2 (Round Down) ---
        test_count++;
        tb_data_in  = 15;   // (15*1 + 16) >> 5 = 31 >> 5 = 0
        tb_scale_M  = 1;
        tb_scale_N  = 5;
        tb_valid_in = 1'b1;
        @(posedge clk);

        // 4. Dung gui va cho ket qua
        tb_valid_in = 1'b0;
        $display("[Stimulus] Da gui %0d test case. Dang cho ket qua...", test_count);

        // Cho them 20 chu ky de tat ca ket qua di ra
        repeat (20) @(posedge clk);

        // 5. Bao cao ket qua
        $display("--- Ket thuc Testbench ---");
        if (error_count == 0 && pass_count == test_count) begin
            $display("[STATUS] PASSED!");
            $display("         Tat ca %0d test case deu dung.", pass_count);
        end else begin
            $display("[STATUS] FAILED!");
            $display("         PASS: %0d/%0d", pass_count, test_count);
            $display("         ERROR: %0d", error_count);
            if (expected_results.size() > 0) begin
                $display("         LOI: %0d ket qua khong bao gio di ra.", expected_results.size());
            end
        end
        
        $stop;
    end

    // --- Khoi Kiem tra Ket qua (Checker) ---
    // Khoi nay chay song song va kiem tra moi khi valid_out bat len
    always @(posedge clk) begin
        if (rst_n == 0) begin
            // Clear hang doi neu bi reset
            expected_results.delete();
        end 
        else if (tb_valid_out) begin
            if (expected_results.size() == 0) begin
                $error("[Checker] LOI: Nhan duoc valid_out nhung khong mong doi ket qua nao!");
                error_count++;
            end else begin
                // Lay ket qua mong doi tu hang doi
                logic signed [7:0] expected_val;
                expected_val = expected_results.pop_front();

                // So sanh
                if (tb_data_out == expected_val) begin
                    $display("[Checker] PASS: Ket qua = %0d (Dung)", tb_data_out);
                    pass_count++;
                end else begin
                    $error("[Checker] LOI: Ket qua = %0d. Mong doi = %0d", tb_data_out, expected_val);
                    error_count++;
                end
            end
        end
    end

endmodule