module locator
# (
    parameter clk_mhz = 33
)
(
    input               clk,
    input               rst,
    input               start,

    // Sound input
    input signed [12:0] mic_1, mic_2, mic_3, mic_4,

    output logic [ 3:0] min_index_h,
    output logic [ 3:0] min_index_v
);

    //------------------------------------------------------------------------

    logic       [15:0] inv   = 16'b1111111000000000;
    logic [15:0][ 3:0] shift = {4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0,
                                4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8};
    logic [15:0][12:0] rms_out_h; // result of band (horizontal)
    logic [15:0][12:0] rms_out_v; // result of band (vertical)
    logic [15:0][12:0] level_h;   // buf result of band (horizontal)
    logic [15:0][12:0] level_v;   // buf result of band (vertical)
    wire               ws;

    //------------------------------------------------------------------------
    //  Acoustic locator
    //------------------------------------------------------------------------

    // Correlation for the shift (horizontal)
    correlator i_correlator_h [15:0]
    (
        .clk       ( clk         ),
        .rst       ( rst         ),
        .ws        ( ~ ws        ),
        .in_1      ( mic_1       ),
        .in_2      ( mic_2       ),
        .inv       ( inv         ),
        .shift     ( shift       ),
        .rms_out   ( rms_out_h   )
    );

    // Correlation for the shift (vertical)
    correlator i_correlator_v [15:0]
    (
        .clk       ( clk         ),
        .rst       ( rst         ),
        .ws        ( ~ ws        ),
        .in_1      ( mic_3       ),
        .in_2      ( mic_4       ),
        .inv       ( inv         ),
        .shift     ( shift       ),
        .rms_out   ( rms_out_v   )
    );

    // Find minimum (horizontal)
    find_min_index i_find_min_index_h
    (
        .clk       ( clk         ),
        .rst       ( rst         ),
        .start     ( start       ),
        .level     ( level_h     ),
        .min_index ( min_index_h )
    );

    // Find minimum (vertical)
    find_min_index i_find_min_index_v
    (
        .clk       ( clk         ),
        .rst       ( rst         ),
        .start     ( start       ),
        .level     ( level_v     ),
        .min_index ( min_index_v )
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            level_h <= '0;
            level_v <= '0;
        end
        else if (start) begin
            level_h <= rms_out_h;
            level_v <= rms_out_v;
        end
    end

    // To receive ws clock only
    inmp441_mic_i2s_receiver_alt
    # (
        .clk_mhz ( clk_mhz    )
    )
    i_microphone
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .right     ( 1'b0       ),
        .lr        (            ),
        .ws        ( ws         ),
        .sck       (            ),
        .sd        ( 1'b0       ),
        .value     (            )
    );

endmodule
