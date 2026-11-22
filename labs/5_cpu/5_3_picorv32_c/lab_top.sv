`include "config.svh"

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

    assign red   = '0;
    assign green = '0;
    assign blue  = '0;
    assign sound = '0;

    //------------------------------------------------------------------------
    // PicoRV32 native memory bus

    wire         trap;

    wire         mem_valid;
    wire         mem_instr;
    logic        mem_ready;
    wire  [31:0] mem_addr;
    wire  [31:0] mem_wdata;
    wire  [ 3:0] mem_wstrb;
    logic [31:0] mem_rdata;

    //------------------------------------------------------------------------
    // UART boot loader

    wire boot_enable;

    generate
        if      (w_sw  >= 1) assign boot_enable = sw  [w_sw  - 1];
        else if (w_key >= 1) assign boot_enable = key [w_key - 1];
        else                 assign boot_enable = 1'b0;
    endgenerate

    wire        resetn;
    wire        boot_wr;
    wire [31:0] boot_addr;
    wire [31:0] boot_wdata;

    // TODO: for now interface only
    // boot_loader
    // # (.clk_mhz (clk_mhz))
    // i_boot_loader
    // (
    //     .clk        ( clk        ),
    //     .rst        ( rst        ),
    //     .enable     ( boot_enable ),
    //     .uart_rx    ( uart_rx    ),
    //     .boot_wr    ( boot_wr    ),
    //     .boot_addr  ( boot_addr  ),
    //     .boot_wdata ( boot_wdata ),
    //     .cpu_resetn ( resetn     )
    // );

    picorv32
    # (
        .PROGADDR_RESET ( 32'h0000_0000 ),
        .STACKADDR      ( 32'h0000_4000 ),  // top of the 16 KB RAM
        .BARREL_SHIFTER ( 1             ),
        .COMPRESSED_ISA ( 0             ),
        .ENABLE_MUL     ( 0             ),  // rv32i: mul/div via libgcc
        .ENABLE_DIV     ( 0             ),
        .ENABLE_IRQ     ( 0             )
    )
    i_picorv32
    (
        .clk        ( clk       ),
        .resetn     ( resetn    ),
        .trap       ( trap      ),

        .mem_valid  ( mem_valid ),
        .mem_instr  ( mem_instr ),
        .mem_ready  ( mem_ready ),
        .mem_addr   ( mem_addr  ),
        .mem_wdata  ( mem_wdata ),
        .mem_wstrb  ( mem_wstrb ),
        .mem_rdata  ( mem_rdata ),

        .irq        ( 32'b0     )
    );

    //------------------------------------------------------------------------
    // Address decode
    //
    //   0xffff_00xx  -> memory-mapped I/O (mmio_t)
    //   everything else -> RAM (reset vector at 0x0)

    wire is_mmio = mem_valid & (mem_addr [31:16] == 16'hffff);
    wire is_ram  = mem_valid & (mem_addr [31:16] != 16'hffff);

    wire        mem_write = | mem_wstrb;

    // MMIO word select (byte offsets 0x0 / 0x4 / 0x8 / 0xc)

    localparam [1:0] SEL_SEVEN_SEG = 2'd0,   // 0xffff_0000
                     SEL_LED       = 2'd1,   // 0xffff_0004
                     SEL_KEY_SW    = 2'd2,   // 0xffff_0008
                     SEL_SERIAL    = 2'd3;   // 0xffff_000c

    wire [1:0] mmio_sel = mem_addr [3:2];

    //------------------------------------------------------------------------
    // RAM (with an unused boot port for now; wired up by boot_loader later)

    wire [31:0] ram_rdata;
    wire        ram_ready;

    data_ram # (.SIZE (4096)) i_data_ram
    (
        .clk        ( clk               ),
        .mem_valid  ( is_ram            ),
        .mem_ready  ( ram_ready         ),
        .mem_addr   ( mem_addr          ),
        .mem_wstrb  ( mem_wstrb         ),
        .mem_rdata  ( ram_rdata         ),
        .mem_wdata  ( mem_wdata         ),
        .boot_wr    ( boot_wr           ),
        .boot_addr  ( boot_addr         ),
        .boot_wdata ( boot_wdata        )
    );

    //------------------------------------------------------------------------
    // MMIO write registers: LED and seven-segment value

    logic [w_led - 1:0]      led_reg;
    logic [w_digit * 4 - 1:0] seven_seg_reg;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            led_reg       <= '0;
            seven_seg_reg <= '0;
        end
        else if (is_mmio & mem_write)
        begin
            if (mmio_sel == SEL_LED)       led_reg       <= mem_wdata [w_led - 1:0];
            if (mmio_sel == SEL_SEVEN_SEG) seven_seg_reg <= mem_wdata [w_digit * 4 - 1:0];
        end

    assign led = led_reg;

    //------------------------------------------------------------------------
    // MMIO reads: key/switch input and UART status
    //
    //   key_sw word = { sw [31:16], key [15:0] }   (matches mmio.key_sw.f)
    //   serial word bit 0 = UART transmitter busy

    wire        uart_busy;

    wire [31:0] key_sw_word = { 16' (sw), 16' (key) };
    wire [31:0] serial_word = { 31'b0, uart_busy };

    logic [31:0] mmio_rdata;

    always_comb
        case (mmio_sel)
            SEL_KEY_SW : mmio_rdata = key_sw_word;
            SEL_SERIAL : mmio_rdata = serial_word;
            default    : mmio_rdata = 32'b0;
        endcase

    //------------------------------------------------------------------------
    // Bus response mux. MMIO answers in a single cycle; RAM adds one wait
    // state through ram_ready.

    assign mem_rdata = is_mmio ? mmio_rdata : ram_rdata;
    assign mem_ready = is_mmio | ram_ready;

    //------------------------------------------------------------------------
    // Seven-segment display (reused common module, hex rendering)

    seven_segment_display
    # (
        .w_digit ( w_digit ),
        .clk_mhz ( clk_mhz )
    )
    i_seven_segment_display
    (
        .clk      ( clk           ),
        .rst      ( rst           ),
        .number   ( seven_seg_reg ),
        .dots     ( w_digit' (0)  ),
        .abcdefgh ( abcdefgh      ),
        .digit    ( digit         )
    );

    // TODO: UART for serial I/O and program load if needed

endmodule
