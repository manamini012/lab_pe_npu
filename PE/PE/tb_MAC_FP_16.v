`timescale 1ns / 1ps

module tb_MAC_FP_16;

    // Inputs
    reg clk;
    reg rst;
    reg [15:0] A;
    reg [15:0] B;
    reg [15:0] C;

    // Outputs
    wire [15:0] Acc_Out;

    // Instantiate the Unit Under Test (UUT)
    MAC_FP_16 uut (
        .clk(clk), 
        .rst(rst), 
        .A(A), 
        .B(B), 
        .C(C), 
        .Acc_Out(Acc_Out)
    );

    // Clock Generation (50MHz - Chu kỳ 20ns)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Stimulus
    initial begin
        // --- 1. KHỞI TẠO & RESET ---
        rst = 1; 
        A = 0; B = 0; C = 0;
        
        #100; 
        rst = 0; // Thả Reset
        #20;

        // ==========================================
        // CASE 1: CƠ BẢN (BASIC POSITIVE)
        // Phép tính: 1.0 * 1.0 + 0.5 = 1.5
        // Expect: 3e00
        // ==========================================
        A = 16'h3c00; // 1.0
        B = 16'h3c00; // 1.0
        C = 16'h3800; // 0.5
        #200; // Đợi pipeline xả hết dữ liệu cũ

        // ==========================================
        // CASE 2: NHÂN VỚI 0 (ZERO MULTIPLICATION)
        // Phép tính: 2.0 * 0.0 + 1.5 = 1.5
        // Expect: 3e00 (Bộ nhân phải ra 0, cộng với C)
        // ==========================================
        A = 16'h4000; // 2.0
        B = 16'h0000; // 0.0
        C = 16'h3e00; // 1.5
        #200;

        // ==========================================
        // CASE 3: CỘNG VỚI 0 (ZERO ADDITION)
        // Phép tính: 1.5 * 2.0 + 0.0 = 3.0
        // Expect: 4200
        // ==========================================
        A = 16'h3e00; // 1.5
        B = 16'h4000; // 2.0
        C = 16'h0000; // 0.0
        #200;

        // ==========================================
        // CASE 4: SỐ ÂM (MIXED SIGN)
        // Phép tính: 1.0 * (-2.0) + 1.0 = -1.0
        // Expect: bc00 (Mã Hex của -1.0)
        // Giải thích: -2.0 + 1.0 = -1.0
        // ==========================================
        A = 16'h3c00; // 1.0
        B = 16'hc000; // -2.0 (Bit dấu = 1)
        C = 16'h3c00; // 1.0
        #200;

        // ==========================================
        // CASE 5: TRIỆT TIÊU (CANCELLATION)
        // Phép tính: 1.0 * 2.0 + (-2.0) = 0.0
        // Expect: 0000
        // Đây là case quan trọng check bộ cộng trừ
        // ==========================================
        A = 16'h3c00; // 1.0
        B = 16'h4000; // 2.0
        C = 16'hc000; // -2.0
        #200;

        // ==========================================
        // CASE 6: SỐ LỚN (LARGE NUMBERS)
        // Phép tính: 4.0 * 4.0 + 0 = 16.0
        // Expect: 4c00
        // ==========================================
        A = 16'h4400; // 4.0
        B = 16'h4400; // 4.0
        C = 16'h0000; // 0.0
        #200;
        
        // ==========================================
        // CASE 7: TRỪ RA SỐ ÂM (RESULT NEGATIVE)
        // Phép tính: 1.0 * 1.0 + (-3.0) = -2.0
        // Expect: c000
        // ==========================================
        A = 16'h3c00; // 1.0
        B = 16'h3c00; // 1.0
        C = 16'hc200; // -3.0
        #200;

        $stop;
    end
      
endmodule