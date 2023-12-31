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

module pong_graph
    (
    input clk,  
    input reset,    
    input [1:0] btnA,        // btn[0] = up, btn[1] = down
    input [1:0] btnB,
    input gra_still,        // still graphics - newgame, game over states
    input video_on,
    input [9:0] x,
    input [9:0] y,
    output graph_on,
    output reg hit_A, miss,   // ball hit or miss
    output reg hit_B,
    output reg [11:0] graph_rgb
    );
    
    // maximum x, y values in display area
    parameter X_MAX = 639;
    parameter Y_MAX = 479;
    
    // create 60Hz refresh tick
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0; // start of vsync(vertical retrace)
    
    
    // WALLS
    // LEFT wall boundaries
    // parameter L_WALL_L = 32;    
    // parameter L_WALL_R = 39;    // 8 pixels wide
    // TOP wall boundaries
    parameter T_WALL_T = 64;    
    parameter T_WALL_B = 71;    // 8 pixels wide
    // BOTTOM wall boundaries
    parameter B_WALL_T = 472;    
    parameter B_WALL_B = 479;    // 8 pixels wide
    
    
    
    // paddle moving velocity when a button is pressed
    parameter PAD_VELOCITY = 3;     // change to speed up or slow down paddle movement
    parameter PAD_HEIGHT = 72;  // 72 pixels high

    //////////////////////////////////////////////////// PADDLE Player A
    // paddle horizontal boundaries
    parameter X_PAD_L_A = 600;
    parameter X_PAD_R_A = 603;    // 4 pixels wide
    // paddle vertical boundary signals
    wire [9:0] y_pad_t_A, y_pad_b_A;
    // register to track top boundary and buffer
    reg [9:0] y_pad_reg_A = 204;      // Paddle starting position
    reg [9:0] y_pad_next_A;

    /////////////////////////////////////////////////// PADDLE Player B
    // paddle horizontal boundaries
    parameter X_PAD_L_B = 50;
    parameter X_PAD_R_B = 53;    // 4 pixels wide
    // paddle vertical boundary signals
    wire [9:0] y_pad_t_B, y_pad_b_B;
    // register to track top boundary and buffer
    reg [9:0] y_pad_reg_B = 204;      // Paddle starting position
    reg [9:0] y_pad_next_B;
    // paddle moving velocity when a button is pressed
    
    
    // BALL
    // square rom boundaries
    parameter BALL_SIZE = 8;
    // ball horizontal boundary signals
    wire [9:0] x_ball_l, x_ball_r;
    // ball vertical boundary signals
    wire [9:0] y_ball_t, y_ball_b;
    // register to track top left position
    reg [9:0] y_ball_reg, x_ball_reg;
    // signals for register buffer
    wire [9:0] y_ball_next, x_ball_next;
    // registers to track ball speed and buffers
    reg [9:0] x_delta_reg, x_delta_next;
    reg [9:0] y_delta_reg, y_delta_next;
    // positive or negative ball velocity
    parameter BALL_VELOCITY_POS = 2;    // ball speed positive pixel direction(down, right)
    parameter BALL_VELOCITY_NEG = -2;   // ball speed negative pixel direction(up, left)
    // round ball from square image
    wire [2:0] rom_addr, rom_col;   // 3-bit rom address and rom column
    reg [7:0] rom_data;             // data at current rom address
    wire rom_bit;                   // signify when rom data is 1 or 0 for ball rgb control
    
    
    // Register Control
    always @(posedge clk or posedge reset)
        if(reset) begin
            y_pad_reg_A <= 204;
            y_pad_reg_B <= 204;
            x_ball_reg <= 0;
            y_ball_reg <= 0;
            x_delta_reg <= 10'h002;
            y_delta_reg <= 10'h002;
        end
        else begin
            y_pad_reg_A <= y_pad_next_A;
            y_pad_reg_B <= y_pad_next_B;
            x_ball_reg <= x_ball_next;
            y_ball_reg <= y_ball_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end
    
    
    // ball rom
    always @*
        case(rom_addr)
            3'b000 :    rom_data = 8'b00111100; //   ****  
            3'b001 :    rom_data = 8'b01111110; //  ******
            3'b010 :    rom_data = 8'b11111111; // ********
            3'b011 :    rom_data = 8'b11111111; // ********
            3'b100 :    rom_data = 8'b11111111; // ********
            3'b101 :    rom_data = 8'b11111111; // ********
            3'b110 :    rom_data = 8'b01111110; //  ******
            3'b111 :    rom_data = 8'b00111100; //   ****
        endcase
    
    
    // OBJECT STATUS SIGNALS
    wire l_wall_on, t_wall_on, b_wall_on, pad_on, sq_ball_on, ball_on;
    wire [11:0] wall_rgb, pad_rgb, ball_rgb, bg_rgb;
    
    
    // pixel within wall boundaries
