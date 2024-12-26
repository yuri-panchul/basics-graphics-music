module uart_transmitter
# (
    parameter clk_frequency = 50 * 1000 * 1000,
              baud_rate     = 115200
)
(
    input              clk,
    input              reset,
    output             tx,
    output             byte_ready, 
    input              byte_valid,
    input logic [7:0]  byte_data
);

    parameter clk_cycles_in_symbol = clk_frequency / baud_rate;

    logic [8:0]  reg_data;

    // Counter to measure distance between symbols

    logic [$clog2 (clk_cycles_in_symbol) - 1:0] counter;
    logic [$clog2 (clk_cycles_in_symbol) - 1:0] load_counter_value;
    logic load_counter;

    always_ff @ (posedge clk or posedge reset)
    begin
        if (reset)
            counter <= 0;
        else if (load_counter)
            counter <= load_counter_value;
        else if (counter != 0)
            counter <= counter - 1;
    end

    wire counter_done = counter == 1;

    // Shift register to accumulate data

    logic       shift;
    logic [8:0] shifted_1;

    always @ (posedge clk or posedge reset)
    begin
        if (reset)
        begin
            shifted_1 <= 0;
        end
        else if (shift)
        begin
            if (shifted_1 == 0)
                shifted_1 <= 9'b100000000;
            else
                shifted_1 <= shifted_1 >> 1;
        end
        else if (byte_ready && byte_valid)
        begin
            shifted_1 <= 0;
        end
    end

    always @ (posedge clk or posedge reset)
        if( reset )
            reg_data <= '1;
        else if( byte_ready && byte_valid )
            reg_data <= { byte_data, 1'b0 };
        else if (shift)
            reg_data <= { 1'b1, reg_data [8:1] };

    assign tx = reg_data[0];

    logic idle, idle_r;

    always @*
    begin
        idle  = idle_r;
        shift = 0;

        load_counter        = 0;
        load_counter_value  = 0;

        if (idle)
        begin
            if (byte_ready && byte_valid)
            begin
                load_counter       = 1;
                load_counter_value = clk_cycles_in_symbol;

                idle = 0;
            end
        end
        else if (counter_done)
        begin
            shift = 1;

            if (shifted_1[0]) 
            begin
                idle = 1; 
            end else
            begin
                load_counter       = 1;
                load_counter_value = clk_cycles_in_symbol;
            end
        end
        // else if (shifted_1[0])
        // begin
        //     idle = 1;
        // end
    end

    always @ (posedge clk or posedge reset)
    begin

        
        if (reset)
            idle_r <= 1;
        else
            idle_r <= idle;
    end

    assign byte_ready = idle_r;

endmodule
