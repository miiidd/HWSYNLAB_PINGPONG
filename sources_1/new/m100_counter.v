`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference book: "FPGA Prototyping by Verilog Examples"
//                      "Xilinx Spartan-3 Version"
// Written by: Dr. Pong P. Chu
// Published by: Wiley, 2008
//
// Adapted for Basys 3 by David J. Marion aka FPGA Dude
//
//////////////////////////////////////////////////////////////////////////////////

module m100_counter(
    input clk,
    input reset,
    input d_inc_A, d_inc_B, d_clr,
    output [3:0] dig0_A, dig1_A,
    output [3:0] dig0_B, dig1_B
    );
    
    // signal declaration
    reg [3:0] r_dig0_A, r_dig1_A, dig0_next_A, dig1_next_A;
    reg [3:0] r_dig0_B, r_dig1_B, dig0_next_B, dig1_next_B;
    
    // register control
    always @(posedge clk or posedge reset)
        if(reset) begin
            r_dig1_A <= 0;
            r_dig0_A <= 0;
            r_dig1_B <= 0;
            r_dig0_B <= 0;
        end
        
        else begin
            r_dig1_A <= dig1_next_A;
            r_dig0_A <= dig0_next_A;
            r_dig1_B <= dig1_next_B;
            r_dig0_B <= dig0_next_B;
        end
    
    // next state logic
    always @* begin
        dig0_next_A = r_dig0_A;
        dig1_next_A = r_dig1_A;
        dig0_next_B = r_dig0_B;
        dig1_next_B = r_dig1_B;
        
        if(d_clr) begin
            dig0_next_A <= 0;
            dig1_next_A <= 0;
            dig0_next_B <= 0;
            dig1_next_B <= 0;
        end
        
        else if(d_inc_A)
            if(r_dig0_A == 9) begin
                dig0_next_A = 0;
                
                if(r_dig1_A == 9)
                    dig1_next_A = 0;
                else
                    dig1_next_A = r_dig1_A + 1;
            end
        
            else    // dig0 != 9
                dig0_next_A = r_dig0_A + 1;
        
        else if(d_inc_B)
            if(r_dig0_B == 9) begin
                dig0_next_B = 0;
                
                if(r_dig1_B == 9)
                    dig1_next_B = 0;
                else
                    dig1_next_B = r_dig1_B + 1;
            end
        
            else    // dig0 != 9
                dig0_next_B = r_dig0_B + 1;
    end
    
    // output
    assign dig0_A = r_dig0_A;
    assign dig1_A = r_dig1_A;
    assign dig0_B = r_dig0_B;
    assign dig1_B = r_dig1_B;
    
endmodule
