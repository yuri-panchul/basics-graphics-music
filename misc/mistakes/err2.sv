module m;

localparam       S_START_1 = 3'd1;
localparam       S_START_2 = 1;
localparam [2:0] S_START_3 = 1;

enum logic [2:0]
{
   IDLE = 3'b000,
   F1   = 3'b001,
   F0   = 3'b010,
   S1   = 3'b011,
   S0   = 3'b100
}
state, new_state;


typedef enum
   localparam S_IDLE   = 3'd0,
               S_START  = 3'd1,
               S_XMIT   = 3'd2,
               S_PARITY = 3'd3,
               S_STOP   = 3'd4;



initial
begin
    $display ("S_START_1 %b", S_START_1);
    $display ("S_START_2 %b", S_START_2);
    $display ("S_START_3 %b", S_START_3);
end

endmodule
