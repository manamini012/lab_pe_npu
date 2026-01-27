`timescale 1ns / 1ps

module FP_Add_16 (
    input wire clk,
    input wire rst,
    input wire [15:0] A,
    input wire [15:0] B,
    output reg [15:0] Sum_Out
);

    // ==========================================
    // GIAI ĐOẠN 1: TÁCH BIT & SO SÁNH
    // ==========================================
    
    // 1. Unpack
    // Chú ý: Kiểm tra 0 phải kiểm tra cả Exponent và Mantissa (trừ bit dấu)
    wire A_is_Zero = (A[14:0] == 15'd0); 
    wire B_is_Zero = (B[14:0] == 15'd0);
    
    wire sA = A[15]; wire [4:0] eA = A[14:10]; wire [10:0] mA = {1'b1, A[9:0]};
    wire sB = B[15]; wire [4:0] eB = B[14:10]; wire [10:0] mB = {1'b1, B[9:0]};

    // 2. So sánh mũ (Dùng ei_adder8 hoặc so sánh trực tiếp)
    // Để an toàn và chính xác nhất cho việc so sánh, ta dùng logic > của Verilog
    // (Bên dưới vẫn dùng ei_adder cho phép tính toán, nhưng so sánh nên dùng wire)
    wire A_is_Big_Exp = (eA > eB);
    wire Exp_Equal    = (eA == eB);
    wire A_Mant_Larger = (mA >= mB);
    
    // Logic xác định số lớn/nhỏ chính xác tuyệt đối
    wire A_is_Big = A_is_Big_Exp || (Exp_Equal && A_Mant_Larger);

    // 3. Swap (Hoán đổi) để luôn có: Big - Small
    wire [10:0] mant_big   = A_is_Big ? mA : mB;
    wire [10:0] mant_small = A_is_Big ? mB : mA;
    wire [4:0]  exp_common = A_is_Big ? eA : eB;
    wire        sign_big   = A_is_Big ? sA : sB;
    wire        sign_small = A_is_Big ? sB : sA;

    // 4. Tính độ lệch mũ (Shift Amount)
    // e_big - e_small
    wire [7:0] diff;
    ei_adder8 u_diff_calc (
        .a({3'b0, exp_common}),
        .b(~{3'b0, (A_is_Big ? eB : eA)}), // Cộng bù 1
        .cin(1'b1),                        // Cộng thêm 1 -> Bù 2 (Phép trừ)
        .sum(diff),
        .cout()
    );

    // 5. Dịch bit (Alignment)
    wire [31:0] m_big_32   = {mant_big, 21'b0}; // 1.xxxx...000
    // Giới hạn dịch tối đa 26 bit để tránh mất hết dữ liệu
    wire [4:0]  shift_amt  = (diff > 26) ? 5'd26 : diff[4:0];
    wire [31:0] m_small_32 = {mant_small, 21'b0} >> shift_amt; 

    // 6. Quyết định Cộng hay Trừ
    // Nếu cùng dấu -> Cộng. Khác dấu -> Trừ (Vì đã swap nên luôn lấy Big - Small)
    wire do_sub = sign_big ^ sign_small; 

    // Chuẩn bị operand cho adder
    // Nếu trừ: Lấy bù 1 của số nhỏ. Bit cin=1 ở stage sau sẽ biến nó thành bù 2.
    wire [31:0] operand2 = do_sub ? ~m_small_32 : m_small_32;

    // ==========================================
    // PIPELINE REGISTER (Giữ nguyên cấu trúc của bạn)
    // ==========================================
    reg [31:0] reg_m_big;
    reg [31:0] reg_operand2;
    reg        reg_do_sub;
    reg [4:0]  reg_exp_common;
    reg        reg_sign_big;
    reg        reg_A_is_Zero, reg_B_is_Zero;
    reg [15:0] reg_A, reg_B;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_m_big <= 0; reg_operand2 <= 0; reg_do_sub <= 0;
            reg_exp_common <= 0; reg_sign_big <= 0;
            reg_A_is_Zero <= 0; reg_B_is_Zero <= 0;
            reg_A <= 0; reg_B <= 0;
        end else begin
            reg_m_big      <= m_big_32;
            reg_operand2   <= operand2;
            reg_do_sub     <= do_sub;
            reg_exp_common <= exp_common;
            reg_sign_big   <= sign_big;
            
            reg_A_is_Zero  <= A_is_Zero;
            reg_B_is_Zero  <= B_is_Zero;
            reg_A          <= A;
            reg_B          <= B;
        end
    end

    // ==========================================
    // GIAI ĐOẠN 2: CỘNG/TRỪ & CHUẨN HÓA
    // ==========================================
    
    wire [31:0] sum_result;
    wire adder_cout;

    // QUAN TRỌNG: Kiểm tra lại module ei_adder32 của bạn
    // Nó phải có port .cin hoạt động đúng thì phép trừ mới đúng!
    ei_adder32 u_mant_add (
        .a(reg_m_big),
        .b(reg_operand2),
        .cin(reg_do_sub), // Nếu trừ, cin=1 để hoàn thành bù 2 (A + ~B + 1)
        .sum(sum_result),
        .cout(adder_cout)
    );

    // --- Logic Chuẩn hóa (Normalization) ---
    reg [15:0] Calculated_Sum;
    reg [4:0]  leading_zeros;
    reg [31:0] mant_normalized;
    reg [9:0]  exp_adjusted;

    always @(*) begin
        // 1. Tìm Leading Zeros (Priority Encoder 32-bit)
        // Tìm bit 1 đầu tiên từ trái sang phải
        if      (sum_result[31]) leading_zeros = 0;
        else if (sum_result[30]) leading_zeros = 1;
        else if (sum_result[29]) leading_zeros = 2;
        else if (sum_result[28]) leading_zeros = 3;
        else if (sum_result[27]) leading_zeros = 4;
        else if (sum_result[26]) leading_zeros = 5;
        else if (sum_result[25]) leading_zeros = 6;
        else if (sum_result[24]) leading_zeros = 7;
        else if (sum_result[23]) leading_zeros = 8;
        else if (sum_result[22]) leading_zeros = 9;
        else if (sum_result[21]) leading_zeros = 10;
        else if (sum_result[20]) leading_zeros = 11;
        else if (sum_result[19]) leading_zeros = 12;
        else if (sum_result[18]) leading_zeros = 13;
        else if (sum_result[17]) leading_zeros = 14;
        else if (sum_result[16]) leading_zeros = 15;
        else                     leading_zeros = 31; // Trường hợp = 0

        // 2. Mặc định
        exp_adjusted = {5'b0, reg_exp_common};
        mant_normalized = sum_result;

        // 3. Xử lý Logic
        if (reg_do_sub) begin
            // --- TRƯỜNG HỢP TRỪ ---
            if (sum_result == 0) begin
                Calculated_Sum = 16'd0; // Triệt tiêu hoàn toàn (VD: 2 - 2 = 0)
            end else begin
                // Dịch trái để đẩy số 1 lên đầu (Normalize)
                mant_normalized = sum_result << leading_zeros;
                
                // Giảm mũ tương ứng
                if (exp_adjusted > leading_zeros)
                    exp_adjusted = exp_adjusted - leading_zeros;
                else
                    exp_adjusted = 0; // Underflow (Mũ về 0)
                
                // Đóng gói kết quả: Sign | Exp | Mantissa
                // Lưu ý: Lấy 10 bit sau bit '1' dẫn đầu (bit 31 sau khi dịch)
                Calculated_Sum = {reg_sign_big, exp_adjusted[4:0], mant_normalized[30:21]};
            end
        end 
        else begin
            // --- TRƯỜNG HỢP CỘNG ---
            if (adder_cout) begin
                // Tràn (Overflow): 1.xxx + 1.xxx = 1x.xxx -> Dịch phải
                mant_normalized = {1'b1, sum_result[31:1]}; 
                exp_adjusted = exp_adjusted + 1;
            end
            
            // Kiểm tra tràn mũ (Infinity)
            if (exp_adjusted >= 31) 
                Calculated_Sum = {reg_sign_big, 5'b11111, 10'b0}; 
            else
                Calculated_Sum = {reg_sign_big, exp_adjusted[4:0], mant_normalized[30:21]};
        end
    end

    // ==========================================
    // OUTPUT REGISTER
    // ==========================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Sum_Out <= 0;
        end else begin
            // Ưu tiên Logic Bypass cho số 0
            if (reg_A_is_Zero & reg_B_is_Zero) begin
                Sum_Out <= 0;
            end else if (reg_A_is_Zero) begin
                Sum_Out <= reg_B; // Nếu A=0, Output = B (Bảo toàn dấu của B)
            end else if (reg_B_is_Zero) begin
                Sum_Out <= reg_A; // Nếu B=0, Output = A (Bảo toàn dấu của A)
            end else begin
                Sum_Out <= Calculated_Sum;
            end
        end
    end

endmodule