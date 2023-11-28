//------------------------------------------------------------------------
//
//  INMP441 Microphone (I2S) data capture module
//
//  This module is traighforward, it generates bit clock and word clock,
//  while shifting in 24 bits of data coming from I2S device. Sampling word
//  (left or right channel) can be selected using left_right parameter.
//
//  Ready signal is strobe generated when all 24 bits are shifted in.
//
//  Copyright (C) 2023 Ruslan Zalata <rz@fabmicro.ru>
//
//  SPDX-License-Identifier: BSD-2-Clause
//
//------------------------------------------------------------------------

module inmp441_mic_i2s_receiver_v2
# (
    parameter clk_mhz = 50,
              samplerate_hz = 48800,
              left_right = 0
)
(
    input               clk,
    input               rst,
    output              lr,
    output              ws,
    output logic        sck,
    input               sd,
    output logic [23:0] value,
    output logic        ready
);

    assign lr = left_right;

    localparam sck_top = clk_mhz * 1000000 / samplerate_hz / 64 / 2;
    localparam w_sck_cnt = $clog2(sck_top) + 1;

    logic [w_sck_cnt - 1:0] sck_cnt;

    logic [5:0] bitnum;
    logic [23:0] shift;

    assign ws = bitnum[5];

    always_ff @ (posedge clk or posedge rst)
        if(rst)
        begin
            sck_cnt <= 'd0;
            bitnum   <= 'd0;
            sck      <= 'b0;
        end else begin
            sck_cnt <= sck_cnt + 'd1;
            ready <= 'b0;

            if (sck_cnt == w_sck_cnt'(sck_top))
            begin
                sck_cnt <= 'd0;
                sck <= ~sck;

                if (~sck) // last clk before SCK goes high
                begin
                    bitnum <= bitnum + 'd1;

                    if (ws == lr)
                        shift <= {shift[22:0], sd};

                    // Is this the last bit ?
                    if ((lr == 'b0 && bitnum == 'd24) ||
                        (lr == 'b1 && bitnum == 'd0))
                    begin
                        value <= shift;
                        ready <= 'b1;
                    end
                end
            end
        end

endmodule
