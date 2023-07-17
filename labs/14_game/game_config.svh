`ifndef GAME_CONFIG_SVH
`define GAME_CONFIG_SVH

`include "config.svh"

`define SCREEN_WIDTH   640
`define SCREEN_HEIGHT  480

`define X_WIDTH        10  // X coordinate width in bits
`define Y_WIDTH        10  // Y coordinate width in bits

`define RGB_WIDTH      3

`ifndef GAME_MASTER_FSM_MODULE

   `define GAME_MASTER_FSM_MODULE   game_master_fsm_1_regular_state_encoded
// `define GAME_MASTER_FSM_MODULE   game_master_fsm_2_special_style_one_hot
// `define GAME_MASTER_FSM_MODULE   game_master_fsm_3_special_style_signals_from_state

`endif

`define N_MIXER_PIPE_STAGES  1

// `define GAME_SPRITE_DISPLAY_MODULE  game_sprite_display_pipelined
   `define GAME_SPRITE_DISPLAY_MODULE  game_sprite_display

`endif
