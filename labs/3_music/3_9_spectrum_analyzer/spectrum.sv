module spectrum
# (
    parameter  clk_mhz             = 50,
               screen_width        = 640,
               screen_height       = 480,
               w_red               = 4,
               w_green             = 4,
               w_blue              = 4,
               w_x                 = $clog2 ( screen_width  ),
               w_y                 = $clog2 ( screen_height ),
        logic  [0:11] [13:0] freq  = '{132, 152, 174, 200, 230, 264,
                                       303, 348, 400, 458, 525, 600}
)
(
    input                        clk,
    input                        rst,

    // Graphics
    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,
    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Sound input
    input        [          8:0] mic
);

    //------------------------------------------------------------------------

    logic [11:0] [16:0] band_count;
    logic [11:0] [10:0] rms_out;
    logic               white;
    assign red   = {w_red   {white}};
    assign green = {w_green {white}};
    assign blue  = {w_blue  {white}};

    //------------------------------------------------------------------------
    //
    //  Spectrum analyzer
    //
    //------------------------------------------------------------------------

    // Calculation of control pulses from system clock and band
    function automatic logic [16:0] b (input [13:0] f );
    b = (clk_mhz * 31250) / f;
    endfunction

    initial begin
        for (int i = 0; i < 12; i = i + 1) begin
            band_count[i] = b(freq[i]);
        end
    end

    // Drawing a spectrogram
generate

    if (screen_width == 800) begin : screen_w_800
    always_ff @ (posedge clk or posedge rst) begin
        if (rst)
            white <= '0;
        else
        case (x [w_x - 1:5])
             1: white <= y > screen_height - rms_out[ 0] || screen_height < rms_out[ 0];
             3: white <= y > screen_height - rms_out[ 1] || screen_height < rms_out[ 1];
             5: white <= y > screen_height - rms_out[ 2] || screen_height < rms_out[ 2];
             7: white <= y > screen_height - rms_out[ 3] || screen_height < rms_out[ 3];
             9: white <= y > screen_height - rms_out[ 4] || screen_height < rms_out[ 4];
            11: white <= y > screen_height - rms_out[ 5] || screen_height < rms_out[ 5];
            13: white <= y > screen_height - rms_out[ 6] || screen_height < rms_out[ 6];
            15: white <= y > screen_height - rms_out[ 7] || screen_height < rms_out[ 7];
            17: white <= y > screen_height - rms_out[ 8] || screen_height < rms_out[ 8];
            19: white <= y > screen_height - rms_out[ 9] || screen_height < rms_out[ 9];
            21: white <= y > screen_height - rms_out[10] || screen_height < rms_out[10];
            23: white <= y > screen_height - rms_out[11] || screen_height < rms_out[11];
       default: white <= '0;
        endcase
    end
    end

    else if (screen_width == 640) begin : screen_w_640
    always_ff @ (posedge clk or posedge rst) begin
        if (rst)
            white <= '0;
        else
        case (x [w_x - 1:4])
         2,  3: white <= y > screen_height - rms_out[ 0] || screen_height < rms_out[ 0];
         5,  6: white <= y > screen_height - rms_out[ 1] || screen_height < rms_out[ 1];
         8,  9: white <= y > screen_height - rms_out[ 2] || screen_height < rms_out[ 2];
        11, 12: white <= y > screen_height - rms_out[ 3] || screen_height < rms_out[ 3];
        14, 15: white <= y > screen_height - rms_out[ 4] || screen_height < rms_out[ 4];
        17, 18: white <= y > screen_height - rms_out[ 5] || screen_height < rms_out[ 5];
        20, 21: white <= y > screen_height - rms_out[ 6] || screen_height < rms_out[ 6];
        23, 24: white <= y > screen_height - rms_out[ 7] || screen_height < rms_out[ 7];
        26, 27: white <= y > screen_height - rms_out[ 8] || screen_height < rms_out[ 8];
        29, 30: white <= y > screen_height - rms_out[ 9] || screen_height < rms_out[ 9];
        32, 33: white <= y > screen_height - rms_out[10] || screen_height < rms_out[10];
        35, 36: white <= y > screen_height - rms_out[11] || screen_height < rms_out[11];
       default: white <= '0;
        endcase
    end
    end

    else begin : screen_w_480
    always_ff @ (posedge clk or posedge rst) begin
        if (rst)
            white <= '0;
        else
        case (x [w_x - 1:3])
 1,  2,  3,  4: white <= y > screen_height - rms_out[ 0] || screen_height < rms_out[ 0];
 6,  7,  8,  9: white <= y > screen_height - rms_out[ 1] || screen_height < rms_out[ 1];
11, 12, 13, 14: white <= y > screen_height - rms_out[ 2] || screen_height < rms_out[ 2];
16, 17, 18, 19: white <= y > screen_height - rms_out[ 3] || screen_height < rms_out[ 3];
21, 22, 23, 24: white <= y > screen_height - rms_out[ 4] || screen_height < rms_out[ 4];
26, 27, 28, 29: white <= y > screen_height - rms_out[ 5] || screen_height < rms_out[ 5];
31, 32, 33, 34: white <= y > screen_height - rms_out[ 6] || screen_height < rms_out[ 6];
36, 37, 38, 39: white <= y > screen_height - rms_out[ 7] || screen_height < rms_out[ 7];
41, 42, 43, 44: white <= y > screen_height - rms_out[ 8] || screen_height < rms_out[ 8];
46, 47, 48, 49: white <= y > screen_height - rms_out[ 9] || screen_height < rms_out[ 9];
51, 52, 53, 54: white <= y > screen_height - rms_out[10] || screen_height < rms_out[10];
56, 57, 58, 59: white <= y > screen_height - rms_out[11] || screen_height < rms_out[11];
       default: white <= '0;
        endcase
    end
    end

endgenerate

    // Quadrature conversion and averaging
    converter i_converter [11:0]
    (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .mic        ( mic        ),
        .band_count ( band_count ),
        .rms_out    ( rms_out    )
    );

endmodule
