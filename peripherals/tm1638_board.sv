/*============================================================================
LED&KEY TM1638 board controller
SPDX-License-Identifier: Apache-2.0

Copyright 2023 Alexander Kirichenko
Copyright 2023 Ruslan Zalata (HCW-132 variation support)

Based on https://github.com/alangarf/tm1638-verilog
Copyright 2017 Alan Garfield
Copyright Contributors to the basics-graphics-music project.
==============================================================================*/

///////////////////////////////////////////////////////////////////////////////////
//                              Top module
///////////////////////////////////////////////////////////////////////////////////

`include "config.svh"
`include "lab_specific_board_config.svh"

module tm1638_board_controller
# (
    parameter clk_mhz = 50,
              w_digit = 8,
              w_seg   = 8
)
(
    input                         clk,
    input                         rst,
    input        [           7:0] hgfedcba,
    input        [ w_digit - 1:0] digit,
    input        [           7:0] ledr,
    `ifdef USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE
    output logic [          15:0] keys,
    `else
    output logic [           7:0] keys,
    `endif
    output                        sio_clk,
    output logic                  sio_stb,
    `ifdef SPLIT_TM1638_DIO_INOUT_SIGNAL
    input                         sio_data_in,
    output                        sio_data_out,
    output                        sio_data_out_en
    `else
    inout                         sio_data
    `endif
);

    localparam
        HIGH    = 1'b1,
        LOW     = 1'b0;

    localparam [7:0]
        C_READ_KEYS   = 8'b01000010,
        C_WRITE_DISP  = 8'b01000000,
        C_SET_ADDR_0  = 8'b11000000,
        C_DISPLAY_ON  = 8'b10001111;

    localparam CLK_DIV = 19; // speed of FSM scanner

    logic  [CLK_DIV:0] counter;

    localparam [CLK_DIV:0] COUNTER_0 = '0;

    // TM1632 requires at least 1us strobe duration
    // we can generate this by adding delay at the end of
    // each transfer. For that we define a flag indicating
    // completion of 1us delay loop.
    wire               stb_delay_complete = (counter > clk_mhz ? 1 : 0);

    logic  [5:0] instruction_step;
    logic  [7:0] led_on;

    logic        tm_rw;
    wire         dio_in, dio_out;

    // setup tm1638 module with it's tristate IO
    //   tm_in      is written to module
    //   tm_out     is read from module
    //   tm_latch   triggers the module to read/write display
    //   tm_rw      selects read or write mode to display
    //   busy       indicates when module is busy
    //                (another latch will interrupt)
    //   tm_clk     is the data clk
    //   dio_in     for reading from display
    //   dio_out    for sending to display
    //
    logic        tm_latch;
    wire         busy;
    logic  [7:0] tm_in;
    wire   [7:0] tm_out;

    ///////////// RESET synhronizer ////////////
    logic             reset_syn1;
    logic             reset_syn2 = 0;
    always @(posedge clk) begin
        reset_syn1 <= rst;
        reset_syn2 <= reset_syn1;
    end

    ////////////// TM1563 dio //////////////////

    `ifdef SPLIT_TM1638_DIO_INOUT_SIGNAL
    assign dio_in          = sio_data_in;
    assign sio_data_out    = dio_out;
    assign sio_data_out_en = tm_rw;
    `else
    assign sio_data = tm_rw ? dio_out : 'z;
    assign dio_in   = sio_data;
    `endif

    tm1638_sio
    # (
        .clk_mhz ( clk_mhz )
    )
    tm1638_sio
    (
        .clk        ( clk        ),
        .rst        ( reset_syn2 ),

        .data_latch ( tm_latch   ),
        .data_in    ( tm_in      ),
        .data_out   ( tm_out     ),
        .rw         ( tm_rw      ),

        .busy       ( busy       ),

        .sclk       ( sio_clk    ),
        .dio_in     ( dio_in     ),
        .dio_out    ( dio_out    )
    );

    ////////////// TM1563 data /////////////////
    wire [w_digit -1:0][w_seg - 1:0] hex;

    tm1638_registers
    # (
        .w_digit  ( w_digit ),
        .w_seg    ( w_seg   )
    )
    i_tm1638_regs
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .hgfedcba ( hgfedcba ),
        .digit    ( digit    ),
        .hex      ( hex      )
    );

    // handles displaying 1-8 on a hex display
    task display_digit
    (
        input [7:0] segs
    );

        tm_latch <= HIGH;
        tm_in    <= segs;

    endtask

    // handles the LEDs 1-8
    task display_led
    (
        input [2:0] led
    );
        tm_latch <= HIGH;
        tm_in <= {7'b0, led_on[led]};

    endtask

    // controller FSM

    always @(posedge clk or posedge reset_syn2)
    begin
        if (reset_syn2) begin
            instruction_step <= 'b0;
            sio_stb          <= HIGH;
            tm_rw            <= HIGH;

            counter          <= 'd0;
            keys             <= 'b0;
            led_on           <= 'b0;

        end else begin

            counter <= counter + 1;

            if (counter[0] && ~busy) begin

                instruction_step <= instruction_step + 1;

                case (instruction_step)
                    // *** KEYS ***
                    1:  {sio_stb, tm_rw}   <= {LOW, HIGH};
                    2:  {tm_latch, tm_in}  <= {HIGH, C_READ_KEYS}; // read mode
                    3:  {tm_latch, tm_rw}  <= {HIGH, LOW};

                    `ifdef USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE
                    //  read back keys S1 - S16
                    4:  {keys[0], keys[1], keys[8], keys[9]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    5:  tm_latch           <= HIGH;
                    6:  {keys[2], keys[3], keys[10], keys[11]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    7:  tm_latch           <= HIGH;
                    8:  {keys[4], keys[5], keys[12], keys[13]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    9:  tm_latch           <= HIGH;
                    10:  {keys[6], keys[7], keys[14], keys[15]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    `else
                    //  read back keys S1 - S8
                    4:  {keys[7], keys[3]} <= {tm_out[0], tm_out[4]};
                    5:  tm_latch           <= HIGH;
                    6:  {keys[6], keys[2]} <= {tm_out[0], tm_out[4]};
                    7:  tm_latch           <= HIGH;
                    8:  {keys[5], keys[1]} <= {tm_out[0], tm_out[4]};
                    9:  tm_latch           <= HIGH;
                    10: {keys[4], keys[0]} <= {tm_out[0], tm_out[4]};
                    `endif
                    11: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    12: {instruction_step} <= (stb_delay_complete ? 6'd13 : 6'd12); // loop till delay complete

                    // *** DISPLAY ***
                    13: {sio_stb, tm_rw}   <= {LOW, HIGH};
                    14: {tm_latch, tm_in}  <= {HIGH, C_WRITE_DISP}; // write mode
                    15: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    16: {instruction_step} <= (stb_delay_complete ? 6'd17 : 6'd16); // loop till delay complete

                    17: {sio_stb, tm_rw}   <= {LOW, HIGH};
                    18: {tm_latch, tm_in}  <= {HIGH, C_SET_ADDR_0}; // set addr 0 pos

                    `ifdef USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE
                    // HCW-132 has very weird display map
                    19: display_digit({hex[7][0],hex[6][0],hex[5][0],hex[4][0],hex[3][0],hex[2][0],hex[1][0],hex[0][0]});
                    20: display_digit(8'b00000000);
                    21: display_digit({hex[7][1],hex[6][1],hex[5][1],hex[4][1],hex[3][1],hex[2][1],hex[1][1],hex[0][1]});
                    22: display_digit(8'b00000000);
                    23: display_digit({hex[7][2],hex[6][2],hex[5][2],hex[4][2],hex[3][2],hex[2][2],hex[1][2],hex[0][2]});
                    24: display_digit(8'b00000000);
                    25: display_digit({hex[7][3],hex[6][3],hex[5][3],hex[4][3],hex[3][3],hex[2][3],hex[1][3],hex[0][3]});
                    26: display_digit(8'b00000000);
                    27: display_digit({hex[7][4],hex[6][4],hex[5][4],hex[4][4],hex[3][4],hex[2][4],hex[1][4],hex[0][4]});
                    28: display_digit(8'b00000000);
                    29: display_digit({hex[7][5],hex[6][5],hex[5][5],hex[4][5],hex[3][5],hex[2][5],hex[1][5],hex[0][5]});
                    30: display_digit(8'b00000000);
                    31: display_digit({hex[7][6],hex[6][6],hex[5][6],hex[4][6],hex[3][6],hex[2][6],hex[1][6],hex[0][6]});
                    32: display_digit(8'b00000000);
                    33: display_digit({hex[7][7],hex[6][7],hex[5][7],hex[4][7],hex[3][7],hex[2][7],hex[1][7],hex[0][7]});
                    34: display_digit(8'b00000000);
                    `else
                    19: display_digit(hex[7]); // Digit 1
                    20: display_led(3'd7);        // LED 8

                    21: display_digit(hex[6]); // Digit 2
                    22: display_led(3'd6);        // LED 7

                    23: display_digit(hex[5]); // Digit 3
                    24: display_led(3'd5);        // LED 6

                    25: display_digit(hex[4]); // Digit 4
                    26: display_led(3'd4);        // LED 5

                    27: display_digit(hex[3]); // Digit 5
                    28: display_led(3'd3);        // LED 4

                    29: display_digit(hex[2]); // Digit 6
                    30: display_led(3'd2);        // LED 3

                    31: display_digit(hex[1]); // Digit 7
                    32: display_led(3'd1);        // LED 2

                    33: display_digit(hex[0]); // Digit 8
                    34: display_led(3'd0);        // LED 1
                    `endif

                    35: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    36: {instruction_step} <= (stb_delay_complete ? 6'd37 : 6'd36); // loop till delay complete

                    37: {sio_stb, tm_rw}   <= {LOW, HIGH};
                    38: {tm_latch, tm_in}  <= {HIGH, C_DISPLAY_ON}; // display on, full bright

                    39: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    40: {instruction_step} <= (stb_delay_complete ? 6'd0 : 6'd40); // loop till delay complete

                endcase

                led_on           <= ledr;

            end else if (busy) begin
                // pull latch low next clock cycle after module has been
                // latched
                tm_latch <= LOW;
            end
        end
    end

endmodule


///////////////////////////////////////////////////////////////////////////////////
//           TM1638 SIO driver for tm1638_board_controller top module
///////////////////////////////////////////////////////////////////////////////////
module tm1638_sio
# (
    parameter clk_mhz = 50
)
(
    input          clk,
    input          rst,

    input          data_latch,
    input  [7:0]   data_in,
    output [7:0]   data_out,
    input          rw,

    output         busy,

    output         sclk,
    input          dio_in,
    output logic   dio_out
);

    localparam CLK_DIV1 = $clog2 (clk_mhz*1000/2/700) - 1; // 700 kHz is recommended SIO clock
    localparam [1:0]
        S_IDLE      = 2'h0,
        S_WAIT      = 2'h1,
        S_TRANSFER  = 2'h2;

    logic [       1:0] cur_state, next_state;
    logic [CLK_DIV1:0] sclk_d, sclk_q;
    logic [       7:0] data_d, data_q, data_out_d, data_out_q;
    logic              dio_out_d;
    logic [       2:0] ctr_d, ctr_q;

    // output read data
    assign data_out = data_out_q;

    // we're busy if we're not idle
    assign busy = cur_state != S_IDLE;

    // tick the clock if we're transfering data
    assign sclk = ~((~sclk_q[CLK_DIV1]) & (cur_state == S_TRANSFER));

    always_comb
    begin
        sclk_d = sclk_q;
        data_d = data_q;
        dio_out_d = dio_out;
        ctr_d = ctr_q;
        data_out_d = data_out_q;
        next_state = cur_state;

        case(cur_state)
            S_IDLE: begin
                sclk_d = 0;
                if (data_latch) begin
                    // if we're reading, set to zero, otherwise latch in
                    // data to send
                    data_d = data_in;
                    next_state = S_WAIT;
                end
            end

            S_WAIT: begin
                sclk_d = sclk_q + 1'd1;
                // wait till we're halfway into clock pulse
                if (sclk_q == {1'b0, {CLK_DIV1{1'b1}}}) begin
                    sclk_d = 0;
                    next_state = S_TRANSFER;
                end
            end

            S_TRANSFER: begin
                sclk_d = sclk_q + 1'd1;
                if (sclk_q == 0) begin
                    // start of clock pulse, output MSB
                    dio_out_d = data_q[0];

                end else if (sclk_q == {1'b0, {CLK_DIV1{1'b1}}}) begin
                    // halfway through pulse, read from device
                    data_d = {dio_in, data_q[7:1]};

                end else if (&sclk_q) begin
                    // end of pulse, tick the counter
                    ctr_d = ctr_q + 1'd1;

                    if (&ctr_q) begin
                        // last bit sent, switch back to idle
                        // and output any data recieved
                        next_state = S_IDLE;
                        data_out_d = data_q;

                        dio_out_d = '0;
                    end
                end
            end

            default:
                next_state = S_IDLE;
        endcase
    end

    always @(posedge clk)
    begin
        if (rst)
        begin
            cur_state <= S_IDLE;
            sclk_q <= 0;
            ctr_q <= 0;
            dio_out <= 0;
            data_q <= 0;
            data_out_q <= 0;
        end
        else
        begin
            cur_state <= next_state;
            sclk_q <= sclk_d;
            ctr_q <= ctr_d;
            dio_out <= dio_out_d;
            data_q <= data_d;
            data_out_q <= data_out_d;
        end
    end
endmodule
