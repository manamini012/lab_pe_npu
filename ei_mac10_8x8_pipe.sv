//////module ei_mac10_8x8_pipe #(
//////    parameter LAT = 3
//////)(
//////    input         clk,
//////    input         rst,
//////    input         en,

//////    input         valid_in,
//////    input         clr_acc,

//////    input  [79:0] a_vec,   // 10 giá trị 8 bit
//////    input  [79:0] b_vec,

//////    output [31:0] sum_out, // accumulator 32bit
//////    output        valid_out
//////);

//////    // =======================================
//////    // Tách 10 số 8-bit
//////    // =======================================
//////    wire [7:0] a [0:9];
//////    wire [7:0] b [0:9];

//////    genvar gi;
//////    generate
//////        for (gi = 0; gi < 10; gi = gi + 1) begin
//////            assign a[gi] = a_vec[gi*8 +: 8];
//////            assign b[gi] = b_vec[gi*8 +: 8];
//////        end
//////    endgenerate

//////    // =======================================
//////    // 10 MAC lane
//////    // =======================================
//////    // CHANGE THIS IF YOUR MODULE OUTPUT IS 32-bit
//////    wire [15:0] prod [0:9];

//////    wire lane_valid;

//////    genvar i;
//////    generate
//////        for (i = 0; i < 10; i = i + 1) begin : GEN_MAC
//////            ei_mac8x8_pipe #(.LAT(LAT)) mac_lane (
//////                .clk      (clk),
//////                .rst      (rst),
//////                .en       (en),
//////                .valid_in (valid_in),
//////                .clr_acc  (1'b0),
//////                .a_in     (a[i]),
//////                .b_in     (b[i]),
//////                .acc_out  (prod[i]),
//////                .valid_out()
//////            );
//////        end
//////    endgenerate

//////    // valid chung → dùng valid_out của lane 0
//////    assign lane_valid = GEN_MAC[0].mac_lane.valid_out;

//////    // =======================================
//////    // Cộng 10 sản phẩm
//////    // =======================================
//////    reg  [31:0] acc_reg;
//////    reg  [31:0] temp_sum;

//////    integer k;

//////    always @(*) begin
//////        temp_sum = 0;
//////        for (k = 0; k < 10; k = k + 1)
//////            temp_sum = temp_sum + prod[k];
//////    end

//////    // =======================================
//////    // Accumulator 32 bit
//////    // =======================================
//////    always @(posedge clk) begin
//////        if (rst)
//////            acc_reg <= 0;
//////        else if (en) begin
//////            if (clr_acc)
//////                acc_reg <= 0;
//////            else if (lane_valid)
//////                acc_reg <= acc_reg + temp_sum;
//////        end
//////    end

//////    assign sum_out  = acc_reg;
//////    assign valid_out = lane_valid;

//////endmodule








////`timescale 1ns/1ps

////module ei_mac10_8x8_pipe #(
////    parameter LAT = 3        // latency của từng ei_mac8x8_pipe
////)(
////    input         clk,
////    input         rst,
////    input         en,

////    input         valid_in,
////    input         clr_acc,

////    input  [79:0] a_vec,     // 10 x 8-bit = 80 bit
////    input  [79:0] b_vec,

////    output [31:0] acc_out,   // tổng 10 sản phẩm
////    output        valid_out
////);

////    //===============================================
////    // 1) Sinh ra 10 instance ei_mac8x8_pipe
////    //===============================================
////    wire [31:0] acc_i [0:9];
////    wire [9:0]  val_i;

////    genvar k;
////    generate
////        for (k=0; k<10; k=k+1) begin : MAC10
////            ei_mac8x8_pipe #(.LAT(LAT)) mac_unit (
////                .clk       (clk),
////                .rst       (rst),
////                .en        (en),
////                .valid_in  (valid_in),
////                .clr_acc   (clr_acc),
////                .a_in      (a_vec[8*k +: 8]),
////                .b_in      (b_vec[8*k +: 8]),
////                .acc_out   (acc_i[k]),
////                .valid_out (val_i[k])
////            );
////        end
////    endgenerate

////    //===============================================
////    // 2) Khi tất cả 10 bộ đều valid thì output valid
////    //===============================================
////    wire all_valid = &val_i;
////    assign valid_out = all_valid;

////    //===============================================
////    // 3) Cộng tổng 10 giá trị acc_i[k]
////    //===============================================
////    reg [31:0] sum_reg;

////    always @(posedge clk) begin
////        if (rst)
////            sum_reg <= 32'd0;
////        else if (en) begin
////            if (clr_acc)
////                sum_reg <= 32'd0;
////            else if (all_valid)
////                sum_reg <= acc_i[0] + acc_i[1] + acc_i[2] + acc_i[3] + acc_i[4] +
////                           acc_i[5] + acc_i[6] + acc_i[7] + acc_i[8] + acc_i[9];
////        end
////    end

////    assign acc_out = sum_reg;

////endmodule




