module multi_push_pop_fifo
# (
  parameter w = 13,  // fifo width
            d = 19,  // fifo_depth
            n = 2,   // max number of pushes or pops
            nw = $clog2 (n + 1)
)
(
  input                        clk,
  input                        rst,
  input  [nw - 1:0]            push,
  input  [n  - 1:0][w - 1:0]   push_data,
  input  [nw - 1:0]            pop,
  output [n  - 1:0][w - 1:0]   pop_data,
  output [nw - 1:0]            can_push,  // how many items can I push
  output [nw - 1:0]            can_pop
);

  // TODO: Implement the whole example
  // with testbench and FPGA demo


  localparam W_PTR = $clog2(d);

  logic [d-1:0]    [w-1:0]     buf_data;
  logic [W_PTR-1:0]            base_h, base_t ;
  logic [n-1:0]    [W_PTR-1:0] index_h, index_t;
  logic                        h_t, h_h;
  logic [W_PTR :0]             occupied, vacant;

  logic [nw - 1:0]             i_can_push;              // tmp for QuestaSim
  logic [n  - 1:0][w - 1:0]    i_pop_data;                    // tmp for QuestaSim
  logic [nw - 1:0]             i_can_pop, step_h, step_t;

//----------- push -----------------------------------------------------
  always_ff @ (posedge clk)
    if (rst) begin
      base_h <= '0;
      h_h    <= '0;
    end
    else begin
      for (int i = 0; i < n; i = i + 1)
        if ( i < step_h) buf_data[index_h[i]] <= push_data[i];          // push  пушим столько сколько  попросили но не больше чем можем
    if ((base_h + step_h) > d) begin                                  // перемешаем указатель на количество записаных элементов
          base_h <= W_PTR'(base_h + step_h - d);
          h_h <= ~h_h;                                                  // пересекли границу, изменили самый старший бит
    end
    else
      base_h <= base_h + step_h;
    end

  always_comb begin
    for (int i = 0; i < n; i = i + 1)                                      // calculating index for push
      if ((base_h+i) < d)   index_h[i] = W_PTR'(base_h + i);
      else  index_h[i] = W_PTR'(base_h + i - d );
    end

  always_comb begin
    vacant = (h_t == h_h)?W_PTR'(d - base_h + base_t):W_PTR'(base_t - base_h);
    i_can_push = (vacant > n)?(nw)'(n):(nw)'(vacant);
    step_h = (i_can_push > push)?push:can_push;                // На сколько будем шагать? сколько просят или сколько можем?
  end

  assign can_push = i_can_push;

 //----------- pop -----------------------------------------------

  assign occupied = W_PTR'(d - vacant);

  always_ff @(posedge clk)
    if (rst) begin
      base_t <= '0;
      h_t    <= '0;
    end
    else begin
      if ((base_t + step_t) > d) begin
        base_t <= (W_PTR)'(base_t - d + step_t);                           // next tail
        h_t    <= ~h_t;
      end
      else base_t <= (W_PTR)'(base_t + step_t);
  end


  always_comb begin
    i_can_pop = (occupied > n )?nw'(n):nw'(occupied);
    step_t = (i_can_pop > pop)?pop:i_can_pop;

    for (int i = 0 ; i < n; i = i + 1)
    if ((base_t+i) < d)   index_t[i] = W_PTR'(base_t + i);                           // calculating the tail index
         else  index_t[i] = W_PTR'(base_t + i - d);

    for (int i = 0; i < n; i = i + 1)                                                      //  pop data
      if ( i < step_t) i_pop_data[i] = buf_data[index_t[i]];
      else i_pop_data[i] = '0;

  end

  assign  pop_data = i_pop_data;
  assign  can_pop  = i_can_pop ;

endmodule