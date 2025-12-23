// -----------------------------------------------------------------
// Original APS course solution didn't include this module.
//
// Added and modified from:
// https://github.com/ButterSus/APS/blob/master/Labs/Extra._Peripheral_units/rtl/peripheral/util/custom_debouncer.sv
// -----------------------------------------------------------------

module debouncer #(
    parameter int COUNT_MAX = 10000,  // For 10 MHz, it will be 1 ms
    parameter int WIDTH     = 1
) (
    input  logic               clk_i,
    input  logic               rst_i,
    input  logic [WIDTH - 1:0] data_i,
    output logic [WIDTH - 1:0] data_o
);

  logic [31:0] counter;
  logic [WIDTH - 1:0] data_sync, data_r;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      counter <= 32'd0;
      data_r  <= data_i;
      data_o  <= data_i;
    end else begin
      if (data_i == data_r) begin
        if (counter < COUNT_MAX) counter <= counter + 1;
        else data_o <= data_r;
      end else begin
        data_r <= data_i;
        counter <= 32'd0;
      end
    end
  end

endmodule
