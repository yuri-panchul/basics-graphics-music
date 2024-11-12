`ifndef GAME_CONFIG_SVH
`define GAME_CONFIG_SVH

`include "config.svh"

`define GAME_RGB_WIDTH       3

`ifndef GAME_MASTER_FSM_MODULE

   `define GAME_MASTER_FSM_MODULE   game_master_fsm_1_regular_state_encoded
// `define GAME_MASTER_FSM_MODULE   game_master_fsm_2_special_style_one_hot
// `define GAME_MASTER_FSM_MODULE   game_master_fsm_3_special_style_signals_from_state

`endif

`define N_MIXER_PIPE_STAGES  1

// `define GAME_SPRITE_DISPLAY_MODULE  game_sprite_display_pipelined
   `define GAME_SPRITE_DISPLAY_MODULE  game_sprite_display

`endif
