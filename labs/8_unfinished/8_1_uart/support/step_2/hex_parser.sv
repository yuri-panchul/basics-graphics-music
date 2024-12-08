module hex_parser
# (
    parameter address_width       = 32,
              data_width          = 32,
              char_width          = 8,
              clk_frequency       = 50 * 1000 * 1000,
              timeout_in_seconds  = 1
)
(
    input                              clk,
    input                              reset,

    input                              in_valid,
    input        [char_width    - 1:0] in_char,

    output logic                       out_valid,
    output logic [address_width - 1:0] out_address,
    output logic [data_width    - 1:0] out_data,

    output                             busy,
    output logic                       error
);
    //------------------------------------------------------------------------

    localparam timeout_in_clk_cycles = timeout_in_seconds * clk_frequency;
    logic [$clog2 (timeout_in_clk_cycles) - 1:0] timeout_counter;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            timeout_counter <= '0;
        else if (in_valid)
            timeout_counter <= timeout_in_clk_cycles;
        else if (timeout_counter > '0)
            timeout_counter <= timeout_counter - 1'd1;

    assign busy    = (timeout_counter != '0);
    wire   timeout = (timeout_counter == 1'd1);

    //------------------------------------------------------------------------

    localparam [char_width - 1:0]
        CHAR_0  = "0",
        CHAR_9  = "9",
        CHAR_a  = "a",
        CHAR_f  = "f",
        CHAR_A  = "A",
        CHAR_F  = "F",
        CHAR_CR = 8'h0D,
        CHAR_LF = 8'h0A;

    //------------------------------------------------------------------------

    localparam nibble_width = 4;

    logic [nibble_width - 1:0] nibble;
    logic nibble_valid;
    logic nibble_error;

    always @*
    begin
       nibble       = in_char - CHAR_0;
       nibble_valid = in_valid;
       nibble_error = '0;

       if (in_char >= CHAR_0 && in_char <= CHAR_9)
           ;
       else if (in_char >= CHAR_a && in_char <= CHAR_f)
           nibble = in_char - CHAR_a + 10;
       else if (in_char >= CHAR_A && in_char <= CHAR_F)
           nibble = in_char - CHAR_A + 10;
       else if (in_char == CHAR_CR | in_char == CHAR_LF)
           nibble_valid = '0;
       else
           nibble_error = in_valid;
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            error <= '0;
        else if (timeout)
            error <= '0;
        else if (nibble_error)
            error <= '1;

    //------------------------------------------------------------------------

    localparam num_nibbles_in_data = data_width / nibble_width;

    logic [$clog2 (num_nibbles_in_data) - 1:0] nibble_counter;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
        begin
            nibble_counter <= '0;
        end
        else if (timeout)
        begin
            nibble_counter <= '0;
        end
        else if (nibble_valid)
        begin
            if (nibble_counter == num_nibbles_in_data - 1)
                nibble_counter <= '0;
            else
                nibble_counter <= nibble_counter + 1'd1;
        end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            out_valid <= '0;
        else if (timeout)
            out_valid <= '0;
        else
            out_valid <=   nibble_valid
                         & nibble_counter == num_nibbles_in_data - 1;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            out_address <= '0;
        else if (timeout)
            out_address <= '0;
        else if (out_valid)
            out_address <= out_address + num_nibbles_in_data / 2;

    always_ff @ (posedge clk)
        if (nibble_valid)
            out_data <= (out_data << nibble_width) | nibble;

endmodule
