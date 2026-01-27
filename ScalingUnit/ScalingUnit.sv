
module ScalingUnit #(
    parameter IN_WIDTH  = 32, 
    parameter M_WIDTH   = 32, 
    parameter N_WIDTH   = 5,  
    parameter OUT_WIDTH = 8   
)(
    input logic clk,
    input logic rst_n, 

    // Giao diện đầu vào
    input logic valid_in,
    input logic signed [IN_WIDTH-1:0]  data_in, 
    input logic signed [M_WIDTH-1:0]  scale_M, 
    input logic [N_WIDTH-1:0]          scale_N, 

    // Giao diện đầu ra
    output logic valid_out,
    output logic signed [OUT_WIDTH-1:0] data_out 
);

    localparam TOTAL_WIDTH = IN_WIDTH + M_WIDTH;
    localparam MAX_VAL =  (1 << (OUT_WIDTH-1)) - 1; 
    localparam MIN_VAL = -(1 << (OUT_WIDTH-1));     

    // --- ĐĂNG KÝ PIPELINE ---
    logic valid_reg1;
    logic signed [TOTAL_WIDTH - 1:0] mult_result_reg; 
    logic [N_WIDTH-1:0]              scale_N_reg;
    logic valid_reg2;
    logic signed [TOTAL_WIDTH - 1:0] shift_result_reg;


    // --- TẦNG 1: NHÂN (MULTIPLY STAGE) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg1      <= 1'b0;
            mult_result_reg <= '0;
            scale_N_reg     <= '0;
        end else begin
            if (valid_in) begin
                // 1. Khi có dữ liệu MỚI, chốt nó và bật valid
                valid_reg1      <= 1'b1;
                mult_result_reg <= data_in * scale_M; 
                scale_N_reg     <= scale_N;
            end else begin
                // 2. Khi không có dữ liệu, hủy valid
                valid_reg1      <= 1'b0;
            end
        end
    end

    
    // --- TẦNG 2: DỊCH BIT & LÀM TRÒN (SHIFT & ROUND STAGE) ---
    
    logic signed [TOTAL_WIDTH - 1:0] round_val;
    logic signed [TOTAL_WIDTH - 1:0] rounded_result;
    logic signed [TOTAL_WIDTH - 1:0] shift_result_comb;
    logic signed [TOTAL_WIDTH - 1:0] one_64bit_helper = 1;

    // Logic tổ hợp (Combinational) của Tầng 2:
    always_comb begin
        
        // 1. Tính giá trị làm tròn (offset)
        round_val = (scale_N_reg == 0) ? 0 : ( one_64bit_helper << (scale_N_reg - 1) );

        // 2. Cộng giá trị làm tròn
        rounded_result = mult_result_reg + round_val;
        
        // 3. Dịch phải SỐ HỌC (>>>)
        shift_result_comb = rounded_result >>> scale_N_reg;
    end

    // Logic tuần tự (Sequential) của Tầng 2: Chốt kết quả vào thanh ghi
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg2       <= 1'b0;
            shift_result_reg <= '0;
        end else begin
            valid_reg2 <= valid_reg1; 
            if (valid_reg1) begin
                shift_result_reg <= shift_result_comb; 
            end
        end
    end


    // --- TẦNG 3: BÃO HÒA & ĐẦU RA (SATURATE & OUTPUT STAGE) ---
    
    logic signed [OUT_WIDTH-1:0] saturated_result; 

    always_comb begin
        if (shift_result_reg > MAX_VAL) begin
            saturated_result = MAX_VAL;
        end else if (shift_result_reg < MIN_VAL) begin
            saturated_result = MIN_VAL;
        end else begin
            saturated_result = shift_result_reg[OUT_WIDTH-1:0];
        end
    end

    // Thanh ghi đầu ra (Logic tuần tự)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out  <= '0;
        end else begin
            valid_out <= valid_reg2; 
            if (valid_reg2) begin
                data_out  <= saturated_result;
            end
        end
    end

endmodule