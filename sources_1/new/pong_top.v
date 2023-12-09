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

module pong_top(
    input clk,              // 100MHz
    input reset,            // btnR
    input [1:0] btnA,        // btnD, btnU
    input [1:0] btnB,
    output [6:0] seg,
    output [3:0] an,
    output hsync,           // to VGA Connector
    output vsync,           // to VGA Connector
    output [11:0] rgb       // to DAC, to VGA Connector
    );
    
    // state declarations for 4 states
    parameter newgame = 2'b00;
    parameter play    = 2'b01;
    parameter newball = 2'b10;
    parameter over    = 2'b11;
           
        
    // signal declaration
    reg [1:0] state_reg, state_next;
    wire [9:0] w_x, w_y;
    wire w_vid_on, w_p_tick, graph_on, hit_A, hit_B, miss;
    wire [3:0] text_on;
    wire [11:0] graph_rgb, text_rgb;
    reg [11:0] rgb_reg, rgb_next;
    wire [3:0] dig0_A, dig1_A;
    wire [3:0] dig0_B, dig1_B;
    reg gra_still, d_inc_A, d_inc_B, d_clr, timer_start;
    wire timer_tick, timer_up;
    reg [7:0] ball_reg, ball_next;
    wire [19:0] clk_div;
    
    assign clk_div[0] = clk;
    generate for (genvar i=0; i<19; i = i+1) begin
        clockDivider div1(clk_div[i], clk_div[i+1]);
    end endgenerate
    
    // Module Instantiations
    vga_controller vga_unit(
        .clk_100MHz(clk),
        .reset(reset),
        .video_on(w_vid_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(w_p_tick),
        .x(w_x),
        .y(w_y));
    
    pong_text text_unit(
        .clk(clk),
        .x(w_x),
        .y(w_y),
        .dig0_A(dig0_A),
        .dig1_A(dig1_A),
        .dig0_B(dig0_B),
        .dig1_B(dig1_B),
        .ball(ball_reg),
        .text_on(text_on),
        .text_rgb(text_rgb));
        
    pong_graph graph_unit(
        .clk(clk),
        .reset(reset),
        .btnA(btnA),
        .btnB(btnB),
        .gra_still(gra_still),
        .video_on(w_vid_on),
        .x(w_x),
        .y(w_y),
        .hit_A(hit_A),
        .hit_B(hit_B),
        .miss(miss),
        .graph_on(graph_on),
        .graph_rgb(graph_rgb)
        );


    
    // 60 Hz tick when screen is refreshed
    assign timer_tick = (w_x == 0) && (w_y == 0);
    timer timer_unit(
        .clk(clk),
        .reset(reset),
        .timer_tick(timer_tick),
        .timer_start(timer_start),
        .timer_up(timer_up));
    
    m100_counter counter_unit(
        .clk(clk),
        .reset(reset),
        .d_inc_A(d_inc_A),
        .d_inc_B(d_inc_B),
        .d_clr(d_clr),
        .dig0_A(dig0_A),
        .dig1_A(dig1_A),
        .dig0_B(dig0_B),
        .dig1_B(dig1_B)
        );
       
    
    // FSMD state and registers
    always @(posedge clk or posedge reset)
        if(reset) begin
            state_reg <= newgame;
            ball_reg <= 0;
            rgb_reg <= 0;
        end
    
        else begin
            state_reg <= state_next;
            ball_reg <= ball_next;
            if(w_p_tick)
                rgb_reg <= rgb_next;
        end
    
    // FSMD next state logic
    always @* begin
        gra_still = 1'b1;
        timer_start = 1'b0;
        d_inc_A = 1'b0;
        d_inc_B = 1'b0;
        d_clr = 1'b0;
        state_next = state_reg;
        ball_next = ball_reg;
        
        case(state_reg)
            newgame: begin
                ball_next = 8'b11111111;          // three balls
                d_clr = 1'b1;               // clear score
                
                if(btnA != 2'b00 || btnB != 2'b00) begin      // button pressed
                    state_next = play;
                    ball_next = ball_reg - 1;    
                end
            end
            
            play: begin
                gra_still = 1'b0;   // animated screen
                
                if(hit_A)
                    d_inc_A = 1'b1;   // increment score A
                
                if(hit_B)
                    d_inc_B = 1'b1;   // increment score B
                    
                else if(miss) 
                begin
                    if(ball_reg == 0)
                        state_next = over;
                    
                    else
                        state_next = newball;
                    
                    timer_start = 1'b1;     // 2 sec timer
                    ball_next = ball_reg - 1;
                end
            end
            
            newball: // wait for 2 sec and until button pressed
            if(timer_up && (btnA != 2'b00 || btnB != 2'b00))
                state_next = play;
                
            over:   // wait 2 sec to display game over
                if(timer_up)
                    state_next = newgame;
        endcase           
    end
    
    // rgb multiplexing
    always @*
        if(~w_vid_on)
            rgb_next = 12'h000; // blank
        
        else
            if(text_on[3] || ((state_reg == newgame) && text_on[1]) || ((state_reg == over) && text_on[0]))
                rgb_next = text_rgb;    // colors in pong_text
            
            else if(graph_on)
                rgb_next = graph_rgb;   // colors in graph_text
                
            else if(text_on[2])
                rgb_next = text_rgb;    // colors in pong_text
                
            else
                rgb_next = 12'h0FF;     // aqua background
    
    // output
    assign rgb = rgb_reg;

    sevenSegment segmentController(
        .clk(clk_div[19]),
        .num0(dig1_B),
        .num1(dig0_B),
        .num2(dig1_A),
        .num3(dig0_A),
        .seg_output(seg),
        .dot(dp),
        .an(an)
    );

endmodule
