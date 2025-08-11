// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// Updated hackathon_top.sv
module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [3:0] gpio
);

    // Exercise: Instantiate the ultrasonic module
    // and the 7-segment display controller module,
    // connect them with each other and with GPIO

    // START_SOLUTION

    // For rotary encoder A/B signals
    wire a, b;
    
    // Connect A and B directly to gpio pins
    assign a = gpio[2];
    assign b = gpio[3];
    
    // Connect switch directly to gpio[0] 
    wire sw = gpio[0];  // Direct connection to GPIO0

    wire [15:0] value;
    wire sw_state;

    rotary_encoder i_rotary_encoder
    (
        .clk      ( clock       ),
        .reset    ( reset       ),
        .a        ( a           ),
        .b        ( b           ),
        .value    ( value       ),
        .sw       ( sw          ),  // Direct connection to switch
        .sw_state ( sw_state    )
    );

    seven_segment_display
    # (.w_digit (8))
    i_7segment
    (
        .clk      ( clock       ),
        .rst      ( reset       ),
        .number   ( 32' (value) ),
        .dots     ( {8{sw_state}} ),  // Control decimal points with switch state
        .abcdefgh ( abcdefgh    ),
        .digit    ( digit       )
    );

    // Display switch state on all LEDs
    assign led = {8{sw_state}};  // Control LEDs with switch state

endmodule