`timescale 1ns/1ps

module ei_mac8x8_pipe #(
    parameter LAT = 3          // latency của bộ nhân pipeline
)(
    input         clk,
    input         rst,
    input         en,

    input         valid_in,    // 1: (a_in,b_in) hợp lệ ở chu kỳ này
    input         clr_acc,     // 1: clear accumulator về 0

    input  [7:0]  a_in,
    input  [7:0]  b_in,

    output [31:0] acc_out,     // giá trị tích luỹ
    output        valid_out    // 1: acc_out vừa được update
);

    //========================
    // 1) Multiplier pipeline 8x8 -> 16 bit
    //========================
    wire [15:0] prod;

    ei_multiplier mul_inst (
        .clk   (clk),
        .rst   (rst),
        .en    (en),
        .a_in  (a_in),
        .b_in  (b_in),
        .c_out (prod)
    );

    //========================
    // 2) Pipeline valid để canh đúng sản phẩm
    //========================
    reg [LAT:0] valid_shift;

    always @(posedge clk) begin
        if (rst)
            valid_shift <= {(LAT+1){1'b0}};
        else if (en)
            valid_shift <= {valid_shift[LAT-1:0], valid_in};
    end

    wire mul_valid = valid_shift[LAT];
    assign valid_out = mul_valid;   // lúc này prod đã khớp với data cách đây LAT chu kỳ

    //========================
    // 3) Accumulator 32-bit
    //========================
    reg  [31:0] acc_reg;
    wire [31:0] acc_next;
    wire        acc_cout;

    // mở rộng prod 16-bit lên 32-bit
    wire [31:0] prod_ext = {16'b0, prod};

    // dùng ei_adder32 để cộng acc_reg + prod_ext
    adder32 acc_adder (
        .a   (acc_reg),
        .b   (prod_ext),
        .sum (acc_next),
        .cout(acc_cout)    // bỏ qua nếu không cần
    );

    always @(posedge clk) begin
        if (rst)
            acc_reg <= 32'd0;
        else if (en) begin
            if (clr_acc)
                acc_reg <= 32'd0;       // bắt đầu MAC mới
            else if (mul_valid)
                acc_reg <= acc_next;    // chỉ update khi sản phẩm đã hợp lệ
        end
    end

    assign acc_out = acc_reg;

endmodule