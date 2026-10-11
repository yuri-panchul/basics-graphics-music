# BRS-100-GW1NR9 with PMOD-RGBLCD and an 800x480 LCD

Board configuration `brisbane_brs_100_tm1638_pmod_rgblcd_800_480_by_claude_alt`.

This is [brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_claude_alt](../brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_claude_alt/README.md) with an 800x480 RGB LCD in place of the
4.3" 480x272 one. The wiring, the TM1638, PCM5102 and INMP441 modules, the
buttons and the LEDs are the same, so follow the README of that directory:

* [wiring diagram](../brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_claude_alt/wiring.png) and the J5 and J6 tables;
* [pin 1 of PMOD-RGBLCD J2](../brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_claude_alt/pmod_rgblcd_pin1.png).

## What differs from 480x272

* [board_specific_top.sv](board_specific_top.sv) defines `USE_LCD_800_480`
  and includes the top module of `brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_claude_alt`, which then uses an 800x480 screen
  and the `lcd_800_480` timing, as `tang_nano_9k_lcd_800_480_tm1638` does.
* [gowin_rpll.v](gowin_rpll.v) is the PLL of `tang_nano_9k_lcd_800_480_tm1638`:
  27 MHz * 24 / 5 = 129.6 MHz, divided by 4 for a 32.4 MHz pixel clock,
  instead of 9 MHz.
* [board_specific.sdc](board_specific.sdc) constrains the pixel clock at
  32.4 MHz. The Tang Nano 9K 800x480 configuration still constrains it at
  9 MHz.
* board_specific.cst is the constraint file of `brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_claude_alt`, which names the pins by function.

## Things to check on hardware

* The pixel clock is almost four times faster than at 480x272 and goes over
  jumper wires. Keep the LCD wires short, about 10 cm, and run the GND wires
  of PMOD-RGBLCD J2 next to the LCD_CLK wire. Flicker, colour noise or a
  shifted picture point to the wires.
* PMOD-RGBLCD is sold with the 4.3" 480x272 LCD. Its 40-pin connector is the
  usual RGB LCD connector, but an 800x480 panel has not been tried on it.
* The backlight boost of PMOD-RGBLCD is set to about 20 mA by R2 (5.1 ohm).
  Larger 800x480 panels may want a different backlight current, and their
  backlight draws from the USB port through the 5 V pin of BRS-100.

## Status

`labs/3_music/3_0_oscilloscope`, with the LCD, TM1638, microphone and DAC,
builds with Gowin EDA V1.9.9 Beta-4 Education: the same logic as
`tang_nano_9k_lcd_800_480_tm1638` (711 LUTs, 185 registers), every signal on
the same FPGA pin as in `brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_claude_alt`, and no timing violations with the
pixel clock constrained at 32.4 MHz. Fmax is 84.8 MHz on the 27 MHz clock and 95.8 MHz on
the pixel clock.

Not yet tried on a real board.
