/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Author: Uri Shaked
 */
/*
 * Ping-pong game by Allen Baker (botbakery.net)
 * 
 * Controls:
 * Player 1: 1 = up, 2 = down
 * Player 2: 6 = up, 7 = down
 */

`default_nettype none

module tt_um_vga_example (input wire [7:0]  ui_in, // Dedicated inputs
			  output wire [7:0] uo_out, // Dedicated outputs
			  input wire [7:0]  uio_in, // IOs: Input path
			  output wire [7:0] uio_out, // IOs: Output path
			  output wire [7:0] uio_oe, // IOs: Enable path (active high: 0=input, 1=output)
			  input wire	    ena, // always 1 when the design is powered, so you can ignore it
			  input wire	    clk, // clock
			  input wire	    rst_n     // reset_n - low to reset
			  );

   // VGA signals
   wire					    hsync;
   wire					    vsync;
   reg [1:0]				    R;
   reg [1:0]				    G;
   reg [1:0]				    B;
   wire					    video_active;
   wire [9:0]				    pix_x;
   wire [9:0]				    pix_y;

   // Configuration

   // TinyVGA PMOD
   assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

   // Unused outputs assigned to 0.
   assign uio_out = 0;
   assign uio_oe  = 0;

   // Suppress unused signals warning
   wire					    _unused_ok = &{ena, ui_in[5:3], ui_in[0], uio_in};

   hvsync_generator vga_sync_gen (.clk(clk),
				  .reset(~rst_n),
				  .hsync(hsync),
				  .vsync(vsync),
				  .display_on(video_active),
				  .hpos(pix_x),
				  .vpos(pix_y)
				  );

   parameter				    lcd_width = 640;
   parameter				    lcd_height = 480;

   parameter				    player_width = 30;
   parameter				    player_height = 80;
   parameter				    player_init_offset = (lcd_height / 2) - (player_height / 2);
   
   parameter				    p1_left_bound = 0;
   parameter				    p1_right_bound = player_width;
   parameter				    p1_upper_bound = 0;
   parameter				    p1_lower_bound = player_height;

   parameter				    p2_left_bound = lcd_width - player_width;
   parameter				    p2_right_bound = lcd_width;
   parameter				    p2_upper_bound = 0;
   parameter				    p2_lower_bound = player_height;

   parameter				    ball_width = 20;
   parameter				    ball_height = 20;
   parameter				    ball_x_init = (lcd_width / 2) - (ball_width / 2);
   parameter				    ball_y_init = (lcd_height / 2) + (ball_height / 2);

   parameter				    player_speed = 15;
   parameter				    ball_speed = 7;

   logic [9:0]				    p1_offset;
   logic [9:0]				    p2_offset;
   logic [9:0]				    ball_x_offset;
   logic [9:0]				    ball_y_offset;
   logic				    ball_x_fwd;
   logic				    ball_y_fwd;

   // Slow clock
   logic slow_clk;
   logic [17:0] slow_clk_cnt;
   always_ff @(posedge clk or negedge rst_n)
     begin
	if (~rst_n)
	  begin
	     slow_clk <= 0;
	     slow_clk_cnt <= 0;
	  end
	else
	  begin
	     slow_clk_cnt <= slow_clk_cnt + 1;
	     if (!slow_clk_cnt)
	       slow_clk <= ~slow_clk;
	  end // else: !if(~rst_n)
     end // always_ff @ (posedge clk or negedge rst_n)

   function logic [9:0] get_player_offset(input up,
					  input down,
					  input [9:0] current_offset);
      if (down)
	begin
	   if (current_offset < (lcd_height - player_height))
	     get_player_offset = current_offset + player_speed;
	   else
	     get_player_offset = current_offset;
	end
      else if (up)
	begin
	   if (current_offset > player_speed)
	     get_player_offset = current_offset - player_speed;
	   else
	     get_player_offset = current_offset;
	end
      else
	get_player_offset = current_offset;
   endfunction // get_player_offset

   function logic [9:0] get_ball_x_offset(input [9:0] current_offset);
      if (ball_x_fwd)
	begin
	   if (current_offset < (lcd_width - ball_width))
	     get_ball_x_offset = current_offset + ball_speed;
	   else
	     get_ball_x_offset = current_offset;
	end
      else
	begin
	   if (current_offset > 0)
	     get_ball_x_offset = current_offset - ball_speed;
	   else
	     get_ball_x_offset = current_offset;
	end
   endfunction // get_ball_x_offset

   function logic [9:0] get_ball_y_offset(input [9:0] current_offset);
      if (ball_y_fwd)
	begin
	   if (current_offset < (lcd_height - ball_height))
	     get_ball_y_offset = current_offset + ball_speed;
	   else
	     get_ball_y_offset = current_offset;
	end
      else
	begin
	   if (current_offset > 0)
	     get_ball_y_offset = current_offset - ball_speed;
	   else
	     get_ball_y_offset = current_offset;
	end
   endfunction // get_ball_y_offset

   // Game objects
   logic at_p1;
   assign at_p1 = (pix_x > p1_left_bound) &&
		  (pix_x < p1_right_bound) &&
		  (pix_y > (p1_offset + p1_upper_bound)) &&
		  (pix_y < (p1_offset + p1_lower_bound));
   logic at_p2;
   assign at_p2 = (pix_x > p2_left_bound) &&
		  (pix_x < p2_right_bound) &&
		  (pix_y > (p2_offset + p2_upper_bound)) &&
		  (pix_y < (p2_offset + p2_lower_bound));
   logic at_ball;
   assign at_ball = (pix_x > ball_x_offset) &&
		    (pix_x < (ball_x_offset + ball_width)) &&
		    (pix_y > ball_y_offset) &&
		    (pix_y < (ball_y_offset + ball_width));
   always_ff @(posedge slow_clk or negedge rst_n)
     begin
        if (~rst_n)
	  begin
	     p1_offset <= player_init_offset;
	     p2_offset <= player_init_offset;
	     ball_x_offset <= ball_x_init;
	     ball_y_offset <= ball_y_init;
	     ball_x_fwd <= 1;
	     ball_y_fwd <= 1;
	  end
	else
	  begin

	     p1_offset <= get_player_offset(ui_in[1], ui_in[2], p1_offset);
	     p2_offset <= get_player_offset(ui_in[6], ui_in[7], p2_offset);
	     ball_x_offset <= get_ball_x_offset(ball_x_offset);
	     ball_y_offset <= get_ball_y_offset(ball_y_offset);

	     // Ball interaction
	     if ((ball_x_offset >= (lcd_width - ball_width)) || !ball_x_offset)
	       begin
		  // Score
		  p1_offset <= player_init_offset;
		  p2_offset <= player_init_offset;
		  ball_x_offset <= ball_x_init;
		  ball_y_offset <= ball_y_init;
		  ball_x_fwd <= 1;
		  ball_y_fwd <= 1;
	       end
	     if (ball_y_offset >= (lcd_height - ball_height))
	       begin
		  // Bounce ball off bottom
		  ball_y_fwd <= 0;
	       end
	     if ((ball_y_offset + 1) < ball_height)
	       begin
		  // Bounce ball off top
		  ball_y_fwd <= 1;
	       end
	     if (((ball_x_offset + ball_width + 1) >= p2_left_bound) &&
		 ((((ball_y_offset + ball_height) >= (p2_offset + p2_upper_bound)) && // Ball lower edge contact
		   ((ball_y_offset + ball_height) <= (p2_offset + p2_lower_bound))) ||
		  ((ball_y_offset >= (p2_offset + p2_upper_bound)) && // Ball upper edge contact
		   (ball_y_offset <= (p2_offset + p2_upper_bound)))))
	       begin
		  // Bounce ball off P2 paddle
		  ball_x_fwd <= 0;
 	       end
	     if (((ball_x_offset - 1) <= p1_right_bound) &&
		 ((((ball_y_offset + ball_height) >= (p1_offset + p1_upper_bound)) && // Ball lower edge contact
		   ((ball_y_offset + ball_height) <= (p1_offset + p1_lower_bound))) ||
		  ((ball_y_offset >= (p1_offset + p1_upper_bound)) && // Ball upper edge contact
		   (ball_y_offset <= (p1_offset + p1_upper_bound)))))
	       begin
		  // Bounce ball off P1 paddle
		  ball_x_fwd <= 1;
 	       end
	  end
     end
   
   always_ff @(posedge clk or negedge rst_n)
     begin
        if (~rst_n)
	  begin
	     R <= 0;
	     G <= 0;
	     B <= 0;
	  end
        else
	  begin
	     R <= 0;
	     G <= 0;
	     B <= 0;
	     if (video_active && (at_p1 || at_p2 || at_ball))
	       begin
		  R <= 2'b11;
		  G <= 2'b11;
		  B <= 2'b11;
	       end
	  end
     end

endmodule
