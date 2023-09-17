`include "config.svh"

module tb;

    localparam clk_mhz = 1,
               w_key   = 4,
               w_sw    = 8,
               w_led   = 8,
               w_digit = 8,
               w_gpio  = 20;

    //------------------------------------------------------------------------

    logic       clk;
    logic       rst;
    logic [3:0] key;
    logic [7:0] sw;

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
        .clk ( clk ),
        .rst ( rst ),
        .key ( key ),
        .sw  ( sw  )
    );

    //------------------------------------------------------------------------

    logic sel, a, b, result, expected;

    task check ()

        // Back-box testing - checking the output

        if (led

        // White-box testing - checking XMR (external module reference)

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
             sel = 1'b ( isel );
             a   = 1'b ( ia   );
             b   = 1'b ( ib   );

             key <= w_key' ({ sel, a, b });
             sw  <= $urandom ();

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
