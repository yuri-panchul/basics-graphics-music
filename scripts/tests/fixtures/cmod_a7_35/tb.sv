`timescale 1ns/1ps
module tb;
    reg sysclk=0;
    always #41.666667 sysclk=~sysclk;
    reg [1:0] btn=0;
    wire [1:0] led;
    wire led0_r, led0_g, led0_b;
    wire [7:0] ja;
    wire [7:0] gpio;
    reg uart_txd_in=1;
    wire uart_rxd_out;
    tri1 pio26;
    wire pio27, pio28, pio29, pio30, pio32, pio33, pio34;
    reg pio31=0;
    board_specific_top dut
    (
        .sysclk(sysclk), .btn(btn), .led(led),
        .led0_r(led0_r), .led0_g(led0_g), .led0_b(led0_b), .ja(ja),
        .uart_txd_in(uart_txd_in), .uart_rxd_out(uart_rxd_out),
        .pio1(gpio[0]), .pio2(gpio[1]), .pio3(gpio[2]), .pio4(gpio[3]),
        .pio5(gpio[4]), .pio6(gpio[5]), .pio7(gpio[6]), .pio8(gpio[7]),
        .pio26(pio26), .pio27(pio27), .pio28(pio28), .pio29(pio29),
        .pio30(pio30), .pio31(pio31), .pio32(pio32), .pio33(pio33), .pio34(pio34)
    );

    initial begin
        #40000000;
        $fatal(1,"Timeout");
    end

    // Independent I2S microphone: one dummy bit, then 24 MSB-first data bits.
    reg mic_ws=1;
    integer mic_bit=0;
    localparam [23:0] MIC_SAMPLE=24'h916ac3;
    always @ (negedge pio29) begin
        if(pio30!=mic_ws) begin
            mic_ws=pio30;
            mic_bit=0;
            pio31=0;
        end else begin
            mic_bit=mic_bit+1;
            pio31=(!pio30 && mic_bit>=1 && mic_bit<=24) ? MIC_SAMPLE[24-mic_bit] : 1'b0;
        end
    end

    reg dac_ws=0;
    integer dac_bit=0, dac_words=0;
    reg [31:0] dac_word=0;
    always @ (posedge pio32) begin
        if (pio34!=dac_ws) begin
            // In I2S the old slot's LSB overlaps the new LRCLK state.
            dac_word={dac_word[30:0],pio33};
            if(dac_words>=2 && dac_word!==32'h5a3c0000)
                $fatal(1,"I2S slot data/alignment: %h",dac_word);
            dac_words=dac_words+1;
            dac_ws=pio34;
            dac_bit=0;
            dac_word=0;
        end else begin
            dac_bit=dac_bit+1;
            dac_word={dac_word[30:0],pio33};
        end
    end

    integer cycles, pixels, active_pixels, hs_pixels, vs_lines;
    integer last_x, last_y;
    initial begin
        #1;
        if(dut.rst!==1 || led0_r!==0) $fatal(1,"Startup reset");
        wait(dut.locked===1);
        repeat(2) @(negedge dut.clk);
        if(dut.rst!==1) $fatal(1,"Reset released too early");
        repeat(2) @(negedge dut.clk);
        if(dut.rst!==0 || led0_g!==0 || led0_b!==1) $fatal(1,"Reset release / LED polarity");
        if(gpio!==8'ha6) $fatal(1,"GPIO bit numbering");
        uart_txd_in=0; #1;
        if(uart_rxd_out!==0) $fatal(1,"USB UART direction");
        btn[1]=1;
        repeat(3) @(negedge dut.clk);
        if(dut.key[0]!==1) $fatal(1,"BTN1 mapping");
        btn[1]=0;

        // Wait for the next visible frame origin, then count a whole raster.
        wait(dut.i_vga.vpos==1);
        wait(dut.i_vga.hpos==0 && dut.i_vga.vpos==0);
        @(negedge dut.clk);
        cycles=0; pixels=0; active_pixels=0; hs_pixels=0; vs_lines=0;
        last_x=-1;last_y=-1;
        repeat(800*525*4) begin
            if(dut.i_vga.hpos!=last_x || dut.i_vga.vpos!=last_y) begin
                pixels=pixels+1;
                if(dut.i_vga.display_on) begin
                    active_pixels=active_pixels+1;
                    if({ja[4],ja[0]}!==2'b01 || {ja[5],ja[1]}!==2'b10 || {ja[6],ja[2]}!==2'b11)
                        $fatal(1,"TinyVGA colour mapping");
                end else if({ja[6:4],ja[2:0]}!==6'b0)
                    $fatal(1,"RGB must be black during blanking");
                if(!ja[7]) hs_pixels=hs_pixels+1;
                if(dut.i_vga.hpos==0 && !ja[3]) vs_lines=vs_lines+1;
                last_x=dut.i_vga.hpos;last_y=dut.i_vga.vpos;
            end
            cycles=cycles+1;
            @(negedge dut.clk);
        end
        if(pixels!=800*525 || active_pixels!=640*480 || hs_pixels!=96*525 || vs_lines!=2)
            $fatal(1,"Raster: pixels=%d active=%d hs=%d vs=%d",pixels,active_pixels,hs_pixels,vs_lines);
        if(dut.mic!==MIC_SAMPLE) $fatal(1,"Microphone sample %h",dut.mic);
        if(dac_words<4) $fatal(1,"DAC clocks absent");
        btn[0]=1;#1;
        if(dut.rst!==1 || led0_r!==0) $fatal(1,"Asynchronous reset assertion");
        #500;btn[0]=0;
        wait(dut.rst===0);
        force dut.i_mmcm.LOCKED=0;#1;
        if(dut.rst!==1) $fatal(1,"Lock loss reset");
        release dut.i_mmcm.LOCKED;
        $display("PASS: reset, GPIO/UART, full VGA frame, RGB blanking, INMP441, I2S DAC");
        $finish;
    end
endmodule
