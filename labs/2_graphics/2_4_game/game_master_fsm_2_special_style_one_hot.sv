`include "game_config.svh"

module game_master_fsm_2_special_style_one_hot
(
    input      clk,
    input      rst,

    input      launch_key,

    output logic sprite_target_write_xy,
    output logic sprite_torpedo_write_xy,

    output logic sprite_target_write_dxy,
    output logic sprite_torpedo_write_dxy,

    output logic sprite_target_enable_update,
    output logic sprite_torpedo_enable_update,

    input      sprite_target_within_screen,
    input      sprite_torpedo_within_screen,

    input      collision,

    output logic end_of_game_timer_start,
    output logic game_won,

    input      end_of_game_timer_running
);

    // Using one-hot

    localparam STATE_START  = 0,
               STATE_AIM    = 1,
               STATE_SHOOT  = 2,
               STATE_END    = 3;

    logic [3:0] state;
    logic [3:0] d_state;

    logic d_sprite_target_write_xy;
    logic d_sprite_torpedo_write_xy;

    logic d_sprite_target_write_dxy;
    logic d_sprite_torpedo_write_dxy;

    logic d_sprite_target_enable_update;
    logic d_sprite_torpedo_enable_update;

    logic d_end_of_game_timer_start;
    logic d_game_won;

    //------------------------------------------------------------------------

    wire end_of_game
        =   ~ sprite_target_within_screen
          | ~ sprite_torpedo_within_screen
          |   collision;

    //------------------------------------------------------------------------

    always_comb
    begin
        d_state = 4'b0;

        d_sprite_target_write_xy        = 1'b0;
        d_sprite_torpedo_write_xy       = 1'b0;

        d_sprite_target_write_dxy       = 1'b0;
        d_sprite_torpedo_write_dxy      = 1'b0;

        d_sprite_target_enable_update   = 1'b0;
        d_sprite_torpedo_enable_update  = 1'b0;

        d_end_of_game_timer_start       = 1'b0;
        d_game_won                      = game_won;

        //--------------------------------------------------------------------

        case (1'b1)  // synopsys parallel_case

        state [STATE_START]:
        begin
            d_sprite_target_write_xy        = 1'b1;
            d_sprite_torpedo_write_xy       = 1'b1;

            d_sprite_target_write_dxy       = 1'b1;

            d_game_won                      = 1'b0;

            d_state [STATE_AIM] = 1;
        end

        state [STATE_AIM]:
        begin
            d_sprite_target_enable_update   = 1'b1;

            if (end_of_game)
            begin
                d_end_of_game_timer_start   = 1'b1;

                d_state [STATE_END] = 1;
            end
            else if (launch_key)
            begin
                d_state [STATE_SHOOT] = 1;
            end
            else
            begin
                d_state [STATE_AIM] = 1;
            end
        end

        state [STATE_SHOOT]:
        begin
            d_sprite_torpedo_write_dxy      = 1'b1;

            d_sprite_target_enable_update   = 1'b1;
            d_sprite_torpedo_enable_update  = 1'b1;

            if (collision)
                d_game_won = 1'b1;

            if (end_of_game)
            begin
                d_end_of_game_timer_start   = 1'b1;

                d_state [STATE_END] = 1;
            end
            else
            begin
                d_state [STATE_SHOOT] = 1;
            end
        end

        state [STATE_END]:
        begin
            // TODO: Investigate why it needs collision detection here
            // and not in previous state

            if (collision)
                d_game_won = 1'b1;

            if (! end_of_game_timer_running)
                d_state [STATE_START] = 1;
            else
                d_state [STATE_END] = 1;
        end

        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            state                         <= (1 << STATE_START);

            sprite_target_write_xy        <= 1'b0;
            sprite_torpedo_write_xy       <= 1'b0;

            sprite_target_write_dxy       <= 1'b0;
            sprite_torpedo_write_dxy      <= 1'b0;

            sprite_target_enable_update   <= 1'b0;
            sprite_torpedo_enable_update  <= 1'b0;

            end_of_game_timer_start       <= 1'b0;
            game_won                      <= 1'b0;
        end
        else
        begin
            state                         <= d_state;

            sprite_target_write_xy        <= d_sprite_target_write_xy;
            sprite_torpedo_write_xy       <= d_sprite_torpedo_write_xy;

            sprite_target_write_dxy       <= d_sprite_target_write_dxy;
            sprite_torpedo_write_dxy      <= d_sprite_torpedo_write_dxy;

            sprite_target_enable_update   <= d_sprite_target_enable_update;
            sprite_torpedo_enable_update  <= d_sprite_torpedo_enable_update;

            end_of_game_timer_start       <= d_end_of_game_timer_start;
            game_won                      <= d_game_won;
        end

endmodule
