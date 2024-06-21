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
    output logic [11:0] value
);

    //------------------------------------------------------------------------

    logic clk_en;

    generate

        if (clk_mhz == 100)
        begin : clk_100
            always_ff @ (posedge clk or posedge rst)
            begin
                if (rst) clk_en  <= '0;
                else     clk_en  <= ~ clk_en;
            end
        end
        else
        begin : not_clk_100
            assign clk_en = '1;
        end

    endgenerate

    //------------------------------------------------------------------------

    logic [6:0] cnt;

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
            cnt <= 7'b100;
        else if (clk_en)
            cnt <= cnt + 7'b1;
    end

    //------------------------------------------------------------------------

    assign sck = ~ cnt [1];
    assign cs  =   cnt [6];

    wire sample_bit = ( cs == 1'b0 && cnt [1:0] == 2'b11 );
    wire value_done = ( cnt [6:0] == '0 );

    //------------------------------------------------------------------------

    logic [11:0] shift;

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            shift <= '0;
            value <= '0;
        end
        else if (clk_en)
        begin
            if (sample_bit)
                shift <= (shift << 1) | sdo;
            else if (value_done)
                value <= shift;
        end
    end

endmodule
