/* -----------------------------------------------------------------------------
* Project Name   : Architectures of Processor Systems (APS) lab work
* Organization   : National Research University of Electronic Technology (MIET)
* Department     : Institute of Microdevices and Control Systems
* Author(s)      : Andrei Solodovnikov
* Email(s)       : hepoh@org.miet.ru

See https://github.com/MPSU/APS/blob/master/LICENSE file for licensing details.
* ------------------------------------------------------------------------------
*/
module clock_divider #(
  parameter int unsigned FAST_CLK_FREQ = 50_000_000,
  parameter int unsigned SLOW_CLK_FREQ = 10_000_000
)(
  input  logic clk_i,
  input  logic aresetn_i,

  output logic clk_o,
  output logic rst_o
);

  localparam int unsigned DIV = FAST_CLK_FREQ / SLOW_CLK_FREQ;

  /*===============
    Делитель клока
    ===============
  */

  /*
    Проверка параметров:
    - FAST_CLK_FREQ должна быть кратна SLOW_CLK_FREQ
    - FAST_CLK_FREQ должна быть выше SLOW_CLK_FREQ
  */
  if (FAST_CLK_FREQ % SLOW_CLK_FREQ != 0)
    fast_clk_is_not_multiple_of_slow_clk err1();

  if (FAST_CLK_FREQ <= SLOW_CLK_FREQ)
    fast_clk_must_be_greater_than_slow_clk err2();

  localparam int unsigned HIGH_CYCLES = (DIV + 1) / 2; // ceil(DIV/2)
  localparam int unsigned LOW_CYCLES  = DIV / 2;       // floor(DIV/2)

  localparam int unsigned DIV_WIDTH = $clog2(DIV);

  logic [DIV_WIDTH-1:0] cnt;

  always_ff @(posedge clk_i or negedge aresetn_i) begin
    if (!aresetn_i) begin
      cnt   <= '0;
      clk_o <= 1'b1;
    end
    else begin
      if (clk_o) begin
        if (cnt == HIGH_CYCLES-1) begin
          cnt   <= '0;
          clk_o <= 1'b0;
        end
        else
          cnt <= cnt + 1'b1;
      end
      else begin
        if (cnt == LOW_CYCLES-1) begin
          cnt   <= '0;
          clk_o <= 1'b1;
        end
        else
          cnt <= cnt + 1'b1;
      end
    end
  end


  /*===================
    Буферизация сброса
    ===================
  */

  // Поскольку в системе используется синхронный сброс,
  // он не будет виден, ведь пока удерживается сброс,
  // генерируемый клок находится в нуле
  // Получается что входной сброс никогда не будет
  // зарегистрирован синхронной логикой.
  // Решением является задержать буферизовать сброс, чтобы
  // он снялся уже после генерации первого такта.
  // Кроме того, входной сброс необходимо синхронизировать.

  logic [1:0] arstn_sync;
  logic rstn_synced;
  assign rstn_synced = arstn_sync[1];

  always_ff @(posedge clk_i or negedge aresetn_i) begin
    if(!aresetn_i) begin
      arstn_sync <= 2'b0;
    end
    else begin
      arstn_sync <= {arstn_sync[0], 1'b1};
    end
  end

  logic [3:0] sys_rstn_buf;
  assign rst_o = !sys_rstn_buf[3];

  always_ff @(posedge clk_o or negedge rstn_synced) begin
    if(!rstn_synced) begin
      sys_rstn_buf <= 2'b0;
    end
    else begin
      sys_rstn_buf <= {sys_rstn_buf[2:0], 1'b1};
    end
  end

endmodule