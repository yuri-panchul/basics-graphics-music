`include "game_config.svh"

module game_sprite_display_pipelined
#(
    parameter SPRITE_WIDTH  = 8,
              SPRITE_HEIGHT = 8,

              screen_width  = 640,
              screen_height = 480,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height ),

              ROW_0         = 32'h000cc000,
              ROW_1         = 32'h000cc000,
              ROW_2         = 32'h000cc000,
              ROW_3         = 32'hcccccccc,
              ROW_4         = 32'hcccccccc,
              ROW_5         = 32'h000cc000,
              ROW_6         = 32'h000cc000,
              ROW_7         = 32'h000cc000
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

    wire [w_x     :0] x_sprite_plus_w_1
        = { 1'b0, sprite_x } + SPRITE_WIDTH - 1;

    wire x_sprite_within_screen
        = // sprite_x < screen_width;

             screen_w_1_minus_sprite [w_x] == 1'b0
          && x_sprite_plus_w_1       [w_x] == 1'b0;

    wire [w_x:0] x_pixel_minus_sprite
        = { 1'b0, pixel_x } - { 1'b0, sprite_x };

    //------------------------------------------------------------------------

    wire [w_y:0] screen_h_1_minus_sprite
        = screen_height - 1 - { 1'b0, sprite_y };

    wire [w_y:0] y_sprite_plus_h_1
        = { 1'b0, sprite_y } + SPRITE_HEIGHT - 1;

    wire y_sprite_within_screen
        = // sprite_y < screen_height;

             screen_h_1_minus_sprite [w_y] == 1'b0
          && y_sprite_plus_h_1       [w_y] == 1'b0;

    wire [w_y:0] y_pixel_minus_sprite
        = { 1'b0, pixel_y } - { 1'b0, sprite_y };

    //------------------------------------------------------------------------

    logic [w_x      - 1:0] reg_pixel_x;
    logic [w_y      - 1:0] reg_pixel_y;

    logic [w_x      - 1:0] reg_sprite_x;
    logic [w_y      - 1:0] reg_sprite_y;

    logic [w_x         :0] reg_x_sprite_plus_w_1;
    logic                  reg_x_sprite_within_screen;
    logic [w_x         :0] reg_x_pixel_minus_sprite;

    logic [w_y         :0] reg_y_sprite_plus_h_1;
    logic                  reg_y_sprite_within_screen;
    logic [w_y         :0] reg_y_pixel_minus_sprite;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            reg_pixel_x                 <= 1'b0;
            reg_pixel_y                 <= 1'b0;

            reg_sprite_x                <= 1'b0;
            reg_sprite_y                <= 1'b0;

            reg_x_sprite_plus_w_1       <= 1'b0;
            reg_x_sprite_within_screen  <= 1'b0;
            reg_x_pixel_minus_sprite    <= 1'b0;

            reg_y_sprite_plus_h_1       <= 1'b0;
            reg_y_sprite_within_screen  <= 1'b0;
            reg_y_pixel_minus_sprite    <= 1'b0;
        end
        else
        begin
            reg_pixel_x                 <= pixel_x;
            reg_pixel_y                 <= pixel_y;

            reg_sprite_x                <= sprite_x;
            reg_sprite_y                <= sprite_y;

            reg_x_sprite_plus_w_1       <= x_sprite_plus_w_1;
            reg_x_sprite_within_screen  <= x_sprite_within_screen;
            reg_x_pixel_minus_sprite    <= x_pixel_minus_sprite;

            reg_y_sprite_plus_h_1       <= y_sprite_plus_h_1;
            reg_y_sprite_within_screen  <= y_sprite_within_screen;
            reg_y_pixel_minus_sprite    <= y_pixel_minus_sprite;
        end

    //------------------------------------------------------------------------

    wire [w_x:0] x_sprite_plus_w_1_minus_pixel
        = reg_x_sprite_plus_w_1 - { 1'b0, reg_pixel_x };

    wire x_hit =    reg_x_pixel_minus_sprite      [w_x] == 1'b0
                 && x_sprite_plus_w_1_minus_pixel [w_x] == 1'b0;

    //------------------------------------------------------------------------

    wire [w_y:0] y_sprite_plus_h_1_minus_pixel
        = reg_y_sprite_plus_h_1 - { 1'b0, reg_pixel_y };

    wire y_hit =    reg_y_pixel_minus_sprite      [w_y] == 1'b0
                 && y_sprite_plus_h_1_minus_pixel [w_y] == 1'b0;

    //------------------------------------------------------------------------

    // Here we assume that SPRITE_WIDTH == 8 and ERGB_WIDTH == 4
    // TODO: instantiate here a more generic mux that is handled by all synthesis tools well

    wire [2:0] row_index    = reg_y_pixel_minus_sprite [2:0];
    wire [2:0] column_index = reg_x_pixel_minus_sprite [2:0];

    logic [SPRITE_WIDTH * ERGB_WIDTH - 1:0] row;

    always_comb
        case (row_index)
        3'd0: row = ROW_0;
        3'd1: row = ROW_1;
        3'd2: row = ROW_2;
        3'd3: row = ROW_3;
        3'd4: row = ROW_4;
        3'd5: row = ROW_5;
        3'd6: row = ROW_6;
        3'd7: row = ROW_7;
        endcase

    logic [ERGB_WIDTH - 1:0] ergb;

    always_comb
        case (column_index)
        3'd0: ergb = row [31:28];
        3'd1: ergb = row [27:24];
        3'd2: ergb = row [23:20];
        3'd3: ergb = row [19:16];
        3'd4: ergb = row [15:12];
        3'd5: ergb = row [11: 8];
        3'd6: ergb = row [ 7: 4];
        3'd7: ergb = row [ 3: 0];
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
                <= reg_x_sprite_within_screen && reg_y_sprite_within_screen;

            sprite_out_left      <= reg_sprite_x;
            sprite_out_right     <= reg_x_sprite_plus_w_1;
            sprite_out_top       <= reg_sprite_y;
            sprite_out_bottom    <= reg_y_sprite_plus_h_1;
        end

endmodule
