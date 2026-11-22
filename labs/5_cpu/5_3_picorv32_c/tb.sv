`include "config.svh"

module tb;

    localparam clk_mhz = 1,
               w_key   = 4,
               w_sw    = 8,
               w_led   = 8,
               w_digit = 8,
               w_gpio  = 100;

    //------------------------------------------------------------------------

    logic                 clk;
    logic                 rst;
    logic [w_key   - 1:0] key;
    logic [w_sw    - 1:0] sw;

    logic [w_led   - 1:0] led;
    logic [          7:0] abcdefgh;
    logic [w_digit - 1:0] digit;

    logic                 uart_rx;
    wire                  uart_tx;

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_lab_top
    (
        .clk      ( clk      ),
        .slow_clk ( clk      ),
        .rst      ( rst      ),
        .key      ( key      ),
        .sw       ( sw       ),
        .led      ( led      ),
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    ),
        .uart_rx  ( uart_rx  ),
        .uart_tx  ( uart_tx  )
    );

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;
        forever #5 clk = ~ clk;
    end

    initial
    begin
        rst     = 1'b1;
        key     = '0;
        sw      = 8'h5a;
        uart_rx = 1'b1;   // UART line idles high
        repeat (4) @ (posedge clk);
        rst = 1'b0;
    end

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        # 2_000_000;

        $finish;
    end

endmodule
