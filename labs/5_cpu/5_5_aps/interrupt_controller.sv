module interrupt_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic [15:0] irq_req_i,
  input  logic [15:0] mie_i,
  input  logic        mret_i,

  output logic [15:0] irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

logic exc_h, irq_h;
logic exc_set, exc_reset, irq_set, irq_reset;
logic exc_or, exc_and, irq_or, irq_and;

assign exc_set      = exception_i;
assign exc_reset    = mret_i;

assign exc_or       = exc_set | exc_h;
assign exc_and      = ~exc_reset & exc_or;

assign irq_set      = irq_o;
assign irq_reset    = ~exc_or & mret_i;

assign irq_or       = irq_set | irq_h;
assign irq_and      = ~irq_reset & irq_or;

daisy_chain dc(
  .*,
  .masked_irq_i(irq_req_i & mie_i),
  .irq_ret_i(exc_reset & ~exc_or),
  .ready_i(!(exc_or | irq_h))
);

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    exc_h <= 1'b0;
  end
  else begin
    exc_h <= exc_and;
  end
end

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    irq_h <= 1'b0;
  end
  else begin
    irq_h <= irq_and;
  end
end

endmodule
