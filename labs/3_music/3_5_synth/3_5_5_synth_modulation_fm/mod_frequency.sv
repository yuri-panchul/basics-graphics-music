module mod_frequency(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [15:0] freq_i,
  output logic [7:0]  sample_data_o
);

  logic [7:0] modulation_data;
  logic [7:0] sample_data;

  logic [15:0] modulation_freq;
  assign modulation_freq = freq_i >> 7;

  audio_triangle i_freq_mod(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (modulation_freq),
    .sample_data_o (modulation_data)
  );

  logic [15:0] carrier_freq;

  assign carrier_freq = 1000 + (modulation_data << 4);

  audio_sine i_carrier(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (carrier_freq),
    .sample_data_o (sample_data)
  );


  assign sample_data_o = sample_data;

endmodule
