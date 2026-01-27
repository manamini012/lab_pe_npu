`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2025 04:51:42 PM
// Design Name: 
// Module Name: regN
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module regN #(
    parameter WIDTH = 16
)(
    input                  clk,
    input                  rst,   // reset đồng bộ, active-high
    input                  en,
    input      [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= {WIDTH{1'b0}};
        else if (en)
            q <= d;
    end
endmodule