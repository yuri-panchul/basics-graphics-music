`include "game_config.svh"

module game_sprite_top
#(
    parameter SPRITE_WIDTH  = 8,
              SPRITE_HEIGHT = 8,

              DX_WIDTH      = 2,  // X speed width in bits
              DY_WIDTH      = 2,  // Y speed width in bits

              ROW_0         = 32'h000cc000,
              ROW_1         = 32'h000cc000,
              ROW_2         = 32'h000cc000,
              ROW_3         = 32'hcccccccc,
              ROW_4         = 32'hcccccccc,
              ROW_5         = 32'h000cc000,
              ROW_6         = 32'h000cc000,
              ROW_7         = 32'h000cc000,

              screen_width  = 640,
              screen_height = 480,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height ),

              strobe_to_update_xy_counter_width = 20
)

//----------------------------------------------------------------------------

(
    input                          clk,
    input                          rst,

    input  [w_x             - 1:0] pixel_x,
    input  [w_y             - 1:0] pixel_y,

    input                          sprite_write_xy,
    input                          sprite_write_dxy,

    input  [w_x             - 1:0] sprite_write_x,
    input  [w_y             - 1:0] sprite_write_y,

    input  [DX_WIDTH        - 1:0] sprite_write_dx,
    input  [DY_WIDTH        - 1:0] sprite_write_dy,

    input                          sprite_enable_update,

    output [w_x             - 1:0] sprite_x,
    output [w_y             - 1:0] sprite_y,

    output                         sprite_within_screen,

    output [w_x             - 1:0] sprite_out_left,
    output [w_x             - 1:0] sprite_out_right,
    output [w_y             - 1:0] sprite_out_top,
    output [w_y             - 1:0] sprite_out_bottom,

    output                         rgb_en,
    output [`GAME_RGB_WIDTH - 1:0] rgb
);

    game_sprite_control
    #(
        .DX_WIDTH              ( DX_WIDTH              ),
        .DY_WIDTH              ( DY_WIDTH              ),

        .screen_width
        (screen_width),

        .screen_height
        (screen_height),

        .strobe_to_update_xy_counter_width
        (strobe_to_update_xy_counter_width)
    )
    sprite_control
    (
        .clk                   ( clk                   ),
        .rst                   ( rst                   ),

        .sprite_write_xy       ( sprite_write_xy       ),
        .sprite_write_dxy      ( sprite_write_dxy      ),

        .sprite_write_x        ( sprite_write_x        ),
        .sprite_write_y        ( sprite_write_y        ),

        .sprite_write_dx       ( sprite_write_dx       ),
        .sprite_write_dy       ( sprite_write_dy       ),

        .sprite_enable_update  ( sprite_enable_update  ),

        .sprite_x              ( sprite_x              ),
        .sprite_y              ( sprite_y              )
    );

    `GAME_SPRITE_DISPLAY_MODULE
    #(
        .SPRITE_WIDTH          ( SPRITE_WIDTH          ),
        .SPRITE_HEIGHT         ( SPRITE_HEIGHT         ),

        .ROW_0                 ( ROW_0                 ),
        .ROW_1                 ( ROW_1                 ),
        .ROW_2                 ( ROW_2                 ),
        .ROW_3                 ( ROW_3                 ),
        .ROW_4                 ( ROW_4                 ),
        .ROW_5                 ( ROW_5                 ),
        .ROW_6                 ( ROW_6                 ),
        .ROW_7                 ( ROW_7                 ),

        .screen_width
        (screen_width),

        .screen_height
        (screen_height)
    )
    sprite_display
    (
        .clk                   ( clk                   ),
        .rst                   ( rst                   ),

        .pixel_x               ( pixel_x               ),
        .pixel_y               ( pixel_y               ),

        .sprite_x              ( sprite_x              ),
        .sprite_y              ( sprite_y              ),

        .sprite_within_screen  ( sprite_within_screen  ),

        .sprite_out_left       ( sprite_out_left       ),
        .sprite_out_right      ( sprite_out_right      ),
        .sprite_out_top        ( sprite_out_top        ),
        .sprite_out_bottom     ( sprite_out_bottom     ),

        .rgb_en                ( rgb_en                ),
        .rgb                   ( rgb                   )
    );

endmodule
