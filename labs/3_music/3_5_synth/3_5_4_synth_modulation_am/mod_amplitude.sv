module mod_amplitude(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [15:0] freq_i,
  output logic [7:0]  sample_data_o
);

  logic [7:0] amplitude;
  logic [7:0] sample_data;

  logic [15:0] ampl_mod_freq;
  assign ampl_mod_freq = freq_i >> 7;

  audio_triangle i_ampl_mod(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (ampl_mod_freq),
    .sample_data_o (amplitude)
  );


  audio_sine i_carrier(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_data)
  );

  logic [15:0] ampl_modulated_sample;

  assign ampl_modulated_sample = (amplitude * sample_data);

  assign sample_data_o = ampl_modulated_sample >> 8;

endmodule
