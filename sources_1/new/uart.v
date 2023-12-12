`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2023 09:55:00 PM
// Design Name: 
// Module Name: uart
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


module uart(
    input clk,
    input RsRx,
    output [1:0] btnA,
    output [1:0] btnB
    );
//    reg [3:0] keyboard = 4'b0000;
    reg [1:0] btnA_out;
    reg [1:0] btnB_out;
    reg en, last_rec;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire sent, received, baud;
    
    assign btnA = btnA_out;
    assign btnB = btnB_out;
//    assign {btnB,btnA} = keyboard;

    baudrate_gen br(clk, baud);
    uart_rx receiver(baud, RsRx, received, data_out);
//    uart_tx transmitter(baud, data_in, en, sent, RsTx);
    
    /////
    always @(posedge baud) begin
        if (en) en = 0;
        if (~last_rec & received) begin
            data_in = data_out;
            if (data_in == 8'h77 || data_in == 8'h73 || data_in == 8'h39 || data_in == 8'h36) en = 1; 
            case (data_in)
                8'h77: btnB_out = 2'b01;// w: Player B up
                8'h73: btnB_out = 2'b10;// s: Player B down
                8'h39: btnA_out = 2'b01;// 9: Player A up
                8'h36: btnA_out = 2'b10;// 6: Player A down
            endcase
        end
        last_rec = received;
    end

//    always @(posedge sent) 
//        begin
//        if (sent) begin
//            case (data_in)
//                8'h77: btnB_out = 2'b10;// w: Player B up
//                8'h73: btnB_out = 2'b01;// s: Player B down
//                8'h39: btnA_out = 2'b10;// 9: Player A up
//                8'h36: btnA_out = 2'b01;// 6: Player A down
//            endcase
//        end
//    end

endmodule
