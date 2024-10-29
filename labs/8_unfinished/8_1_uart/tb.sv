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
  
string	test_name[3:0];
int fd;
int args;

  
int 	            test_id=0;
logic               test_passed=0;
logic               test_stop=0;
logic               test_timeout=0;

int                 test_uart_p1=0;
int                 test_uart_p2=0;

localparam clk_mhz = 50,
w_key   = 4,
w_sw    = 4,
w_led   = 4,
w_digit = 4,
w_gpio  = 100,
screen_width  = 640,
screen_height = 480,
w_x           = $clog2 ( screen_width  ),
w_y           = $clog2 ( screen_height ),
w_red         = 4,
w_green       = 4,
w_blue        = 4;


//------------------------------------------------------------------------

logic                   clk=0;
logic                   rst;
logic [w_key   - 1:0]   key;
logic [w_sw    - 1:0]   sw;
logic [w_led   - 1:0]   led;
logic [          7:0]   abcdefgh;
logic [w_digit - 1:0]   digit;
logic [w_gpio  - 1:0]   gpio;
logic [w_x     - 1:0]   x;
logic [w_y     - 1:0]   y;
logic [w_red   - 1:0]   red;
logic [w_green - 1:0]   green;
logic [w_blue  - 1:0]   blue;
logic [         23:0]   mic;
logic [         15:0]   sound;
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
    .w_gpio        (   w_gpio        ),
    .screen_width  (   screen_width  ),
    .screen_height (   screen_height ),
    .w_red         (   w_red         ),
    .w_green       (   w_green       ),
    .w_blue        (   w_blue        )
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

    .x             (   x             ),
    .y             (   y             ),
    .red           (   red           ),
    .green         (   green         ),
    .blue          (   blue          ),

    .uart_rx       (   uart_rx       ),
    .uart_tx       (   uart_tx       ),

    .mic           (   mic           ),
    .sound         (   sound         ),

    .gpio          (   gpio          )
);


// Main process  
initial begin  

    args=-1;

    test_name[0] = "test_uart";
    test_name[1] = "test_1";
    test_name[2] = "test_2";
    test_name[3] = "test_3";

    if( $value$plusargs( "test_id=%0d", args )) begin
        if( args>=0 && args<2 )
        test_id = args;
        $display( "args=%d  test_id=%d", args, test_id );
    end

  $display("test_id=%d  name: %s  ", test_id, test_name[test_id]);

  rst <= #1 1;

  #200;

  @(posedge clk);
  
  rst <= #1 0;
  
  //@(posedge clk iff test_stop | test_timeout ); // this code don't work in the Icarus verilog
  for( int ii=0; ~(test_stop || test_timeout)  ; ii++ ) begin
    @(posedge clk);
  end

  #200;

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

    #200;

    case( test_id )
        0: begin
            // some action for test_id==0
            fork
                test_seq_key0();    
                test_seq_key1();    
                //test_seq_uart_p0();
                test_seq_uart_p1();
                test_seq_uart_p2();
            join

            if(     1==test_uart_p1 
                 && 1==test_uart_p2
              )
                     test_passed = 1;
        end

        // 1: begin
        //     // some action for test_id==1
        // end

    endcase    

    test_stop = 1;
end
  



`include "tb_pkg.svh"

endmodule