// adder_tree_49_fixed_pipelined.sv
`timescale 1ns/1ps
module adder_tree_49_fixed_pipelined (
    input  logic clk,
    input  logic rst,
    input  logic en,

    // 49 inputs × 32-bit each (Q16.16)
    input  logic signed [49*32-1:0] in_flat,
    // Full-width output (Q22.16)  : 38 bits
    output logic signed [37:0] sum_out
);

    // --- unpack 49 inputs (32-bit signed each) ---
    logic signed [31:0] L0 [0:48];
    genvar gi;
    generate
        for (gi = 0; gi < 49; gi = gi + 1) begin
            assign L0[gi] = in_flat[gi*32 +: 32];
        end
    endgenerate

    // -------------------------------------------------------------------
    // Layer widths: all internal sums use 38-bit signed (Q22.16)
    // Layers: 49 -> 25 -> 13 -> 7 -> 4 -> 2 -> 1
    // Each layer has combinational add then one clocked pipeline register
    // -------------------------------------------------------------------

    // Layer1: 49 -> 25 (combine pairs)  (combinational)
    logic signed [37:0] S1_comb [0:24];
    integer k;
    always_comb begin
        for (k = 0; k < 24; k = k + 1) begin
            // extend operands to 38 bits before add to avoid accidental truncation
            S1_comb[k] = $signed({{6{L0[2*k][31]}}, L0[2*k]}) + $signed({{6{L0[2*k+1][31]}}, L0[2*k+1]});
        end
        // leftover single element
        S1_comb[24] = $signed({{6{L0[48][31]}}, L0[48]});
    end

    // pipeline stage register 1
    logic signed [37:0] P1 [0:24];
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 25; k = k + 1) P1[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 25; k = k + 1) P1[k] <= S1_comb[k];
        end
    end

    // Layer2: 25 -> 13
    logic signed [37:0] S2_comb [0:12];
    always_comb begin
        for (k = 0; k < 12; k = k + 1) begin
            S2_comb[k] = P1[2*k] + P1[2*k+1];
        end
        S2_comb[12] = P1[24];
    end

    logic signed [37:0] P2 [0:12];
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 13; k = k + 1) P2[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 13; k = k + 1) P2[k] <= S2_comb[k];
        end
    end

    // Layer3: 13 -> 7
    logic signed [37:0] S3_comb [0:6];
    always_comb begin
        for (k = 0; k < 6; k = k + 1) S3_comb[k] = P2[2*k] + P2[2*k+1];
        S3_comb[6] = P2[12];
    end

    logic signed [37:0] P3 [0:6];
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 7; k = k + 1) P3[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 7; k = k + 1) P3[k] <= S3_comb[k];
        end
    end

    // Layer4: 7 -> 4
    logic signed [37:0] S4_comb [0:3];
    always_comb begin
        S4_comb[0] = P3[0] + P3[1];
        S4_comb[1] = P3[2] + P3[3];
        S4_comb[2] = P3[4] + P3[5];
        S4_comb[3] = P3[6];
    end

    logic signed [37:0] P4 [0:3];
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 4; k = k + 1) P4[k] <= 38'sd0;
        end else if (en) begin
            for (k = 0; k < 4; k = k + 1) P4[k] <= S4_comb[k];
        end
    end

    // Layer5: 4 -> 2
    logic signed [37:0] S5_comb [0:1];
    always_comb begin
        S5_comb[0] = P4[0] + P4[1];
        S5_comb[1] = P4[2] + P4[3];
    end

    logic signed [37:0] P5 [0:1];
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            P5[0] <= 38'sd0; P5[1] <= 38'sd0;
        end else if (en) begin
            P5[0] <= S5_comb[0];
            P5[1] <= S5_comb[1];
        end
    end

    // Layer6: 2 -> 1 (final)
    logic signed [37:0] final_comb;
    always_comb begin
        final_comb = P5[0] + P5[1];
    end

    // final pipeline register and optional saturation (keeps full 38-bit)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) sum_out <= 38'sd0;
        else if (en) begin
            // optional saturation: comment/uncomment if you want clamp
            // sum_out <= (final_comb > 38'sd( (1<<37)-1 )) ? 38'sd((1<<37)-1) :
            //            (final_comb < -38'sd(1<<37)) ? -38'sd(1<<37) : final_comb;
            sum_out <= final_comb; // keep full precision
        end
    end

endmodule
