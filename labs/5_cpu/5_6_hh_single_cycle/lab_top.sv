`include "config.svh"
//`define ORIGINAL_TB              // This line determines which execution variant of the program and testbench is used — H&H or School_RISCV



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

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    wire [ 4:0] regAddr;  // debug access reg address
    wire [31:0] regData;  // debug access reg data
    wire [31:0] imAddr;   // instruction memory address
    wire [31:0] imData;   // instruction memory data
    wire [31:0] wRAMData; // data for writing to RAM
    wire [31:0] rRAMData; // data read from  RAM
    wire [31:0] dAddr;    // addres for RAM
    wire [31:0] ALUResult;//
    wire        we;       // enable write to data memory
    wire [31:0] PC;       //

    riscvsingle cpu
    (
        .clk        ( slow_clk ),
        .reset      ( rst      ),
        .PC         ( PC       ),
        .Instr      ( imData   ) ,
        .MemWrite   ( we       ),
        .ALUResult  ( ALUResult),
        .WriteData  ( wRAMData ),
        .ReadData   ( rRAMData )
    );
    assign imAddr = PC >> 2 ;
    assign dAddr  = ALUResult;

   dmem ram
    (
        .clk        ( clk      ),
        .we         ( we       ),
        .a          ( dAddr    ),
        .wd         ( wRAMData ),
        .rd         ( rRAMData )
    );

`ifdef ORIGINAL_TB 

    instruction_rom # (.SIZE (64), .NAME("program.hex")) rom
    (
        .a       ( imAddr  ),
        .rd      ( imData  )
    );
`else
    instruction_rom # (.SIZE (64), .NAME("riscvtest.hex")) rom
    (
        .a       ( imAddr  ),
        .rd      ( imData  )
    );
`endif
    //------------------------------------------------------------------------

    // assign regAddr = 5'd10;  // a0

    `ifdef ORIGINAL_TB 
       assign led              = '0;
    `else
       assign led[0]            = we;
       assign led[w_led-1:1]    ='0;
    `endif

    localparam w_number = w_digit * 4;

    wire [w_number - 1:0] number
        = w_number' ( key [0] ? ALUResult : imAddr );



    seven_segment_display
    # (
        .w_digit  ( w_digit  ),
        .clk_mhz  ( clk_mhz  )
    )
    display
    (
        .clk      ( clk      ),
        .rst      ( rst      ),

        .number   ( number   ),
        .dots     ( '0       ),

        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

endmodule
