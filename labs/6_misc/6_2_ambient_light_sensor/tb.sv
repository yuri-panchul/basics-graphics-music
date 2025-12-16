`include "config.svh"

module tb;
    localparam clk_mhz       = 27,
               pixel_mhz     = 25,

               // We use sw as an alias to key on Tang Nano 9K,
               // either with or without TM1638

               w_key         = 2,
               w_sw          = 0,
               w_led         = 6,
               w_digit       = 0,
               w_gpio        = 10,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 8,
               w_green       = 8,
               w_blue        = 8,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height );

    //------------------------------------------------------------------------

    logic       clk;
    logic       rst;

    wire [w_gpio - 1:0] gpio;

    //------------------------------------------------------------------------

   wire    sclk, cs;
   logic   sdo;
   logic [7:0] test_data = 8'hAB;

   assign sclk = gpio[5];
   assign cs = gpio[4];
   assign gpio[3] = sdo;

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
        .clk      ( clk ),
        .rst      ( rst ),
        .gpio     ( gpio )
    );

    //------------------------------------------------------------------------

   // 27 MHz clock
    initial
    begin
        clk = 1'b0;

        forever
            # 19 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

       @(negedge rst);
       sdo = 'x;

       /** emulate approximately what the ADC does */
       @(negedge cs);

       // leading zeros
       sdo = 1'b0;
       @(negedge sclk);
       @(negedge sclk);
       @(negedge sclk);
       // data
       @(negedge sclk);
       sdo = test_data[7];
       @(negedge sclk);
       sdo = test_data[6];
       @(negedge sclk);
       sdo = test_data[5];
       @(negedge sclk);
       sdo = test_data[4];
       @(negedge sclk);
       sdo = test_data[3];
       @(negedge sclk);
       sdo = test_data[2];
       @(negedge sclk);
       sdo = test_data[1];
       @(negedge sclk);
       sdo = test_data[0];
       // trailing zeros
       @(negedge sclk);
       $display("Done transmitting data!");
       sdo = 1'b0;
       @(negedge sclk);
       @(negedge sclk);
       @(negedge sclk);
       @(negedge sclk);

       @(posedge cs);

       @(posedge clk);
       @(posedge clk);

       @(negedge clk);

       @(posedge clk);
       @(posedge clk);

       @(negedge clk);
        $finish;
    end

   initial begin
      #100000;
      $display("FATAL: Simulation timeout reached at time %0t", $time);
      $finish;
   end
endmodule
