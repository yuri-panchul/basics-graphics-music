module melody_memory #(
  CLK_MHZ      = 50,
  BPM          = 120
) (
  input  logic    clk_i,
  input  logic    rst_i,
  
  output logic [3:0] note_o, // C, Cd, D, Dd, E, F, Fd, G, Gd, A, Ad, B
  output logic [1:0] octave_o, // THIRD, SECOND, FIRST, SMALL
  output logic       enable_o
);

    localparam TPB = (CLK_MHZ * 30) * (1_000_000 / BPM);

    `include "music_imperial_march.svh"

    logic          [$clog2(TPB)-1:0] tick_cnt;
    logic                      [3:0] bit_cnt;
    logic [$clog2(MEMORY_DEPTH)-1:0] quant_cnt;

    logic [3:0] bits_to_switch;

    logic [3:0] note;
    logic [1:0] octave;
    logic       enable;

    // pending quant driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        quant_cnt <= 'b0;
      end
      else begin
        enable         <= melody_rom [10];
        bits_to_switch <= melody_rom [9:6];
        note           <= melody_rom [ 5:2];
        octave         <= melody_rom [ 1:0];
        if ( bit_cnt >= bits_to_switch ) begin
          quant_cnt <= quant_cnt + 'b1;
        end
        else if ( quant_cnt >= MEMORY_DEPTH ) begin
          quant_cnt <= 'b0;
        end
      end
    end

    // bit counter driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        bit_cnt <= 'b0;
      end
      else begin
        if ( bit_cnt >= bits_to_switch ) begin
          bit_cnt <= 'b0;
        end
        else if ( tick_cnt >= TPB ) begin
          bit_cnt <= bit_cnt + 'b1;
        end
      end
    end

    // tick counter driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        tick_cnt <= 'b0;
      end
      else begin
        if ( tick_cnt >= TPB ) begin
          tick_cnt <= 'b0;
        end
        else begin
          tick_cnt <= tick_cnt + 'b1;
        end
      end
    end

    assign note_o = note;
    assign octave_o = octave;
    assign enable_o = enable;

endmodule
