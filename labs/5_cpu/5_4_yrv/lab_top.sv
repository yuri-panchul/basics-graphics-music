`include "config.svh"
`include "cpu/yrv_mcu.vh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------
    // Unused pins

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------
    // Board-specific key and switch assignments

    wire slow_clk_mode;
    wire slow_addr_data_sel;
    wire external_interrupt_raw;
    wire local_interrupt_0_raw;
    wire local_interrupt_1_raw;

    generate

        if (w_key >= 7)
        begin : keys_at_least_7

            assign slow_clk_mode          = key [w_key - 1];
            assign slow_addr_data_sel     = key [w_key - 2];
            assign external_interrupt_raw = key [w_key - 3];
            assign local_interrupt_0_raw  = key [w_key - 4];
            assign local_interrupt_1_raw  = key [w_key - 5];

            // TODO localparam w_user_key, w_user_sw
            // wire user_key, user_sw
        end
        else if (w_sw >= 7)
        begin : switches_at_least_7
            // Covers Terasic DE10-Lite (2 keys, 10 switches)

            assign slow_clk_mode          = sw  [w_sw  - 1];
            assign slow_addr_data_sel     = sw  [w_sw  - 2];
            assign external_interrupt_raw = sw  [w_sw  - 3];
            assign local_interrupt_0_raw  = sw  [w_sw  - 4];
            assign local_interrupt_1_raw  = sw  [w_sw  - 5];
        end
        else if (w_key >= 4)
        begin : keys_at_least_4
            // Covers Omdazz Altera Cyclone IV board
            // (4 keys are combined with 4 switches)

            assign slow_clk_mode          = key [w_key - 1];
            assign slow_addr_data_sel     = 1'b0;
            assign external_interrupt_raw = key [w_key - 2];
            assign local_interrupt_0_raw  = 1'b0;
            assign local_interrupt_1_raw  = 1'b0;
        end
        else
        begin : few_keys_and_sw_available

            assign slow_clk_mode          = 1'b0;
            assign slow_addr_data_sel     = 1'b0;
            assign external_interrupt_raw = 1'b0;
            assign local_interrupt_0_raw  = 1'b0;
            assign local_interrupt_1_raw  = 1'b0;
        end

    endgenerate

    //------------------------------------------------------------------------
    // MCU clock

    wire muxed_clk_raw = slow_clk_mode ? slow_clk : clk;
    wire muxed_clk;

    `ifdef SIMULATION
        assign muxed_clk = muxed_clk_raw;
    `else
         // TODO: Proper support for Gowin and Lattice/Yosys
         // TODO: Consider clock mux macro

         `ifdef ALTERA_RESERVED_QIS
             global i_global (.in (muxed_clk_raw), .out (muxed_clk));
         `elsif XILINX_VIVADO
             BUFG   i_bufg   (.I  (muxed_clk_raw), .O   (muxed_clk));
         `else
             assign muxed_clk = muxed_clk_raw;
         `endif
    `endif

    //------------------------------------------------------------------------
    // MCU inputs

    wire        ei_req;            // external int request
    wire        nmi_req;           // non-maskable interrupt
    wire [15:0] li_req;

    wire        resetb   = ~ rst;  // master reset
    wire        ser_rxd  = 1'b0;   // receive data input

    wire [15:0] port4_in = 16' ( key );
    wire [15:0] port5_in = 16' ( sw  );

    //------------------------------------------------------------------------
    // MCU outputs

    wire         debug_mode;  // in debug mode
    wire         ser_clk;     // serial clk output (cks mode)
    wire         ser_txd;     // transmit data output
    wire         wfi_state;   // waiting for interrupt
    wire  [15:0] port0_reg;   // port 0
    wire  [15:0] port1_reg;   // port 1
    wire  [15:0] port2_reg;   // port 2
    wire  [15:0] port3_reg;   // port 3

    // Auxiliary UART receive pin

    `ifdef BOOT_FROM_AUX_UART
        wire     aux_uart_rx = uart_rx;
    `endif

    // Exposed memory bus for debug purposes

    wire         mem_ready;   // memory ready
    wire  [31:0] mem_rdata;   // memory read data
    wire         mem_lock;    // memory lock (rmw)
    wire         mem_write;   // memory write enable
    wire  [ 1:0] mem_trans;   // memory transfer type
    wire  [ 3:0] mem_ble;     // memory byte lane enables
    wire  [31:0] mem_addr;    // memory address
    wire  [31:0] mem_wdata;   // memory write data

    wire  [31:0] extra_debug_data;

    //------------------------------------------------------------------------
    // MCU instantiation

    yrv_mcu
    # (.clk_frequency (clk_mhz * 1000 * 1000))
    i_yrv_mcu
    (.clk (muxed_clk), .*);

    //------------------------------------------------------------------------
    // Pin assignments
    //------------------------------------------------------------------------
    // LED

    logic local_interrupt_2_toggle;

    localparam w_reduced_led = w_led - 1;

    assign led =
    {
        slow_clk_mode ? muxed_clk : local_interrupt_2_toggle,
        w_reduced_led' ({ port3_reg [7:0], port2_reg })
    };

    //------------------------------------------------------------------------
    // Seven-segment display

    wire [7:0] abcdefgh_from_mcu
        = { port0_reg [6:0], port0_reg [7] };

    wire [w_digit - 1:0] digit_from_mcu
        = w_digit' (port1_reg [7:0]);

    //------------------------------------------------------------------------

    wire [          7:0] abcdefgh_from_show_mode;
    wire [w_digit - 1:0] digit_from_show_mode;

    localparam w_display_number = w_digit * 4;
    logic [w_display_number - 1:0] display_number;

    always_comb
        if (slow_addr_data_sel)
            display_number = w_display_number' (mem_addr);
        else
            display_number = w_display_number' (mem_rdata);

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .number   ( display_number            ),
        .dots     ( w_digit' (0)              ),
        .abcdefgh ( abcdefgh_from_show_mode   ),
        .digit    ( digit_from_show_mode      )
    );

    //------------------------------------------------------------------------

    always_comb
        if (slow_clk_mode)
        begin
            abcdefgh = abcdefgh_from_show_mode;
            digit    = digit_from_show_mode;
        end
        else
        begin
            abcdefgh = abcdefgh_from_mcu;
            digit    = digit_from_mcu;
        end

    //------------------------------------------------------------------------
    // External interrupt and Local interrupts 0 and 1
    //
    // See
    //
    // Inside an Open-Source Processor by Monte Dalrympl
    //
    // 3.2.8 Machine Interrupt-Enable (mie)
    // The Machine Local Interrupt-Enable bits (MLIE, bits 31-16)
    // enable the individual Local interrupts
    // that are custom additions for this design.
    //
    // 3.2.9 Machine Interrupt-Pending (mip)
    // The Machine Local Interrupt-Pending bits (MLIP, bits 31-16)
    // reflects the state of the individual Local interrupts.
    //
    // 3.2.16 Machine Exception Cause (mcause)
    // Local interrupts are identified by mcause[31] interrupt bit
    // and mcause[30:0] from 16 (Local Interrupt 0)
    // to 31 (Local Interrupt 15).
    //
    // Listing 5.6: Local Interrupt Exception Code Definitions.
    // Table 6.2: Interrupt-related Signals

    wire [2:0] intr_debounced;

      sync_and_debounce # (.w (3))
    i_sync_and_debounce
    (
        .clk,
        .reset (rst),

        .sw_in
        ({
            external_interrupt_raw,
            local_interrupt_0_raw,
            local_interrupt_1_raw
        }),

        .sw_out (intr_debounced)
    );

    //------------------------------------------------------------------------

    wire external_interrupt;
    wire local_interrupt_0;
    wire local_interrupt_1;

      pulse_on_0_to_1 # (3)
    i_pulse_on_0_to_1
    (
        .clk,
        .rst,
        .level (intr_debounced),

        .pulse
        ({
            external_interrupt,
            local_interrupt_0,
            local_interrupt_1
        })
    );

    //------------------------------------------------------------------------
    // Local interrupt 2

    wire local_interrupt_2;

    strobe_gen
    # (.clk_mhz (clk_mhz), .strobe_hz (100))
    local_timer_interrupt_gen
    (
        .clk,
        .rst,
        .strobe (local_interrupt_2)
    );

      pulse_to_level
    i_pulse_to_level
    (
        .clk,
        .rst,
        .pulse (local_interrupt_2),
        .level (local_interrupt_2_toggle)
    );

    //------------------------------------------------------------------------

    wire external_interrupt_extended;
    wire local_interrupt_0_extended;
    wire local_interrupt_1_extended;
    wire local_interrupt_2_extended;

      pulse_extender
    # (.width (4), .depth (6))
    i_pulse_extender
    (
        .clk,
        .rst,

        .pulse
        ({
            external_interrupt,
            local_interrupt_0,
            local_interrupt_1,
            local_interrupt_2
        }),

        .extended
        ({
            external_interrupt_extended,
            local_interrupt_0_extended,
            local_interrupt_1_extended,
            local_interrupt_2_extended
        })
    );

    //------------------------------------------------------------------------

    assign nmi_req = 1'b0;
    assign ei_req  = external_interrupt_extended;

    assign li_req  =
    {
        13'b0,
        local_interrupt_2_extended,
        local_interrupt_1_extended,
        local_interrupt_0_extended
    };

endmodule