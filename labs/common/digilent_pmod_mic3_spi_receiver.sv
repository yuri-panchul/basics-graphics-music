`include "config.svh"

module digilent_pmod_mic3_spi_receiver
# (
    parameter clk_mhz = 50
)
(
    input               clk,
    input               rst,
    output              cs,
    output              sck,
    input               sdo,
    output logic [15:0] value
);


    
    logic [ 6:0] cnt;
    logic [15:0] shift;
    
    generate

    logic en;
    if (clk_mhz == 100) begin
    always_ff @ (posedge clk or posedge rst)
        begin
            if (rst) en  <= 0;
            else     en  <= ~en;
        end
    
    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst) begin
            cnt <= 7'b100 ;
        end
        else if(en) begin
            cnt <= cnt + 7'b1;
        end

    end
    end
    else 
        always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
            cnt <= 7'b100;
        else
            cnt <= cnt + 7'b1;
    end
    endgenerate

    assign sck = ~ cnt [1];
    assign cs  =   cnt [6];

    wire sample_bit = ( cs == 1'b0 && cnt [2:0] == 3'b111 );
    wire value_done = ( cnt [6:0] == 8'b0 );

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            shift <= 16'h0000;
            value <= 16'h0000;
        end
        else if (sample_bit)
        begin
            shift <= (shift << 1) | sdo;
        end
        else if (value_done)
        begin
            value <= shift;
        end
    end

endmodule
