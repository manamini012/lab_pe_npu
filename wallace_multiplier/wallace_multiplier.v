module wallace_multiplier #(
    parameter WIDTH = 32 // Mặc định 32-bit
)(
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    output reg  valid_out,
    
    input  signed [WIDTH-1:0] A,
    input  signed [WIDTH-1:0] B,
    output reg signed [2*WIDTH-1:0] P // Output 64-bit
);

    // --- GIAI ĐOẠN 1: TẠO MA TRẬN TÍCH (PPG) ---
    wire [2*WIDTH-1:0] rows [WIDTH-1:0];
    
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_PPG
            for (j = 0; j < WIDTH; j = j + 1) begin : GEN_CELLS
                wire bit_val;
                // Baugh-Wooley: Đảo bit hàng cuối và cột cuối (trừ góc)
                if ((i == WIDTH-1 && j != WIDTH-1) || (i != WIDTH-1 && j == WIDTH-1))
                    assign bit_val = ~(A[j] & B[i]); // NAND
                else
                    assign bit_val = A[j] & B[i];    // AND
                
                // Gán vào đúng trọng số (Shift cứng)
                assign rows[i][i+j] = bit_val;
            end
            
            // Điền 0 vào các bit còn lại
            if (i > 0) assign rows[i][i-1:0] = 0;
            if (i+WIDTH < 2*WIDTH) assign rows[i][2*WIDTH-1 : i+WIDTH] = 0;
        end
    endgenerate

    // --- GIAI ĐOẠN 2: PIPELINE ADDER TREE ---
    
    // [PIPELINE 1] Nén 32 hàng -> 8 tổng
    reg signed [2*WIDTH-1:0] sum_stage1 [7:0];
    reg valid_s1;
    integer k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s1 <= 0;
            for(k=0; k<8; k=k+1) sum_stage1[k] <= 0;
        end else begin
            valid_s1 <= valid_in;
            for(k=0; k<8; k=k+1) begin
                sum_stage1[k] <= rows[4*k] + rows[4*k+1] + rows[4*k+2] + rows[4*k+3];
            end
        end
    end

    // [PIPELINE 2] Nén 8 tổng -> 1 tổng
    reg signed [2*WIDTH-1:0] sum_stage2;
    reg valid_s2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= 0;
            valid_s2 <= 0;
        end else begin
            valid_s2 <= valid_s1;
            sum_stage2 <= sum_stage1[0] + sum_stage1[1] + sum_stage1[2] + sum_stage1[3] +
                          sum_stage1[4] + sum_stage1[5] + sum_stage1[6] + sum_stage1[7];
        end
    end

    // [PIPELINE 3] Final Correction
    wire [2*WIDTH-1:0] bw_constant;
    
    // *** FIX LỖI TẠI ĐÂY ***
    // Cộng 1 vào Bit 32 (WIDTH) và Bit 63 (2*WIDTH-1)
    assign bw_constant = (64'b1 << WIDTH) | (64'b1 << (2*WIDTH-1));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            P <= 0;
            valid_out <= 0;
        end else begin
            if (valid_s2) begin
                P <= sum_stage2 + bw_constant;
                valid_out <= 1;
            end else begin
                valid_out <= 0;
            end
        end
    end

endmodule