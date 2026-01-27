`timescale 1ns/1ps
module adder_tree_49_fixed_pipelined (
    input  clk,
    input  rst,
    input  en,

    input  signed [49*32-1:0] in_flat,  // 49 × 32-bit Q16.16
    output reg signed [37:0] sum_out    // Q22.16
);

    // -----------------------------
    // Unpack 49 signed 32-bit inputs
    // -----------------------------
    wire signed [31:0] L0 [0:48];

    genvar gi;
    generate
        for (gi = 0; gi < 49; gi = gi + 1) begin : UNPACK
            assign L0[gi] = in_flat[gi*32 +: 32];
        end
    endgenerate

    integer k;

    // ==========================================================
    // Layer 1: 49 -> 25
    // ==========================================================
    reg  signed [37:0] S1_comb [0:24];
    reg  signed [37:0] P1      [0:24];

    // Combine
    always @* begin
        for (k = 0; k < 24; k = k + 1) begin
            S1_comb[k] = {{6{L0[2*k][31]}}, L0[2*k]} +
                         {{6{L0[2*k+1][31]}}, L0[2*k+1]};
        end
        S1_comb[24] = {{6{L0[48][31]}}, L0[48]};
    end

    // Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 25; k = k + 1)
                P1[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 25; k = k + 1)
                P1[k] <= S1_comb[k];
        end
    end

    // ==========================================================
    // Layer 2: 25 -> 13
    // ==========================================================
    reg  signed [37:0] S2_comb [0:12];
    reg  signed [37:0] P2      [0:12];

    always @* begin
        for (k = 0; k < 12; k = k + 1)
            S2_comb[k] = P1[2*k] + P1[2*k+1];
        S2_comb[12] = P1[24];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 13; k = k + 1)
                P2[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 13; k = k + 1)
                P2[k] <= S2_comb[k];
        end
    end

    // ==========================================================
    // Layer 3: 13 -> 7
    // ==========================================================
    reg  signed [37:0] S3_comb [0:6];
    reg  signed [37:0] P3      [0:6];

    always @* begin
        for (k = 0; k < 6; k = k + 1)
            S3_comb[k] = P2[2*k] + P2[2*k+1];
        S3_comb[6] = P2[12];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 7; k = k + 1)
                P3[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 7; k = k + 1)
                P3[k] <= S3_comb[k];
        end
    end

    // ==========================================================
    // Layer 4: 7 -> 4
    // ==========================================================
    reg  signed [37:0] S4_comb [0:3];
    reg  signed [37:0] P4      [0:3];

    always @* begin
        S4_comb[0] = P3[0] + P3[1];
        S4_comb[1] = P3[2] + P3[3];
        S4_comb[2] = P3[4] + P3[5];
        S4_comb[3] = P3[6];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 4; k = k + 1)
                P4[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 4; k = k + 1)
                P4[k] <= S4_comb[k];
        end
    end

    // ==========================================================
    // Layer 5: 4 -> 2
    // ==========================================================
    reg  signed [37:0] S5_comb [0:1];
    reg  signed [37:0] P5      [0:1];

    always @* begin
        S5_comb[0] = P4[0] + P4[1];
        S5_comb[1] = P4[2] + P4[3];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            P5[0] <= 38'sd0;
            P5[1] <= 38'sd0;
        end else if (en) begin
            P5[0] <= S5_comb[0];
            P5[1] <= S5_comb[1];
        end
    end

    // ==========================================================
    // Layer 6: 2 -> 1  (final)
    // ==========================================================
    wire signed [37:0] final_comb;
    assign final_comb = P5[0] + P5[1];

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst)
            sum_out <= 38'sd0;
        else if (en)
            sum_out <= final_comb;
    end

endmodule
