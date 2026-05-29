module uart_transceiver
    import uart_pkg::*;
# (
    parameter over_smpl = 0,
    parameter stop_bits = 0
)
(
    input clk,
    input rst,

    input uart_strb_i,

    input                   tx_vld_i,
    input [DATA_BITS - 1:0] tx_data_i,
    output                  tx_rdy_o,

    output tx_o
);

    state_t state, next_state;

    logic [SMPL_CNT_WIDTH - 1:0] smpl_cnt; 
    logic [DATA_CNT_WIDTH - 1:0] bit_cnt;

    logic is_last;
    logic is_stop;

    logic [DATA_BITS - 1:0] tx_shift_reg;
    logic                   tx_reg;

    assign is_last = over_smpl ? (smpl_cnt == SMPL_X8_LAST) : (smpl_cnt == SMPL_X16_LAST);

    assign is_stop = stop_bits ? 
    (over_smpl ? (smpl_cnt == SMPL_X8_STOP2) : (smpl_cnt == SMPL_X16_STOP2)) :
    (over_smpl ? (smpl_cnt == SMPL_X8_STOP1) : (smpl_cnt == SMPL_X16_STOP1));

    always_ff @(posedge clk or posedge rst) begin 
        if (rst)
            smpl_cnt <= '0;
        else begin 
            if (uart_strb_i) begin 
                if (state == IDLE)
                    smpl_cnt <= '0;
                else if (state == START & tx_o == 1'b1)
                    smpl_cnt <= '0;
                else if ((is_last & state != STOP) | (is_stop & state == STOP))
                    smpl_cnt <= '0;
                else  
                    smpl_cnt <= smpl_cnt + 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (tx_vld_i & tx_rdy_o)
            tx_shift_reg <= tx_data_i;
    end

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
                if (tx_vld_i) 
                    next_state = START;
            START: 
                if (uart_strb_i & is_last)
                        next_state = DATA;
            DATA: 
                if (uart_strb_i & is_last & bit_cnt == (DATA_BITS - 1)) 
                    next_state = STOP;
            STOP:
                if (uart_strb_i & is_stop) begin
                    if (tx_vld_i)
                        next_state = START;
                    else 
                        next_state = IDLE;
                end
        endcase 
    end

    always_ff @(posedge clk) begin 
        if (state != DATA)
            bit_cnt <= '0;
        else if (uart_strb_i & is_last)
            bit_cnt <= bit_cnt + 1'b1;
    end

    always_ff @(posedge clk or posedge rst) begin 
        if (rst) 
            tx_reg <= 1'b1;
        else begin 
            case (state)
                IDLE: 
                    tx_reg <= 1'b1; 
                START: 
                    if (uart_strb_i) begin
                        if (is_last)
                            tx_reg <= tx_shift_reg[0];
                        else  
                            tx_reg <= 1'b0;
                    end
                DATA:
                    if (uart_strb_i & is_last) begin 
                        if (bit_cnt == (DATA_BITS - 1))
                            tx_reg <= 1'b1; 
                        else  
                            tx_reg <= tx_shift_reg[bit_cnt + 1];
                    end
                STOP: 
                    if (uart_strb_i & is_stop)
                        tx_reg <= 1'b1; 
            endcase
        end
    end

    assign tx_rdy_o = (state == IDLE) | (state == STOP & uart_strb_i & is_stop);
    assign tx_o = tx_reg;

endmodule