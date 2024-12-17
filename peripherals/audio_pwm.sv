module audio_pwm
#(parameter data_w = 16) (
  input  logic              clk_i,
  input  logic              rst_i,

  input  logic [data_w-1:0] data_i,
  output logic              pwm_o
);

    logic [data_w-1:0] cnt_ff;
    logic [data_w-1:0] data_unsigned;

    assign data_unsigned = data_i + 2**(data_w-1);

    always_ff @( posedge clk_i ) begin
    if ( rst_i )
        cnt_ff <= '0;
    else
        cnt_ff <= cnt_ff + 'b1;
    end

    assign pwm_o = (cnt_ff <= data_unsigned);

endmodule
