module audio_noise(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [15:0] freq_i,
  output logic [7:0]  sample_data_o
);

  // Frequency counter
  localparam FREQ_CNT_WIDTH = 19;

  logic [FREQ_CNT_WIDTH-1:0] freq_counter_ff;
  logic [FREQ_CNT_WIDTH-1:0] freq_counter_next;

  assign freq_counter_next = freq_counter_ff + freq_i;

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      freq_counter_ff <= '0;
    else
      freq_counter_ff <= freq_counter_next;
  end

  logic freq_msb_dly_ff;

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      freq_msb_dly_ff <= '0;
    else
      freq_msb_dly_ff <= freq_counter_ff[FREQ_CNT_WIDTH-1];
  end

  logic freq_ofl;
  assign freq_ofl = ~freq_counter_ff[FREQ_CNT_WIDTH-1] & freq_msb_dly_ff;


  // Based on SID noise generator
  // http://www.sidmusic.org/sid/sidtech5.html

  logic [22:0] noise_shiftreg_ff;
  logic [22:0] noise_shiftreg_next;
  logic [7:0] noise_output;

  localparam NOISE_SHREG_INIT = 22'h7FFFF8;

  // Shift register left
  // LSB is (bit22 ^ bit17)
  assign noise_shiftreg_next = {noise_shiftreg_ff[21:0],
                               (noise_shiftreg_ff[22] ^ noise_shiftreg_ff[17])};

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      noise_shiftreg_ff <= NOISE_SHREG_INIT;
    else if (freq_ofl)
      noise_shiftreg_ff <= noise_shiftreg_next;
  end

  // Select specific shift register bits for 8-bit output
  assign noise_output = {noise_shiftreg_ff[22],
                         noise_shiftreg_ff[20],
                         noise_shiftreg_ff[16],
                         noise_shiftreg_ff[13],
                         noise_shiftreg_ff[11],
                         noise_shiftreg_ff[7],
                         noise_shiftreg_ff[4],
                         noise_shiftreg_ff[2]};

  assign sample_data_o = noise_output;

endmodule
