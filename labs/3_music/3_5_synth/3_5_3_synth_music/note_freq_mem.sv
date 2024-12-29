module note_freq_mem #(
  CLK_MHZ = 50
) (
  input  [3:0] note_sel_i,
  input  [1:0] octave_sel_i,

  output logic [15:0] freq_o
);

    localparam bit [63:0] freq_c =(((2**27) * 1046)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_cd =(((2**27) * 1108)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_d =(((2**27) * 1174)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_dd =(((2**27) * 1244)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_e =(((2**27) * 1318)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_f =(((2**27) * 1396)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_fd =(((2**27) * 1479)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_g =(((2**27) * 1586)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_gd =(((2**27) * 1661)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_a =(((2**27) * 1760)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_ad =(((2**27) * 1864)/(CLK_MHZ * 1000000))-1;
    localparam bit [63:0] freq_b =(((2**27) * 1975)/(CLK_MHZ * 1000000))-1;


    logic [15:0] freq_unshifted;

    // freq pre-shifted selector
    always_comb begin
      case ( note_sel_i )
        4'd0:    freq_unshifted = freq_c;
        4'd1:    freq_unshifted = freq_cd;
        4'd2:    freq_unshifted = freq_d;
        4'd3:    freq_unshifted = freq_dd;
        4'd4:    freq_unshifted = freq_e;
        4'd5:    freq_unshifted = freq_f;
        4'd6:    freq_unshifted = freq_fd;
        4'd7:    freq_unshifted = freq_g;
        4'd8:    freq_unshifted = freq_gd;
        4'd9:    freq_unshifted = freq_a;
        4'd10:   freq_unshifted = freq_ad;
        4'd11:   freq_unshifted = freq_b;
        default: freq_unshifted = 'b0;
      endcase
    end

    assign freq_o = freq_unshifted >> octave_sel_i;

endmodule
