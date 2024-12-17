module audio_channel
(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        en_i,
  input  logic [2:0]  gen_sel_i,
  input  logic [15:0] freq_i,
  input  logic [7:0]  volume_i,
  output logic [7:0]  sample_data_o
);

  localparam SEL_SQUARE   = 3'd0;
  localparam SEL_SAW      = 3'd1;
  localparam SEL_SAW_INV  = 3'd2;
  localparam SEL_TRIANGLE = 3'd3;
  localparam SEL_SINE     = 3'd4;
  localparam SEL_NOISE    = 3'd5;

  logic [7:0] sample_mux;

  logic [7:0] sample_square;
  logic [7:0] sample_saw;
  logic [7:0] sample_saw_inv;
  logic [7:0] sample_triangle;
  logic [7:0] sample_sine;
  logic [7:0] sample_noise;

  logic [15:0] sample_volume_applied;

  logic [7:0]  sample_final;


  audio_square i_square_gen(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_square)
  );

  audio_saw i_saw_gen(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_saw)
  );

  audio_saw_inv i_saw_inv_gen(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_saw_inv)
  );

  audio_triangle i_triangle_gen(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_triangle)
  );

  audio_sine i_sine_gen(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_sine)
  );

  audio_noise i_noise_gen(
    .clk_i         (clk_i),
    .rst_i         (rst_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_noise)
  );


  always_comb begin
    case(gen_sel_i)
      SEL_SQUARE:   sample_mux = sample_square;
      SEL_SAW:      sample_mux = sample_saw;
      SEL_SAW_INV:  sample_mux = sample_saw_inv;
      SEL_TRIANGLE: sample_mux = sample_triangle;
      SEL_SINE:     sample_mux = sample_sine;
      SEL_NOISE:    sample_mux = sample_noise;
      default:      sample_mux = sample_square;
    endcase
  end

  assign sample_volume_applied = sample_mux * volume_i;
  assign sample_final          = sample_volume_applied >> 8;

  assign sample_data_o = {8{en_i}} & sample_final;

endmodule
