package uart_pkg;
    localparam SMPL_X16_1     = 7;
    localparam SMPL_X16_2     = 8; 
    localparam SMPL_X16_3     = 9;
    localparam SMPL_X16_VOTED = 10;

    localparam SMPL_X8_1     = 3;
    localparam SMPL_X8_2     = 4;
    localparam SMPL_X8_3     = 5;
    localparam SMPL_X8_VOTED = 6;

    localparam RX_VOTE_SAMPLES = 3;

    localparam SMPL_X8_LAST  = 7;
    localparam SMPL_X16_LAST = 15;

    localparam SMPL_X8_STOP1  = 7;
    localparam SMPL_X8_STOP2  = 15;
    localparam SMPL_X16_STOP1 = 15;
    localparam SMPL_X16_STOP2 = 31;

    localparam SMPL_CNT_MAX   = 32;
    localparam SMPL_CNT_WIDTH = $clog2(SMPL_CNT_MAX);

    localparam DATA_BITS      = 8;
    localparam DATA_CNT_WIDTH = $clog2(DATA_BITS);

    // localparam FIFO_DEPTH     = 16;
    // localparam FIFO_CNT_WIDTH = $clog2(FIFO_DEPTH + 1);

    typedef enum bit [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    // typedef struct packed {
    //     logic [3:0]  div_frac;
    //     logic [11:0] div_mant;
    //     logic        over8;
    // } baudgen_cfg_t;

    // typedef struct packed {
    //     logic over8;
    //     logic stop_bits;
    // } driver_cfg_t;
endpackage