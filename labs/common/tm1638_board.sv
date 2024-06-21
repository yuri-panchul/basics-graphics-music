/*============================================================================
LED&KEY TM1638 board controller

Copyright 2023 Alexander Kirichenko
Copyright 2023 Ruslan Zalata (HCW-132 variation support)

Based on https://github.com/alangarf/tm1638-verilog
Copyright 2017 Alan Garfield
==============================================================================*/

/*============================================================================
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
==============================================================================*/

///////////////////////////////////////////////////////////////////////////////////
//                              Top module
///////////////////////////////////////////////////////////////////////////////////

`include "config.svh"
`include "lab_specific_config.svh"

module tm1638_board_controller
# (
    parameter clk_mhz = 50,
              w_digit = 8,
              w_seg   = 8
)
(
    input                             clk,
    input                             rst,
    input        [               7:0] hgfedcba,
    input        [     w_digit - 1:0] digit,
    input        [               7:0] ledr,
    `ifdef HCW132
    output logic [              15:0] keys,
    `else
    output logic [               7:0] keys,
    `endif
    output                            sio_clk,
    output logic                      sio_stb,
    inout                             sio_data
);

    `ifdef EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS
        localparam static_hex = 1'b0;
    `else
        localparam static_hex = 1'b1;
    `endif

    localparam
        HIGH    = 1'b1,
        LOW     = 1'b0;

    localparam [  7:0]
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

    logic  [      5:0] instruction_step;
    logic  [      7:0] led_on;

    logic              tm_rw;
    wire               dio_in, dio_out;

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
    logic              tm_latch;
    wire               busy;
    logic  [      7:0] tm_in;
    wire   [      7:0] tm_out;

    ///////////// RESET synhronizer ////////////
    logic              reset_syn1;
    logic              reset_syn2 = 0;
    always @(posedge clk) begin
        reset_syn1  <= rst;
        reset_syn2  <= reset_syn1;
    end

    ////////////// TM1563 dio //////////////////
    assign sio_data = tm_rw ? dio_out : 'Z;
    assign dio_in   = sio_data;

    tm1638_sio
    # (
        .clk_mhz ( clk_mhz )
    )
    tm1638_sio
    (
        .clk        ( clk               ),
        .rst        ( reset_syn2        ),

        .data_latch ( tm_latch          ),
        .data_in    ( tm_in             ),
        .data_out   ( tm_out            ),
        .rw         ( tm_rw             ),

        .busy       ( busy              ),

        .sclk       ( sio_clk           ),
        .dio_in     ( dio_in            ),
        .dio_out    ( dio_out           )
    );

    ////////////// TM1563 data /////////////////

    // HEX registered
    logic [w_seg - 1:0] r_hex0,r_hex1,r_hex2,r_hex3,r_hex4,r_hex5,r_hex6,r_hex7;

    always @( posedge clk or posedge reset_syn2)
    begin
        if (reset_syn2) begin
            r_hex0 <= 'b0;
            r_hex1 <= 'b0;
            r_hex2 <= 'b0;
            r_hex3 <= 'b0;
            r_hex4 <= 'b0;
            r_hex5 <= 'b0;
            r_hex6 <= 'b0;
            r_hex7 <= 'b0;
        end
        else
        begin
            case (digit)
                'b00000001: r_hex0 <= hgfedcba;
                'b00000010: r_hex1 <= hgfedcba;
                'b00000100: r_hex2 <= hgfedcba;
                'b00001000: r_hex3 <= hgfedcba;
                'b00010000: r_hex4 <= hgfedcba;
                'b00100000: r_hex5 <= hgfedcba;
                'b01000000: r_hex6 <= hgfedcba;
                'b10000000: r_hex7 <= hgfedcba;
            endcase
        end
    end

    // HEX combinational
    wire [w_seg - 1:0] c_hex0,c_hex1,c_hex2,c_hex3,c_hex4,c_hex5,c_hex6,c_hex7;

    assign c_hex0 = digit [0] ? hgfedcba : '0;
    assign c_hex1 = digit [1] ? hgfedcba : '0;
    assign c_hex2 = digit [2] ? hgfedcba : '0;
    assign c_hex3 = digit [3] ? hgfedcba : '0;
    assign c_hex4 = digit [4] ? hgfedcba : '0;
    assign c_hex5 = digit [5] ? hgfedcba : '0;
    assign c_hex6 = digit [6] ? hgfedcba : '0;
    assign c_hex7 = digit [7] ? hgfedcba : '0;

    // Select combinational or registered HEX (blink or not)
    wire [w_seg - 1:0] hex0,hex1,hex2,hex3,hex4,hex5,hex6,hex7;

    assign hex0 = static_hex ? r_hex0 : c_hex0;
    assign hex1 = static_hex ? r_hex1 : c_hex1;
    assign hex2 = static_hex ? r_hex2 : c_hex2;
    assign hex3 = static_hex ? r_hex3 : c_hex3;
    assign hex4 = static_hex ? r_hex4 : c_hex4;
    assign hex5 = static_hex ? r_hex5 : c_hex5;
    assign hex6 = static_hex ? r_hex6 : c_hex6;
    assign hex7 = static_hex ? r_hex7 : c_hex7;

    // handles displaying 1-8 on a hex display
    task display_digit
    (
        input [    7:0] segs
    );
        begin
            tm_latch <= HIGH;
            tm_in   <= segs;
        end
    endtask

    // handles the LEDs 1-8
    task display_led
    (
        input [    2:0] led
    );
        begin
            tm_latch <= HIGH;
            tm_in <= {7'b0, led_on[led]};
        end
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

                    `ifdef HCW132
                    //  read back keys S1 - S16
                    4:  {keys[0], keys[1], keys[8], keys[9]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    5:  {tm_latch}         <= {HIGH};
                    6:  {keys[2], keys[3], keys[10], keys[11]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    7:  {tm_latch}         <= {HIGH};
                    8:  {keys[4], keys[5], keys[12], keys[13]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    9:  {tm_latch}         <= {HIGH};
                    10:  {keys[6], keys[7], keys[14], keys[15]} <= {tm_out[2], tm_out[6], tm_out[1], tm_out[5]};
                    `else
                    //  read back keys S1 - S8
                    4:  {keys[7], keys[3]} <= {tm_out[0], tm_out[4]};
                    5:  {tm_latch}         <= {HIGH};
                    6:  {keys[6], keys[2]} <= {tm_out[0], tm_out[4]};
                    7:  {tm_latch}         <= {HIGH};
                    8:  {keys[5], keys[1]} <= {tm_out[0], tm_out[4]};
                    9:  {tm_latch}         <= {HIGH};
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

                    `ifdef HCW132
                    // HCW-132 has very weird display map
                    19: display_digit({hex7[0],hex6[0],hex5[0],hex4[0],hex3[0],hex2[0],hex1[0],hex0[0]});
                    20: display_digit(8'b00000000);
                    21: display_digit({hex7[1],hex6[1],hex5[1],hex4[1],hex3[1],hex2[1],hex1[1],hex0[1]});
                    22: display_digit(8'b00000000);
                    23: display_digit({hex7[2],hex6[2],hex5[2],hex4[2],hex3[2],hex2[2],hex1[2],hex0[2]});
                    24: display_digit(8'b00000000);
                    25: display_digit({hex7[3],hex6[3],hex5[3],hex4[3],hex3[3],hex2[3],hex1[3],hex0[3]});
                    26: display_digit(8'b00000000);
                    27: display_digit({hex7[4],hex6[4],hex5[4],hex4[4],hex3[4],hex2[4],hex1[4],hex0[4]});
                    28: display_digit(8'b00000000);
                    29: display_digit({hex7[5],hex6[5],hex5[5],hex4[5],hex3[5],hex2[5],hex1[5],hex0[5]});
                    30: display_digit(8'b00000000);
                    31: display_digit({hex7[6],hex6[6],hex5[6],hex4[6],hex3[6],hex2[6],hex1[6],hex0[6]});
                    32: display_digit(8'b00000000);
                    33: display_digit({hex7[7],hex6[7],hex5[7],hex4[7],hex3[7],hex2[7],hex1[7],hex0[7]});
                    34: display_digit(8'b00000000);
                    `else
                    19: display_digit(hex7); // Digit 1
                    20: display_led(3'd7);        // LED 8

                    21: display_digit(hex6); // Digit 2
                    22: display_led(3'd6);        // LED 7

                    23: display_digit(hex5); // Digit 3
                    24: display_led(3'd5);        // LED 6

                    25: display_digit(hex4); // Digit 4
                    26: display_led(3'd4);        // LED 5

                    27: display_digit(hex3); // Digit 5
                    28: display_led(3'd3);        // LED 4

                    29: display_digit(hex2); // Digit 6
                    30: display_led(3'd2);        // LED 3

                    31: display_digit(hex1); // Digit 7
                    32: display_led(3'd1);        // LED 2

                    33: display_digit(hex0); // Digit 8
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
