module uart_receiver
    import uart_pkg::*;
# (
    parameter over_smpl = 0,
    parameter stop_bits = 0
)
(
    input clk, 
    input rst,

    input uart_strb_i,

    output                   rx_vld_o,
    output [DATA_BITS - 1:0] rx_data_o,
    input                    rx_rdy_i,

    input rx_i
);

    uart_state_t state, next_state;

    logic [SMPL_CNT_WIDTH - 1:0] smpl_cnt; 
    logic [DATA_CNT_WIDTH - 1:0] bit_cnt;

    logic [RX_VOTE_SAMPLES -1:0] rx_smpl;
    logic                        rx_voted;

    logic is_smpl;
    logic is_vote;
    logic is_last;
    logic is_stop;

    logic [DATA_BITS - 1:0] rx_shift_reg;
    logic [DATA_BITS - 1:0] rx_reg;
    logic                   rx_vld_reg;

    assign rx_voted = rx_smpl[0] & rx_smpl[1] |
                      rx_smpl[0] & rx_smpl[2] |
                      rx_smpl[1] & rx_smpl[2];

    assign is_smpl = over_smpl ? 
        (smpl_cnt == SMPL_X8_1 | smpl_cnt == SMPL_X8_2 | smpl_cnt == SMPL_X8_3) : 
        (smpl_cnt == SMPL_X16_1 | smpl_cnt == SMPL_X16_2 | smpl_cnt == SMPL_X16_3);

    assign is_vote = over_smpl ? (smpl_cnt ==  SMPL_X8_VOTED) : (smpl_cnt ==  SMPL_X16_VOTED);

    assign is_last = over_smpl ? (smpl_cnt == SMPL_X8_LAST) : (smpl_cnt == SMPL_X16_LAST);

    assign is_stop = stop_bits ? 
        (over_smpl ? (smpl_cnt == SMPL_X8_STOP2) : (smpl_cnt == SMPL_X16_STOP2)) :
        (over_smpl ? (smpl_cnt == SMPL_X8_STOP1) : (smpl_cnt == SMPL_X16_STOP1));

    always_ff @(posedge clk or posedge rst) begin 
        if (rst) 
            state <= IDLE;
        else  
            state <= next_state;
    end  

    always_comb begin
        next_state = state; 
        case (state)
            IDLE:  
                if (~rx_i) 
                    next_state = START;
            START: 
                if (uart_strb_i) begin 
                    if (is_vote & rx_voted)
                        next_state = IDLE;
                    else if (is_last)
                        next_state = DATA;
                end
            DATA: 
                if (uart_strb_i & is_last & bit_cnt == (DATA_BITS - 1)) 
                    next_state = STOP;
            STOP:
                if (uart_strb_i & is_stop)  
                    next_state = IDLE;
        endcase 
    end

    always_ff @(posedge clk or posedge rst) begin 
        if (rst)
            smpl_cnt <= '0;
        else if ((state == IDLE & ~rx_i) | (uart_strb_i & state != STOP & is_last))
            smpl_cnt <= '0;
        else if (uart_strb_i)
            smpl_cnt <= smpl_cnt + 1'b1;
    end

    always_ff @(posedge clk) begin 
        if (state != DATA)
            bit_cnt <= '0;
        else if (uart_strb_i & is_last)
            bit_cnt <= bit_cnt + 1'b1;
    end

    always_ff @(posedge clk) begin
        if (uart_strb_i & is_smpl)
            rx_smpl <= {rx_smpl[1:0], rx_i};
    end

    always_ff @(posedge clk) begin 
        if (state == DATA & uart_strb_i & is_vote)
            rx_shift_reg <= {rx_voted, rx_shift_reg[DATA_BITS - 1:1]};
    end

    always_ff @(posedge clk or posedge rst) begin 
        if (rst)
            rx_vld_reg <= 1'b0;
        else if (state == STOP & is_stop & uart_strb_i) 
            rx_vld_reg <= 1'b1;
        else if (rx_vld_o & rx_rdy_i)
            rx_vld_reg <= 1'b0;
    end

    always_ff @(posedge clk)
        if (state == STOP & is_stop & uart_strb_i)
            rx_reg <= rx_shift_reg;

    assign rx_vld_o  = rx_vld_reg;
    assign rx_data_o = rx_reg;

endmodule