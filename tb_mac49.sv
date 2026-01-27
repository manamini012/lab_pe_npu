module adder_tree_49_q16_16_pipe (
    input  logic clk,
    input  logic rst,
    input  logic en,

    input  logic signed [49*32-1:0] in_flat,
    output logic signed [37:0] sum_out      // Q22.16
);

    // -------- Unpack 49 inputs -----------
    logic signed [31:0] L0 [0:48];
    genvar i;
    generate
        for (i=0;i<49;i++)
            assign L0[i] = in_flat[i*32 +: 32];
    endgenerate

    // ==========================================================
    // Layer structure: 49 → 25 → 13 → 7 → 4 → 2 → 1
    // Mỗi layer pipeline 1 stage
    // ==========================================================

    // ------- L1: 49 -> 25 -----------
    logic signed [37:0] L1 [0:24];
    always_comb begin
        integer k;
        for (k=0;k<24;k++)
            L1[k] = L0[2*k] + L0[2*k+1];
        L1[24] = L0[48];
    end

    logic signed [37:0] P1 [0:24];
    always_ff @(posedge clk or posedge rst)
        if (rst) P1 <= '{default:0};
        else if (en) P1 <= L1;

    // ------- L2: 25 -> 13 -----------
    logic signed [37:0] L2 [0:12];
    always_comb begin
        integer k;
        for (k=0;k<12;k++)
            L2[k] = P1[2*k] + P1[2*k+1];
        L2[12] = P1[24];
    end

    logic signed [37:0] P2 [0:12];
    always_ff @(posedge clk or posedge rst)
        if (rst) P2 <= '{default:0};
        else if (en) P2 <= L2;

    // ------- L3: 13 -> 7 -----------
    logic signed [37:0] L3 [0:6];
    always_comb begin
        integer k;
        for (k=0;k<6;k++)
            L3[k] = P2[2*k] + P2[2*k+1];
        L3[6] = P2[12];
    end

    logic signed [37:0] P3 [0:6];
    always_ff @(posedge clk or posedge rst)
        if (rst) P3 <= '{default:0};
        else if (en) P3 <= L3;

    // ------- L4: 7 -> 4 -----------
    logic signed [37:0] L4 [0:3];
    always_comb begin
        L4[0] = P3[0] + P3[1];
        L4[1] = P3[2] + P3[3];
        L4[2] = P3[4] + P3[5];
        L4[3] = P3[6];
    end

    logic signed [37:0] P4 [0:3];
    always_ff @(posedge clk or posedge rst)
        if (rst) P4 <= '{default:0};
        else if (en) P4 <= L4;

    // ------- L5: 4 -> 2 -----------
    logic signed [37:0] L5 [0:1];
    assign L5[0] = P4[0] + P4[1];
    assign L5[1] = P4[2] + P4[3];

    logic signed [37:0] P5 [0:1];
    always_ff @(posedge clk or posedge rst)
        if (rst) P5 <= '{default:0};
        else if (en) P5 <= L5;

    // ------- L6: 2 -> 1 -----------
    logic signed [37:0] final_sum;
    assign final_sum = P5[0] + P5[1];

    // ------- SATURATION ở OUTPUT -----------
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            sum_out <= 0;
        else if (en) begin
            if (final_sum > $signed(38'sh1FFFFFFFFF))
                sum_out <= 38'sh1FFFFFFFFF;
            else if (final_sum < $signed(-38'sh2000000000))
                sum_out <= -38'sh2000000000;
            else
                sum_out <= final_sum;
        end
    end

endmodule
