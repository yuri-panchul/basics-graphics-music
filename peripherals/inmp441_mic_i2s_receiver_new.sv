`ifdef UNDEFINED

// The INMP441 microphone is a digital microphone that outputs I2S data.

// This module receives the clock and outputs a 24-bit value.
// The INMP441 microphone outputs 64-bit words, with the first 24 bits being the left channel.
// The remaining bits are ignored.
// See https://invensense.tdk.com/wp-content/uploads/2015/02/INMP441.pdf for details
// Note: Asynchronous reset here is needed for one of FPGA boards we use.

`include "config.svh"

module inmp441_mic_i2s_receiver
# (
    parameter clk_mhz = 50
)
(
    input               clk, // Clock
    input               rst, // Reset
    output              lr, // Request data to be sent in left or right I2S channel
    output logic        ws, // I2S word select (left or right channel)
    output logic        sck, // I2S clock
    input               sd, // I2S data
    output logic [23:0] value // 24-bit value
);

    assign lr = 1'b0; // Left channel (we ignore the right channel)

    //------------------------------------------------------------------------

    // Drive SCK at 1/(2*sck_clock_divisor) of the clock frequency.
    // INMP441: Accepts SCK frequency 0.5-3.2 MHz, WS frequency 7.8-50 KHz
    // We will target SCK at or below 3 Mhz, and WS at or below 46.9 Khz
    // For example:
    //   clk 50 MHz -> 9 cycles -> sck clock at 2.777 Mhz, ws at 43.4 Khz
    //   clk 27 MHz -> 5 cycles -> sck clock at 2.7 Mhz, ws at 42.2 Khz
    localparam int sck_clock_divisor = $ceil(1.0 * clk_mhz / 3 / 2);
    logic [$clog2(sck_clock_divisor) - 1:0] cnt; // Counter used to drive SCK
    logic       sck_posedge; // Tracks SCK posedge
    logic       sck_negedge; // Tracks SCK negedge

    always_ff @ (posedge clk or posedge rst)
        if (rst) begin
            cnt <= '0;
            sck_posedge <= '0;
            sck_negedge <= '0;
        end else
            if (cnt == sck_clock_divisor - 1'b1) // Every N cycles drive SCK up or down
            begin
                sck <= ~ sck;
                cnt <= '0;
                if (~ sck)
                    sck_posedge <= '1;
                else
                    sck_negedge <= '1;
            end
            else
            begin
                cnt <= cnt + 1'b1;
                sck_posedge <= '0;
                sck_negedge <= '0;
            end

    //------------------------------------------------------------------------

    logic [5:0] cnt_sd; // Counter bit within a 64-bit SD-driven word
    logic [23:0] shift; // 24-bit value accumulator

     // Update SD on the rising edge of SCK, and may be capture 1-bit of data
    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            cnt_sd <= '0;
            shift <= '0;
        end
        else if (sck_posedge)
        begin
            cnt_sd <= cnt_sd + 1'b1;
            // INMP441: 64-bit SD-driven word, with 2-25 and 34-57 bits being valid 24 bits of data
            if (cnt_sd >= 6'd2 && cnt_sd <= 6'd25 || cnt_sd >= 6'd34 && cnt_sd <= 6'd57)
                shift <= {shift [22:0], sd}; // capture 1 bit from SD
        end

    // Update WS on the falling edge of SCK, and output 24-bit value
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ws <= '0;
        else if (sck_negedge)
        begin
            ws <= cnt_sd[5]; // 0 for 0-31, 1 for 32-63
            if (cnt_sd == 6'd0 || cnt_sd == 6'd31)
                if (ws == lr) // only capture channel we have requested data from
                    // Bad soldering may result in unexepcted values to be captured,
                    // valid values are up to around 100K
                    if (shift[23-:6] == '0 || shift[23-:6] == '1)
                        value <= shift; // capture 24-bit value
        end

endmodule

`endif
