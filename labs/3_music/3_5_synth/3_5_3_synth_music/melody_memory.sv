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

    // We use 1/8 part of beat as a unit to track time in this design 
    localparam TPB = (CLK_MHZ * 30) * (1_000_000 / BPM);

    `include "music_imperial_march.svh"

    logic          [$clog2(TPB)-1:0] tick_cnt_ff;
    logic                      [3:0] bit_cnt_ff;
    logic [$clog2(MEMORY_DEPTH)-1:0] quant_cnt_ff;

    logic [3:0] bits_to_switch;

    // pending quant driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        quant_cnt_ff <= 'b0;
      end
      else begin
        if ( bit_cnt_ff >= bits_to_switch ) begin
          quant_cnt_ff <= quant_cnt_ff + 'b1;
        end
        else if ( quant_cnt_ff >= MEMORY_DEPTH ) begin
          quant_cnt_ff <= 'b0;
        end
      end
    end

    // bit counter driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        bit_cnt_ff <= 'b0;
      end
      else begin
        if ( bit_cnt_ff >= bits_to_switch ) begin
          bit_cnt_ff <= 'b0;
        end
        else if ( tick_cnt_ff >= TPB ) begin
          bit_cnt_ff <= bit_cnt_ff + 'b1;
        end
      end
    end

    // tick counter driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        tick_cnt_ff <= 'b0;
      end
      else begin
        if ( tick_cnt_ff >= TPB ) begin
          tick_cnt_ff <= 'b0;
        end
        else begin
          tick_cnt_ff <= tick_cnt_ff + 'b1;
        end
      end
    end

    assign enable_o       = melody_rom [10];
    assign bits_to_switch = melody_rom [9:6];
    assign note_o         = melody_rom [5:2];
    assign octave_o       = melody_rom [1:0];

endmodule
