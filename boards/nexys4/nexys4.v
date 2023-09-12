
module nexys4
(
    input         clk,
    input         btnCpuReset,

    input         btnC,
    input         btnU,
    input         btnL,
    input         btnR,
    input         btnD,

    input  [15:0] sw,

    output [15:0] led,

    output        RGB1_Red,
    output        RGB1_Green,
    output        RGB1_Blue,
    output        RGB2_Red,
    output        RGB2_Green,
    output        RGB2_Blue,

    output [ 6:0] seg,
    output        dp,
    output [ 7:0] an,

    inout  [ 7:0] JA,
    inout  [ 7:0] JB,

    input         RsRx