//    assign l_wall_on = ((L_WALL_L <= x) && (x <= L_WALL_R)) ? 1 : 0;
    assign t_wall_on = ((T_WALL_T <= y) && (y <= T_WALL_B)) ? 1 : 0;
    assign b_wall_on = ((B_WALL_T <= y) && (y <= B_WALL_B)) ? 1 : 0;
    
    
    // assign object colors
    assign wall_rgb   = 12'h000;    // blue walls
    assign pad_rgb    = 12'h006;    // blue paddle
    assign ball_rgb   = 12'hF00;    // red ball
    assign bg_rgb     = 12'hC9F;    // aqua background
    
    
    // paddle 
    assign y_pad_t_A = y_pad_reg_A;                             // paddle top position A
    assign y_pad_t_B = y_pad_reg_B;                         //  B
    assign y_pad_b_A = y_pad_t_A + PAD_HEIGHT - 1;              // paddle bottom position A
    assign y_pad_b_B = y_pad_t_B + PAD_HEIGHT - 1;              //  B
    
    assign pad_on = (X_PAD_L_A <= x) && (x <= X_PAD_R_A) &&     // pixel within paddle boundaries
                    (y_pad_t_A <= y) && (y <= y_pad_b_A);
    assign pad_on_B = (X_PAD_L_B <= x) && (x <= X_PAD_R_B) &&     // pixel within paddle boundaries
                    (y_pad_t_B <= y) && (y <= y_pad_b_B);
    
                    
    // Paddle Control
    always @* begin
        y_pad_next_A = y_pad_reg_A;     // no move
        
        if(refresh_tick)
            if(btnA[1] & (y_pad_b_A < (B_WALL_T - 1 - PAD_VELOCITY)))
                y_pad_next_A = y_pad_reg_A + PAD_VELOCITY;  // move down
            else if(btnA[0] & (y_pad_t_A > (T_WALL_B - 1 - PAD_VELOCITY)))
                y_pad_next_A = y_pad_reg_A - PAD_VELOCITY;  // move up
    end

    always @* begin
        y_pad_next_B = y_pad_reg_B;     // no move
        
        if(refresh_tick)
            if(btnB[1] & (y_pad_b_B < (B_WALL_T - 1 - PAD_VELOCITY)))
                y_pad_next_B = y_pad_reg_B + PAD_VELOCITY;  // move down
            else if(btnB[0] & (y_pad_t_B > (T_WALL_B - 1 - PAD_VELOCITY)))
                y_pad_next_B = y_pad_reg_B - PAD_VELOCITY;  // move up
    end
    
    
    // rom data square boundaries
    assign x_ball_l = x_ball_reg;
    assign y_ball_t = y_ball_reg;
    assign x_ball_r = x_ball_l + BALL_SIZE - 1;
    assign y_ball_b = y_ball_t + BALL_SIZE - 1;
    // pixel within rom square boundaries
    assign sq_ball_on = (x_ball_l <= x) && (x <= x_ball_r) &&
                        (y_ball_t <= y) && (y <= y_ball_b);
    // map current pixel location to rom addr/col
    assign rom_addr = y[2:0] - y_ball_t[2:0];   // 3-bit address
    assign rom_col = x[2:0] - x_ball_l[2:0];    // 3-bit column index
    assign rom_bit = rom_data[rom_col];         // 1-bit signal rom data by column
    // pixel within round ball
    assign ball_on = sq_ball_on & rom_bit;      // within square boundaries AND rom data bit == 1
 
  
    // new ball position
    assign x_ball_next = (gra_still) ? X_MAX / 2 :
                         (refresh_tick) ? x_ball_reg + x_delta_reg : x_ball_reg;
    assign y_ball_next = (gra_still) ? Y_MAX / 2 :
                         (refresh_tick) ? y_ball_reg + y_delta_reg : y_ball_reg;
    
    // change ball direction after collision
    always @* begin
        hit_A = 1'b0;
        miss = 1'b0;
        hit_B = 1'b0;
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
        
        if(gra_still) begin
            x_delta_next = BALL_VELOCITY_NEG;
            y_delta_next = BALL_VELOCITY_POS;
        end
        
        else if(y_ball_t < T_WALL_B)                   // reach top
            y_delta_next = BALL_VELOCITY_POS;   // move down
        
        else if(y_ball_b > (B_WALL_T))         // reach bottom wall
            y_delta_next = BALL_VELOCITY_NEG;   // move up
        
        //else if(x_ball_l <= L_WALL_R)           // reach left wall
        //    x_delta_next = BALL_VELOCITY_POS;   // move right
        //


        else if((X_PAD_L_A <= x_ball_r) && (x_ball_r <= X_PAD_R_A) &&
                (y_pad_t_A <= y_ball_b) && (y_ball_t <= y_pad_b_A)) begin
                    x_delta_next = BALL_VELOCITY_NEG;
                    hit_A = 1'b1;
        
        end
        
        else if((X_PAD_L_B <= x_ball_l) && (x_ball_l <= X_PAD_R_B) &&
                (y_pad_t_B <= y_ball_b) && (y_ball_t <= y_pad_b_B)) begin
                    x_delta_next = BALL_VELOCITY_POS;
                    hit_B = 1'b1;
        end
        
        else if(x_ball_r > X_MAX | x_ball_l < 0)
            miss = 1'b1;
        
    end                    
    
    // output status signal for graphics 
    assign graph_on = l_wall_on | t_wall_on | b_wall_on | pad_on | pad_on_B | ball_on;
    
    
    // rgb multiplexing circuit
    always @*
        if(~video_on)
            graph_rgb = 12'h000;      // no value, blank
        else
            if(t_wall_on | b_wall_on)
                graph_rgb = wall_rgb;     // wall color
            else if(pad_on | pad_on_B)
                graph_rgb = pad_rgb;      // paddle color
            else if(ball_on)
                graph_rgb = ball_rgb;     // ball color
            else
                graph_rgb = bg_rgb;       // background
       
endmodule