//`timescale 1ns/1ps

//module ei_mac8x8_pipe #(
//    parameter LAT = 3          // latency của bộ nhân pipeline
//)(
//    input         clk,
//    input         rst,
//    input         en,

//    input         valid_in,    // 1: (a_in,b_in) hợp lệ ở chu kỳ này
//    input         clr_acc,     // 1: clear accumulator về 0

//    input  [7:0]  a_in,
//    input  [7:0]  b_in,

//    output [31:0] acc_out,     // giá trị tích luỹ
//    output        valid_out    // 1: acc_out vừa được update
//);

//    //========================
//    // 1) Multiplier pipeline 8x8 -> 16 bit
//    //========================
//    wire [15:0] prod;

//    ei_multiplier mul_inst (
//        .clk   (clk),
//        .rst   (rst),
//        .en    (en),
//        .a_in  (a_in),
//        .b_in  (b_in),
//        .c_out (prod)
//    );

//    //========================
//    // 2) Pipeline valid để canh đúng sản phẩm
//    //========================
//    reg [LAT:0] valid_shift;

//    always @(posedge clk) begin
//        if (rst)
//            valid_shift <= {(LAT+1){1'b0}};
//        else if (en)
//            valid_shift <= {valid_shift[LAT-1:0], valid_in};
//    end

//    wire mul_valid = valid_shift[LAT];
//    assign valid_out = mul_valid;   // lúc này prod đã khớp với data cách đây LAT chu kỳ

//    //========================
//    // 3) Accumulator 32-bit
//    //========================
//    reg  [31:0] acc_reg;
//    wire [31:0] acc_next;
//    wire        acc_cout;

//    // mở rộng prod 16-bit lên 32-bit
//    wire [31:0] prod_ext = {16'b0, prod};

//    // dùng ei_adder32 để cộng acc_reg + prod_ext
//    adder32 acc_adder (
//        .a   (acc_reg),
//        .b   (prod_ext),
//        .sum (acc_next),
//        .cout(acc_cout)    // bỏ qua nếu không cần
//    );

//    always @(posedge clk) begin
//        if (rst)
//            acc_reg <= 32'd0;
//        else if (en) begin
//            if (clr_acc)
//                acc_reg <= 32'd0;       // bắt đầu MAC mới
//            else if (mul_valid)
//                acc_reg <= acc_next;    // chỉ update khi sản phẩm đã hợp lệ
//        end
//    end

//    assign acc_out = acc_reg;

//endmodule


`timescale 1ns/1ps

module ei_mac10_8x8_pipe #(
    parameter LAT = 3          // latency của pipeline
)(
    input         clk,
    input         rst,
    input         en,

    input         valid_in,
    input         clr_acc,

    input  [79:0] a_vec,       // 10 số 8-bit
    input  [79:0] b_vec,

    output [31:0] acc_out,     // tổng của 10 tích
    output        valid_out
);

    //=====================================
    // 1) Tách 10 phần tử a,b từ vector 80-bit
    //=====================================
    wire [7:0] a_in [0:9];
    wire [7:0] b_in [0:9];

    genvar idx;
    generate
        for (idx = 0; idx < 10; idx = idx + 1) begin : UNPACK
            assign a_in[idx] = a_vec[idx*8 +: 8];
            assign b_in[idx] = b_vec[idx*8 +: 8];
        end
    endgenerate

    //=====================================
    // 2) 10 multiplier song song
    //=====================================
    wire [15:0] prod [0:9];

    generate
        for (idx = 0; idx < 10; idx = idx + 1) begin : MULS
            ei_multiplier mul_inst (
                .clk   (clk),
                .rst   (rst),
                .en    (en),
                .a_in  (a_in[idx]),
                .b_in  (b_in[idx]),
                .c_out (prod[idx])
            );
        end
    endgenerate

    //=====================================
    // 3) Pipeline valid (căn đúng LAT)
    //=====================================
    reg [LAT:0] valid_shift;

    always @(posedge clk) begin
        if (rst)
            valid_shift <= {(LAT+1){1'b0}};
        else if (en)
            valid_shift <= {valid_shift[LAT-1:0], valid_in};
    end

    wire mul_valid = valid_shift[LAT];
    assign valid_out = mul_valid;

    //=====================================
    // 4) Cộng dồn 10 tích vào sum10
    //=====================================
    reg [31:0] sum10;

    integer k;
    always @(*) begin
        sum10 = 32'd0;
        for (k = 0; k < 10; k = k + 1)
            sum10 = sum10 + prod[k];
    end

    //=====================================
    // 5) Accumulator (nếu muốn lưu nhiều lần)
    //=====================================
    reg [31:0] acc_reg;

    always @(posedge clk) begin
        if (rst)
            acc_reg <= 32'd0;
        else if (en) begin
            if (clr_acc)
                acc_reg <= 32'd0;
            else if (mul_valid)
                acc_reg <= sum10;
        end
    end

    assign acc_out = acc_reg;

endmodule
