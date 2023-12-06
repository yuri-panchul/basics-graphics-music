//------------------------------------------------------------------------
//
//  Digilent PMOD Mic3 (SPI) data capture module
//
//  This module is traighforward, it generates bit clock and word clock,
//  while shifting in 16 bits of data coming from I2S device.
//
//  Ready signal is strobe generated during Tquiet when all 16 bits are
//  shifted in.
//
//  Sampling period is 2*16 clocks, left_right parameter defines when data
//  should be samples: 0 - first 16 clocks, 1 - last 16 clock.
//
//  Output value is 12 LSB of data which is unsigned [0-Vcc].
//
//  Copyright (C) 2023 Ruslan Zalata <rz@fabmicro.ru>
//
//  SPDX-License-Identifier: BSD-2-Clause
//
//------------------------------------------------------------------------

module digilent_pmod_mic3_spi_receiver_v2
# (
    parameter clk_mhz = 50,
              samplerate_hz = 48000,
              left_right = 0
)
(
    input               clk,
    input               rst,
    output              cs,
    output logic        sck,
    input               sdo,
    output logic [11:0] value,
    output logic        ready
);

    localparam sck_max = clk_mhz * 1000000 / samplerate_hz / (16*2) / 2;
    localparam w_sck_cnt = $clog2(sck_max + 1);

    logic [w_sck_cnt - 1:0] sck_cnt;

    logic [4:0] bitnum;
    logic [15:0] shift;

    assign cs = (left_right == 0) ? bitnum[4] : ~bitnum[4];

    always_ff @ (posedge clk or posedge rst)
        if(rst)
        begin
            sck_cnt <= 'd0;
            bitnum  <= 'd0;
            sck     <= 'b0;
        end else begin
            sck_cnt <= sck_cnt + 'd1;
            ready   <= 'b0;

            if (sck_cnt == w_sck_cnt'(sck_max))
            begin
                sck_cnt <= 'd0;
                sck     <= ~sck;

                if (~sck) // Process one bit when SCK is low 
                begin
                    bitnum <= bitnum + 'd1;

                    // Shift one bit of data when CS is low
                    if (~cs)
                        shift <= {shift[14:0], sdo};

                    // Is this the last bit ?
                    if ((left_right == 'b0 && bitnum == 'd16) ||
                        (left_right == 'b1 && bitnum == 'd0))
                    begin
                        value <= shift[11:0];
                        ready <= 'b1;
                    end
                end
            end
        end

endmodule
