module digilent_pmod_als_spi_receiver
(
    input               clock,
    input               reset_n,
    output              cs,
    output              sck,
    input               sdo,
    output logic [15:0] value
);

    logic [21:0] cnt;
    logic [15:0] shift;

    always_ff @ (posedge clock)
    begin       
        if (! reset_n)
            cnt <= 22'b100;
        else
            cnt <= cnt + 22'b1;
    end

    assign sck = ~ cnt [3];
    assign cs  =   cnt [8];

    wire sample_bit = ( cs == 1'b0 && cnt [3:0] == 4'b1111 );
    wire value_done = ( cnt [21:0] == 22'b0 );

    always_ff @ (posedge clock)
    begin       
        if (! reset_n)
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
