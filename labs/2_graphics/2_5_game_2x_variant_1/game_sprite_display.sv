`include "game_config.svh"

module game_sprite_display
#(
    parameter SPRITE_WIDTH  = 16,
              SPRITE_HEIGHT = 16,

              ROW_0         = 64'h000000cccc000000,
              ROW_1         = 64'h000000cccc000000,
              ROW_2         = 64'h000000cccc000000,
              ROW_3         = 64'h000000cccc000000,
              ROW_4         = 64'h000000cccc000000,
              ROW_5         = 64'h000000cccc000000,
              ROW_6         = 64'hcccccccccccccccc,
              ROW_7         = 64'hcccccccccccccccc,
              ROW_8         = 64'hcccccccccccccccc,
              ROW_9         = 64'hcccccccccccccccc,
              ROW_10        = 64'hcccccccccccccccc,
              ROW_11        = 64'h000000cccc000000,
              ROW_12        = 64'h000000cccc000000,
              ROW_13        = 64'h000000cccc000000,
              ROW_14        = 64'h000000cccc000000,
              ROW_15        = 64'h000000cccc000000,

              screen_width  = 640,
              screen_height = 480,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)

//----------------------------------------------------------------------------

(
    input                                clk,
    input                                rst,

    input        [w_x             - 1:0] pixel_x,
    input        [w_y             - 1:0] pixel_y,

    input        [w_x             - 1:0] sprite_x,
    input        [w_y             - 1:0] sprite_y,

    output logic                         sprite_within_screen,

    output logic [w_x             - 1:0] sprite_out_left,
    output logic [w_x             - 1:0] sprite_out_right,
    output logic [w_y             - 1:0] sprite_out_top,
    output logic [w_y             - 1:0] sprite_out_bottom,

    output logic                         rgb_en,
    output logic [`GAME_RGB_WIDTH - 1:0] rgb
);

    //------------------------------------------------------------------------

    localparam ERGB_WIDTH = 1 + `GAME_RGB_WIDTH;

    //------------------------------------------------------------------------

    wire [w_x:0] screen_w_1_minus_sprite
        = screen_width - 1 - { 1'b0, sprite_x };

    wire [w_x:0] x_sprite_plus_w_1
        = { 1'b0, sprite_x } + SPRITE_WIDTH - 1;

    wire x_sprite_within_screen
        = // sprite_x < `screen_width;

             screen_w_1_minus_sprite [w_x] == 1'b0
          && x_sprite_plus_w_1       [w_x] == 1'b0;

    //------------------------------------------------------------------------

    wire [w_x:0] x_pixel_minus_sprite
        = { 1'b0, pixel_x } - { 1'b0, sprite_x };

    wire [w_x:0] x_sprite_plus_w_1_minus_pixel
        = x_sprite_plus_w_1 - { 1'b0, pixel_x };

    wire x_hit =    x_pixel_minus_sprite          [w_x] == 1'b0
                 && x_sprite_plus_w_1_minus_pixel [w_x] == 1'b0;

    //------------------------------------------------------------------------

    wire [w_y:0] screen_h_1_minus_sprite
        = screen_height - 1 - { 1'b0, sprite_y };

    wire [w_y:0] y_sprite_plus_h_1
        = { 1'b0, sprite_y } + SPRITE_HEIGHT - 1;

    wire y_sprite_within_screen
        = // sprite_y < screen_height;

             screen_h_1_minus_sprite [w_y] == 1'b0
          && y_sprite_plus_h_1       [w_y] == 1'b0;

    //------------------------------------------------------------------------

    wire [w_y:0] y_pixel_minus_sprite
        = { 1'b0, pixel_y } - { 1'b0, sprite_y };

    wire [w_y:0] y_sprite_plus_h_1_minus_pixel
        = y_sprite_plus_h_1 - { 1'b0, pixel_y };

    wire y_hit =    y_pixel_minus_sprite          [w_y] == 1'b0
                 && y_sprite_plus_h_1_minus_pixel [w_y] == 1'b0;

    //------------------------------------------------------------------------

    // Here we assume that SPRITE_WIDTH == 8 and ERGB_WIDTH == 4
    // TODO: instantiate here a more generic mux that is handled by all
    // synthesis tools well

    wire [3:0] row_index    = y_pixel_minus_sprite [3:0];
    wire [3:0] column_index = x_pixel_minus_sprite [3:0];

    logic [screen_width * ERGB_WIDTH - 1:0] row;

    always_comb
        case (row_index)
        4'd0 : row = ROW_0;
        4'd1 : row = ROW_1;
        4'd2 : row = ROW_2;
        4'd3 : row = ROW_3;
        4'd4 : row = ROW_4;
        4'd5 : row = ROW_5;
        4'd6 : row = ROW_6;
        4'd7 : row = ROW_7;
        4'd8 : row = ROW_8;
        4'd9 : row = ROW_9;
        4'd10: row = ROW_10;
        4'd11: row = ROW_11;
        4'd12: row = ROW_12;
        4'd13: row = ROW_13;
        4'd14: row = ROW_14;
        4'd15: row = ROW_15;
        endcase

    logic [ERGB_WIDTH - 1:0] ergb;

    always_comb
        case (column_index)

        4'd0:  ergb = row [63:60];
        4'd1:  ergb = row [59:56];
        4'd2:  ergb = row [55:52];
        4'd3:  ergb = row [51:48];
        4'd4:  ergb = row [47:44];
        4'd5:  ergb = row [43:40];
        4'd6:  ergb = row [39:36];
        4'd7:  ergb = row [35:32];
        4'd8:  ergb = row [31:28];
        4'd9:  ergb = row [27:24];
        4'd10: ergb = row [23:20];
        4'd11: ergb = row [19:16];
        4'd12: ergb = row [15:12];
        4'd13: ergb = row [11: 8];
        4'd14: ergb = row [ 7: 4];
        4'd15: ergb = row [ 3: 0];

        endcase

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            rgb_en <= 1'b0;
        else if (x_hit && y_hit)
            { rgb_en, rgb } <= ergb;
        else
            rgb_en <= 1'b0;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            sprite_within_screen <= 1'b0;

            sprite_out_left      <= 1'b0;
            sprite_out_right     <= 1'b0;
            sprite_out_top       <= 1'b0;
            sprite_out_bottom    <= 1'b0;
        end
        else
        begin
            sprite_within_screen
                <= x_sprite_within_screen && y_sprite_within_screen;

            sprite_out_left      <= sprite_x;
            sprite_out_right     <= x_sprite_plus_w_1;
            sprite_out_top       <= sprite_y;
            sprite_out_bottom    <= y_sprite_plus_h_1;
        end

endmodule
