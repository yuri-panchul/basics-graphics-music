/*****************************************************************************************/
/* Console Output Stub                                                                   */
/*****************************************************************************************/
module sim_serial_top (bufr_done, bufr_empty, bufr_full, bufr_ovr, rx_rdata, ser_clk, ser_txd,
                       cks_mode, clkp, div_rate, ld_wdata, rd_rdata, s_reset, ser_rxd, tx_wdata);

  input         cks_mode;
  input         clkp;
  input         ld_wdata;
  input         rd_rdata;
  input         s_reset;
  input         ser_rxd;
  input   [7:0] tx_wdata;
  input  [11:0] div_rate;

  output        bufr_done;
  output        bufr_empty;
  output        bufr_full;
  output        bufr_ovr;
  output        ser_clk;
  output        ser_txd;
  output  [7:0] rx_rdata;


  reg           bufr_done;
  reg           bufr_empty;
  reg           bufr_full;
  reg           bufr_ovr;
  reg           ser_clk;
  reg           ser_txd;
  reg    [7:0]  rx_rdata;

initial $write("Serial port simulation used \n");

always @(posedge clkp) begin
    if (s_reset) begin
      bufr_done  <= 1'b1;
      bufr_empty <= 1'b1;
      bufr_full  <= 1'b0;
      bufr_ovr   <= 1'b0;
      rx_rdata   <= 8'h00;
      ser_clk    <= 1'b0;
      ser_txd    <= 1'b1;
    end
    else if (!s_reset && ld_wdata && (tx_wdata != 8'h00)) begin
          if (tx_wdata >= 8'h20 && tx_wdata <= 8'h7e)
            $write("%c", tx_wdata);
          else if (tx_wdata == 8'h0a || tx_wdata == 8'h0d)
            $write("%c", tx_wdata);
          else
            $write("[0x%02h]", tx_wdata);
    end
end
endmodule