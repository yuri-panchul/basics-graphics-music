/* Adapter for ADC081S021
* https://www.ti.com/lit/ds/symlink/adc081s021.pdf?HQS=dis-dk-null-digikeymode-dsf-pf-null-wwe&ts=1765789819202&ref_url=https%253A%252F%252Fwww.ti.com%252Fgeneral%252Fdocs%252Fsuppproductinfo.tsp%253FdistId%253D10%2526gotoUrl%253Dhttps%253A%252F%252Fwww.ti.com%252Flit%252Fgpn%252Fadc081s021
*/

module adc_adapter
# (
  // This adapter was designed for for 1MHz ADC clk frequency a 27MHz input clock. Weird timing violations may start happening if you modify these parameters. For instance, increasing ADC frequency, such as violating t_{quiet} (cs pulse width)
  parameter CLK_FREQ_MHZ = 27,
  parameter ADC_CLK_FREQ_HZ = 1_000_000
)
(
    input        clk_i,
    input        rst_i,

    /** ADC pins */
    output logic sclk_o,
    output logic cs_o,
    input logic  sdo_i,

    output logic [7:0] data_o, // concatenated output of adc; extra zero padding is omitted

    /** Ready-Valid interface */
    output       logic valid_o,     // signals high when data_o is valid for one clk_i cycle
    input        ready_i,     // X
    input        valid_i,     // X
    output       logic ready_o      // Always 1
);
   localparam adc_cycles_per_sample_lp = 16;

   logic      is_sampling_l;
   // The MSB represents when we should stop sampling, so one extra cycle is used to pulse CS high again. At 1 MHz, 1 cycle period is sufficient to meet t_quiet (50ns) timing requirement.
   logic [$clog2(adc_cycles_per_sample_lp):0] adc_cycl_ctr_r;
   // 3 leading zeros + 8 data (big endian) + 4 trailing zeros
   logic [14:0]                   data_r;
   logic                          has_signaled_valid_r;

   assign ready_o = 1'b1;

   slow_clk_gen #(.fast_clk_mhz(CLK_FREQ_MHZ), .slow_clk_hz(ADC_CLK_FREQ_HZ))
     slow_clk_inst
       (.clk(clk_i),
        .rst(rst_i),
        .slow_clk(sclk_o));

   assign is_sampling_l = !adc_cycl_ctr_r[$clog2(adc_cycles_per_sample_lp)];
   assign cs_o = adc_cycl_ctr_r[$clog2(adc_cycles_per_sample_lp)];
   assign data_o = data_r[11:4];

   // data is sampled at negative edge, and we reading at positive edge
   always_ff @(negedge sclk_o or posedge rst_i) begin
      if (rst_i) begin
         adc_cycl_ctr_r <= {1'b1, {$clog2(adc_cycles_per_sample_lp){'0}}};
      end else begin
            if (adc_cycl_ctr_r[$clog2(adc_cycles_per_sample_lp)]) begin
                adc_cycl_ctr_r <= '0;
            end else begin
                adc_cycl_ctr_r <= adc_cycl_ctr_r + 1;
            end
      end
   end

   always_ff @(posedge sclk_o or posedge rst_i) begin
      if (rst_i) begin
            data_r <= '0;
      end
      else begin
            data_r <= data_r;
            if (is_sampling_l) begin
                data_r[0] <= sdo_i;
                data_r[14:1] <= data_r[13:0];
             end
      end
   end

   // output is signaled valid on one clk_i cycle only on full sample read
   always_ff @(posedge clk_i or posedge rst_i) begin
      if (rst_i) begin
         valid_o <= '0;
         has_signaled_valid_r <= '0;
      end else begin
         if (adc_cycl_ctr_r[$clog2(adc_cycles_per_sample_lp)] && !has_signaled_valid_r) begin
            valid_o <= 1'b1;
            has_signaled_valid_r <= 1'b1;
         end else begin
            valid_o <= '0;
            has_signaled_valid_r <= has_signaled_valid_r;
            if (!adc_cycl_ctr_r[$clog2(adc_cycles_per_sample_lp)]) begin
               has_signaled_valid_r <= 1'b0;
            end
         end
      end
   end


endmodule
