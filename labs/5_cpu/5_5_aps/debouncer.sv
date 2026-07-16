module debouncer #(
    parameter int unsigned DEBOUNCE_CYCLES = 1000
)(
    input  logic clk_i,
    input  logic rst_i,

    input  logic din_i,
    output logic dout_o
);

  //----------------------------------------------------------------------
  // Пересинхронизация входа
  //----------------------------------------------------------------------

  logic sync_ff1;
  logic sync_ff2;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      sync_ff1 <= 1'b0;
      sync_ff2 <= 1'b0;
    end
    else begin
      sync_ff1 <= din_i;
      sync_ff2 <= sync_ff1;
    end
  end

  //----------------------------------------------------------------------
  // Подавитель дребезга
  //----------------------------------------------------------------------
  logic [$clog2(DEBOUNCE_CYCLES)-1:0] counter;

    always_ff @(posedge clk_i) begin
      if (rst_i) begin
        dout_o  <= 1'b0;
        counter <= '0;
      end
      else begin
        // Вход совпадает со стабильным состоянием
        if (sync_ff2 == dout_o) begin
          counter <= '0;
        end
        // Вход отличается — проверяем, удерживается ли он достаточно долго
        else begin
          if (counter == DEBOUNCE_CYCLES-1) begin
            dout_o  <= sync_ff2;
            counter <= '0;
          end
          else begin
            counter <= counter + 1'b1;
          end
        end
      end
    end
endmodule
