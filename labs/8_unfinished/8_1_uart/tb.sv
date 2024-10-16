// Code your testbench here
// or browse Examples

module tb
();
  
initial begin

    `ifdef __ICARUS__
        $dumpvars;
    `endif

//   $dumpfile("dump.vcd");
//   $dumpvars();
end
  
//   string	test_name[3:0]=
//   {
//    "test_3", 
//    "test_2", 
//    "test_1", 
//    "test_0" 
//   };
string	test_name[3:0];
int fd;
int args;

  
int 	            test_id=0;

logic [15:0]        display_number;    
logic [3:0]         ar_display_number[4];
                                    
                                    

logic               test_passed=0;
logic               test_stop=0;
logic               test_timeout=0;




//top #( .is_simulation(1) ) uut( .* );

localparam clk_mhz = 50,
w_key   = 4,
w_sw    = 4,
w_led   = 4,
w_digit = 4,
w_gpio  = 100;

//------------------------------------------------------------------------

logic                   clk=0;
logic                   rst;
logic [w_key   - 1:0]   key;
logic [w_sw    - 1:0]   sw;
logic [w_led   - 1:0]   led;
logic [          7:0]   abcdefgh;
logic [w_digit - 1:0]   digit;
logic [w_gpio  - 1:0]   gpio;

logic                   uart_rx;
logic                   uart_tx;

always #10 clk = ~clk;

//------------------------------------------------------------------------

lab_top
# (
    .clk_mhz       (   clk_mhz       ),

    .w_key         (   w_key         ),
    .w_sw          (   w_sw          ),
    .w_led         (   w_led         ),
    .w_digit       (   w_digit       ),
    .w_gpio        (   w_gpio        )

    // .screen_width  (   screen_width  ),
    // .screen_height (   screen_height ),

    // .w_red         (   w_red         ),
    // .w_green       (   w_green       ),
    // .w_blue        (   w_blue        )
)
i_lab_top
(
    .clk           (   clk           ),
    .slow_clk      (   slow_clk      ),
    .rst           (   rst           ),

    .key           (   key           ),
    .sw            (   key           ),

    .led           (   led           ),

    .abcdefgh      (   abcdefgh      ),
    .digit         (   digit         ),

    // .x             (   x             ),
    // .y             (   y             ),

    // .red           (   red           ),
    // .green         (   green         ),
    // .blue          (   blue          ),

    .uart_rx       (   uart_rx       ),
    .uart_tx       (   uart_tx       ),

    .mic           (   mic           ),
    .sound         (   sound         ),

    .gpio          (   gpio          )
);



assign ar_display_number[0] = display_number[3:0];
assign ar_display_number[1] = display_number[7:4];
assign ar_display_number[2] = display_number[11:8];
assign ar_display_number[3] = display_number[15:12];

// Main process  
initial begin  

    args=-1;

    test_name[0] = "test_0";
    test_name[1] = "test_1";
    test_name[2] = "test_2";
    test_name[3] = "test_3";

    
    if( $value$plusargs( "test_id=%0d", args )) begin
        if( args>=0 && args<2 )
        test_id = args;

        $display( "args=%d  test_id=%d", args, test_id );

    end

  $display("Hello, world! test_id=%d  name: %s  ", test_id, test_name[test_id]);

  rst <= #1 1;

  #200;

  @(posedge clk);
  
  rst <= #1 0;
  
  //@(posedge clk iff test_stop | test_timeout );
  for( int ii=0; ~(test_stop || test_timeout)  ; ii++ ) begin
    @(posedge clk);
  end


  #200;

  //test_finish( test_id, test_name[test_id], test_passed, display_number[7:4] );
  test_finish( test_id, test_name[test_id], test_passed );

end

initial begin
    #260000000;
    $display();
    $display( "***************************  TIMEMOUT  ****************************"  );
    $display();
    test_timeout = 1;
end

initial begin

    test_init();

    @(negedge rst );

    case( test_id )
        0: begin
            // some action for test_id==0
            fork
                //test_seq_p0();    
                //test_seq_p1();    
                //test_seq_p2();    
                test_seq_uart_rx();
            join_any
           
            // if( display_number[3:0]==4'b1111 )  
            //     test_passed = 1;
        end

        // 1: begin
        //     // some action for test_id==1
        // end

        // 1: begin
        //     #50000000;
        //     if( display_number[3:0]==4'b0110 )  
        //         test_passed = 1;

        // end

    endcase    

    test_stop = 1;
end
  

task test_init;

    uart_rx <= 1;

    key <= '0;

endtask


`include "tb_pkg.svh"

endmodule