`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2023 05:36:41 PM
// Design Name: 
// Module Name: clockDivider
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


module clockDivider(
        input clkIn,
        output clkOut
    );

    reg clkOut;
    initial
    begin
        clkOut = 0;
    end

    always @(posedge clkIn) begin
        clkOut = ~clkOut;
    end

endmodule
