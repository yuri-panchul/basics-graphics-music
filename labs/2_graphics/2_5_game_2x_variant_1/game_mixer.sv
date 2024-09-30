`include "game_config.svh"

module game_mixer
(
    input                                clk,
    input                                rst,

    input                                sprite_target_rgb_en,
    input        [`GAME_RGB_WIDTH - 1:0] sprite_target_rgb,

    input                                sprite_torpedo_rgb_en,
    input        [`GAME_RGB_WIDTH - 1:0] sprite_torpedo_rgb,

    input                                game_won,
    input                                end_of_game_timer_running,
    input                                random,

    output logic [`GAME_RGB_WIDTH - 1:0] rgb
);

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            rgb <= 3'b000;
        else if (end_of_game_timer_running)
            rgb <= { 1'b1, ~ game_won, random };
        else if (sprite_torpedo_rgb_en)
            rgb <= sprite_torpedo_rgb;
        else if (sprite_target_rgb_en)
            rgb <= sprite_target_rgb;
        else
            rgb <= 3'b000;

endmodule
