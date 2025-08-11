`include "config.svh"

module tb;

  localparam  CLK_PERIOD = 10;
  localparam  END_TIME   = 5000;
  localparam  MAX_DAT    = 254;

  localparam w = 8;                  // fifo width
  localparam d = 19;                 // fifo_depth
  localparam n = 4;                  // max number of pushes or pops
  localparam nw = $clog2 (n + 1);

//---- variables for modules -------------------------------------------

  logic  [nw - 1:0]          push;
  logic  [n  - 1:0][w - 1:0] push_data;
  logic  [nw - 1:0]          pop;
  logic  [n  - 1:0][w - 1:0] pop_data;
  logic  [nw - 1:0]          can_push;   // how many items can I push
  logic  [nw - 1:0]          can_pop;

// ------- the assistive variables  ------------------------------------
  logic  [w - 1:0]           res_exp, res, dat_0;
  logic  [nw - 1:0]          n_pop, n_push, n_pop_s;
  logic  [n  - 1:0][w - 1:0] in_data, pop_data_s;
  logic                      clk, rst;
  int queue_in[$], queue_out[$];

//------------------  drived clk ---------------------------------------
  initial
    begin
        clk <= '1;
        forever
        begin
            # (CLK_PERIOD/2);
             clk <= ~ clk;
        end
    end

  initial begin

    # END_TIME
    $display ("FAIL: TIMEOUT" );
    $finish;

  end

// ----- the assistive process ------------------------------------
  int size_free;
  logic vld, vld_s;

  always_ff @(posedge clk) begin
      vld_s        <= vld;
      pop_data_s   <= pop_data;
      n_pop_s      <= n_pop;
  end

  always_ff @(posedge clk)
    if (rst) size_free <= d;
  else
    size_free = size_free + pop - push;

  always_comb begin
    pop = (can_pop < n_pop) ? '0 : n_pop;
    vld = (can_pop < n_pop) ? 1'h0 : 1'h1;
  end

// ---- instanse DUT---------------------------------------------

  multi_push_pop_fifo #(w, d, n) dut(.*);

//----- pop process ----------------------------------------------------------

  initial begin
    wait(~rst);
    forever begin
      @(posedge clk);
      if (vld_s)begin
        for(int i = 0; i < n_pop_s; i = i+1) begin       // save result to quene_out
         if ($urandom_range(100) < 0 )                   // introducing an error
           queue_out.push_back(pop_data_s[i]+1);
         else
           queue_out.push_back(pop_data_s[i]);
         end
      end
    end
  end

// -------- CHEK PROC -----------------------------
  initial begin
  wait(~rst);
  forever begin
    @(posedge clk);
    while (queue_out.size () > 0)begin
      `ifdef __ICARUS__
        res_exp <= queue_in [0];
        queue_in.delete (0);
        res <= queue_out [0];
       queue_out.delete (0);
       `else
      for (int i = 0;  i < pop; i = i + 1) begin
        res_exp <= queue_in.pop_front ();
        res     <= queue_out.pop_front ();
        $write(" res_exp = %h, res = %h \n", res_exp, res);
      end
      `endif

      @(posedge clk);
      if (res !== res_exp) begin
         $display ("FAIL : res mismatch. Expected %d, actual %d",  res_exp, res);
      @(posedge clk);

       $finish;
       end
     end
   end
end


//------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif


    //--------------------------------------------------------------------
    // Reset
    queue_out = {};
    queue_in  = {};
    pop  <= '0;
    push <= '0;
    rst <= 'x;
    pop  = '0;
    push = '0;
    repeat (3) @ (posedge clk);
    rst <= '1;
    repeat (3) @ (posedge clk);
    rst <= '0;


    //----------- push 1  pop 1 -------------------------------------
    n_pop  <= 3'h1;
    n_push <= 3'h1;

    repeat (5) begin
      @ (posedge clk);
      if (size_free >= (2 * n_push))begin                           // if there is room for two maximum volume records, then we prepare and write the data.
        dat_0 = $urandom_range(MAX_DAT);                            // In any case, one entry will be made.
        queue_in.push_back(dat_0);
        in_data[0] = dat_0;
        push_data <= in_data;
        push <= n_push;
      end
      else
       push <= '0;
    end

//----------- push 1  pop 4 -------------------------------------
    n_pop  <= 3'h4;
    n_push <= 3'h1;

    repeat (3) begin
      @ (posedge clk);
      if (size_free >= (2 * n_push))begin
        for(int i = 0; i < n_push; i = i+1)begin
          dat_0 = $urandom_range(MAX_DAT);
          queue_in.push_back(dat_0);
          in_data[i] = dat_0;
        end
        push_data <= in_data;
        push <= n_push;
      end
      else
      push <= '0;
    end


 //----------- push 4  pop 1 -------------------------------------
    n_pop  <= 3'h1;
    n_push <= 3'h4;

    repeat (3) begin
      @ (posedge clk);
      if (size_free >= (2 * n_push))begin
        for(int i = 0; i < n_push; i = i+1)begin
          dat_0 = $urandom_range(MAX_DAT);
          queue_in.push_back(dat_0);
          in_data[i] = dat_0;
        end
        push_data <= in_data;
        push <= n_push;
      end
      else
      push <= '0;
    end


    //--------------------------------------------------------------------
    // Random stimuli
    repeat (3*d) begin
      n_pop  <= $urandom_range(n,0);
      n_push <= $urandom_range(n,0);
      @ (posedge clk);
      if (size_free >= (2 * n_push))begin
        for(int i = 0; i < n_push; i = i+1)begin
          dat_0 = $urandom_range(MAX_DAT);
          queue_in.push_back(dat_0);
          in_data[i] = dat_0;
        end
        push_data <= in_data;
        push <= n_push;
      end
      else
      push <= '0;
    end

    repeat(d) @(posedge clk);

    $display ("PASS  " );

    //--------------------------------------------------------------------
        $finish;

 end

endmodule
