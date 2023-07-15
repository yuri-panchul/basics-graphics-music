`include "game_config.svh"

/*

6 bit state:

START -> AIM

1 sprite_target_write_xy
1 sprite_torpedo_write_xy
1 sprite_target_write_dxy
0 sprite_torpedo_write_dxy
0 sprite_target_enable_update
0 sprite_torpedo_enable_update
0 end_of_game_timer_start
0 game_won

AIM -> AIM, SHOOT, LOST

0 sprite_target_write_xy
0 sprite_torpedo_write_xy
0 sprite_target_write_dxy
0 sprite_torpedo_write_dxy
1 sprite_target_enable_update
0 sprite_torpedo_enable_update
0 end_of_game_timer_start
0 game_won

SHOOT -> SHOOT, WON, LOST

0 sprite_target_write_xy
0 sprite_torpedo_write_xy
0 sprite_target_write_dxy
1 sprite_torpedo_write_dxy
1 sprite_target_enable_update
1 sprite_torpedo_enable_update
0 end_of_game_timer_start
0 game_won

WON -> WON_END                         LOST -> LOST_END

0 sprite_target_write_xy               0 sprite_target_write_xy
0 sprite_torpedo_write_xy              0 sprite_torpedo_write_xy
0 sprite_target_write_dxy              0 sprite_target_write_dxy
0 sprite_torpedo_write_dxy             0 sprite_torpedo_write_dxy
0 sprite_target_enable_update          0 sprite_target_enable_update
0 sprite_torpedo_enable_update         0 sprite_torpedo_enable_update
1 end_of_game_timer_start              1 end_of_game_timer_start
1 game_won                             0 game_won

WON_END -> WON_END, START              LOST_END -> LOST_END, START

0 sprite_target_write_xy               0 sprite_target_write_xy
0 sprite_torpedo_write_xy              0 sprite_torpedo_write_xy
0 sprite_target_write_dxy              0 sprite_target_write_dxy
0 sprite_torpedo_write_dxy             0 sprite_torpedo_write_dxy
0 sprite_target_enable_update          0 sprite_target_enable_update
0 sprite_torpedo_enable_update         0 sprite_torpedo_enable_update
0 end_of_game_timer_start              0 end_of_game_timer_start
1 game_won                             0 game_won

*/

module game_master_fsm_3_special_style_signals_from_state
(
    input  clk,
    input  rst,

    input  launch_key,

    output sprite_target_write_xy,
    output sprite_torpedo_write_xy,

    output sprite_target_write_dxy,
    output sprite_torpedo_write_dxy,

    output sprite_target_enable_update,
    output sprite_torpedo_enable_update,

    input  sprite_target_within_screen,
    input  sprite_torpedo_within_screen,

    input  collision,

    output end_of_game_timer_start,
    output game_won,

    input  end_of_game_timer_running
);

    //------------------------------------------------------------------------

    localparam [5:0] STATE_START    = 6'b100000,
                     STATE_AIM      = 6'b001000,
                     STATE_SHOOT    = 6'b011100,
                     STATE_WON      = 6'b000011,
                     STATE_WON_END  = 6'b000001,
                     STATE_LOST     = 6'b000010,
                     STATE_LOST_END = 6'b000000;

    //------------------------------------------------------------------------

    logic [5:0] state;
    logic [5:0] n_state;

    //------------------------------------------------------------------------

    assign sprite_target_write_xy        = state [5];
    assign sprite_torpedo_write_xy       = state [5];
    assign sprite_target_write_dxy       = state [5];
    assign sprite_torpedo_write_dxy      = state [4];
    assign sprite_target_enable_update   = state [3];
    assign sprite_torpedo_enable_update  = state [2];
    assign end_of_game_timer_start       = state [1];
    assign game_won                      = state [0];

    //------------------------------------------------------------------------

    wire out_of_screen
        =   ~ sprite_target_within_screen
          | ~ sprite_torpedo_within_screen;

    //------------------------------------------------------------------------

    always_comb
    begin
        n_state = 6'bx;  // For debug and "don't care" directive for synthesis

        case (state)

        STATE_START    : n_state =                             STATE_AIM;

        STATE_AIM      : n_state = out_of_screen             ? STATE_LOST
                                 : collision                 ? STATE_WON
                                 : launch_key                ? STATE_SHOOT
                                 :                             STATE_AIM;

        STATE_SHOOT    : n_state = out_of_screen             ? STATE_LOST
                                 : collision                 ? STATE_WON
                                 :                             STATE_SHOOT;

        STATE_WON      : n_state =                             STATE_WON_END;

        STATE_WON_END  : n_state = end_of_game_timer_running ? STATE_WON_END
                                 :                             STATE_START;

        STATE_LOST     : n_state =                             STATE_LOST_END;

        STATE_LOST_END : n_state = end_of_game_timer_running ? STATE_LOST_END
                                 :                             STATE_START;
        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            state <= STATE_START;
        else
            state <= n_state;

endmodule
