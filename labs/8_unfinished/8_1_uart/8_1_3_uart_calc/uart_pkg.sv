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

    typedef enum bit [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } uart_state_t;

    typedef enum logic [2:0] {
        OP_ADD = 3'b000,
        OP_SUB = 3'b001,
        OP_AND = 3'b010,
        OP_OR  = 3'b011,
        OP_XOR = 3'b100,
        OP_MUL = 3'b101,
        OP_NL  = 3'b110
    } opcode_t;
endpackage