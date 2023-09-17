`include "config.svh"

module tb;

    localparam clk_mhz = 1,
               w_key   = 4,
               w_sw    = 8,
               w_led   = 8,
               w_digit = 8,
               w_gpio  = 20;

    //------------------------------------------------------------------------

    logic               clk;
    logic               rst;
    logic [w_key - 1:0] key;
    logic [w_sw  - 1:0] sw;
    wire  [w_led - 1:0] led;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_top
    (
        .clk  ( clk ),
        .rst  ( rst ),
        .key  ( key ),
        .sw   ( sw  ),
        .led  ( led )
    );

    //------------------------------------------------------------------------

    logic sel, a, b, result, expected;

    task check ();

        // Back-box testing - checking the output

        result   = led [0];
        expected = sel ? a : b;

        if (result != expected)
            $display ("Mismatch: %b ? %b : %b. expected: %b actual: %b",
                sel, a, b, expected, result);

        // White-box testing - checking XMR (external module reference)

        for (int i = 0; i < $bits (i_top.all_muxes); i ++)
        begin
            result = i_top.all_muxes [i];

            if (result != expected)
                $display ("Mismatch in mux %0d: %b ? %b : %b. expected: %b actual: %b",
                    sel, a, b, expected, result);
        end

    endtask

    //------------------------------------------------------------------------

    // The stimulus generation

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        // Exhaustive direct testing aka brute force testing

        for (int isel = 0; isel <= 1; isel ++)
        for (int ia   = 0; ia   <= 1; ia   ++)
        for (int ib   = 0; ib   <= 1; ib   ++)
        begin
             sel = 1' ( isel );
             a   = 1' ( ia   );
             b   = 1' ( ib   );

             key <= w_key' ({ sel, a, b });
             sw  <= $urandom ();  // The result should not depend on sw

             # 10

             check ();
        end

        // Another way of doing it

        for (int i = 0; i < 8; i ++)
        begin
             key <= w_key'   (i);
             sw  <= $urandom ();

             # 10

             sel = key [2];
             a   = key [1];
             b   = key [0];

             check ();
        end

        // Randomized testing

        repeat (8)
        begin
             key <= $urandom ();
             sw  <= $urandom ();

             # 10

             sel = key [2];
             a   = key [1];
             b   = key [0];

             check ();
        end

        $finish;
    end

endmodule
