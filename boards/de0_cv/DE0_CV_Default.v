      input              CLOCK_50,
      input              RESET_N,

      input       [3:0]  KEY,
      input       [9:0]  SW,

      output      [9:0]  LEDR,
      
      output      [6:0]  HEX0,
      output      [6:0]  HEX1,
      output      [6:0]  HEX2,
      output      [6:0]  HEX3,
      output      [6:0]  HEX4,
      output      [6:0]  HEX5,

      output      [3:0]  VGA_B,
      output      [3:0]  VGA_G,
      output             VGA_HS,
      output      [3:0]  VGA_R,
      output             VGA_VS

      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,
