// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"

module vga
# (
    parameter N_MIXER_PIPE_STAGES = 0,

              HPOS_WIDTH          = 10,
              VPOS_WIDTH          = 10,

              // Horizontal constants

              H_DISPLAY           = 640,  // Horizontal display width
              H_FRONT             =  16,  // Horizontal right border (front porch)
              H_SYNC              =  96,  // Horizontal sync width
              H_BACK              =  48,  // Horizontal left border (back porch)

              // Vertical constants

              V_DISPLAY           = 480,  // Vertical display height
              V_BOTTOM            =  10,  // Vertical bottom border
              V_SYNC              =   2,  // Vertical sync # lines
              V_TOP               =  33,  // Vertical top border

              CLK_MHZ             =  50,   // Clock frequency (50 or 100 MHz)
              VGA_CLOCK           =  25   // Pixel clock of VGA in MHz
)
(
    input                           clk,
    input                           rst,
    output logic                    hsync,
    output logic                    vsync,
    output logic                    display_on,
    output logic [HPOS_WIDTH - 1:0] hpos,
    output logic [VPOS_WIDTH - 1:0] vpos
);

    // Derived constants

    localparam H_SYNC_START  = H_DISPLAY    + H_FRONT + N_MIXER_PIPE_STAGES,
               H_SYNC_END    = H_SYNC_START + H_SYNC  - 1,
               H_MAX         = H_SYNC_END   + H_BACK,

               V_SYNC_START  = V_DISPLAY    + V_BOTTOM,
               V_SYNC_END    = V_SYNC_START + V_SYNC  - 1,
               V_MAX         = V_SYNC_END   + V_TOP;

    // Calculating next values of the counters

    logic [HPOS_WIDTH - 1:0] d_hpos;
    logic [VPOS_WIDTH - 1:0] d_vpos;

    always_comb
    begin
        if (hpos == H_MAX)
        begin
            d_hpos = 1'd0;

            if (vpos == V_MAX)
                d_vpos = 1'd0;
            else
                d_vpos = vpos + 1'd1;
        end
        else
        begin
          d_hpos = hpos + 1'd1;
          d_vpos = vpos;
        end
    end

    // Enable to divide clock from 50 or 100 MHz to 25 MHz

    logic [3:0] clk_en_cnt;
    logic clk_en;

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            clk_en_cnt <= 3'b0;
            clk_en <= 1'b0;
        end
        else
        begin
            if (clk_en_cnt == (CLK_MHZ / VGA_CLOCK) - 1)
            begin
                clk_en_cnt <= 3'b0;
                clk_en <= 1'b1;
            end
            else
            begin
                clk_en_cnt <= clk_en_cnt + 1;
                clk_en <= 1'b0;
            end
        end
    end

    // Making all outputs registered

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            hsync       <= 1'b0;
            vsync       <= 1'b0;
            display_on  <= 1'b0;
            hpos        <= 1'b0;
            vpos        <= 1'b0;
        end
        else if (clk_en)
        begin
            hsync       <= ~ (    d_hpos >= H_SYNC_START
                               && d_hpos <= H_SYNC_END   );

            vsync       <= ~ (    d_vpos >= V_SYNC_START
                               && d_vpos <= V_SYNC_END   );

            display_on  <=   (    d_hpos <  H_DISPLAY
                               && d_vpos <  V_DISPLAY    );

            hpos        <= d_hpos;
            vpos        <= d_vpos;
        end
    end

endmodule
