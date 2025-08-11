/*
 * schoolRISCV - small RISC-V CPU
 *
 * originally based on Sarah L. Harris MIPS CPU
 *                   & schoolMIPS project
 *
 * Copyright(c) 2017-2020 Stanislav Zhelnio
 *                        Aleksandr Romanov
 */

// Fully associative instruction cache

 module sr_icache
 # (
    parameter bit CACHE_EN = 1'b0
 )
 (
    input  logic          clk,         // clock
    input  logic          rst,         // reset
    input  logic          imem_req_i,  // Memory request
    input  logic  [31:0]  imAddr,      // instruction memory address
    output logic  [31:0]  imData,      // instruction memory data
    output logic          im_drdy,
    output logic  [31:0]  ext_addr_o,
    output logic          ext_req_o,
    input  logic          ext_rsp_i,
    input  logic  [127:0] ext_data_i
);

localparam NWAYS = 4;
localparam LINE_SIZE = 128;
localparam TAG_WIDTH  = 32 - $clog2(LINE_SIZE/32);

logic     [NWAYS -1:0] cache_way_en      ;
logic [LINE_SIZE -1:0] cache_data_ff     [NWAYS -1:0];
logic [TAG_WIDTH -1:0] cache_tag_ff      [NWAYS -1:0];
logic   [2*NWAYS -1:0] cache_state_ff    ;
logic   [2*NWAYS -1:0] cache_state_next  ;
logic                  cache_state_en    ;
logic    [NWAYS -1:0]  plru_set          ;
logic    [NWAYS -1:0]  cache_plru        ;
logic    [NWAYS -1:0]  cache_valid       ;
logic    [NWAYS -1:0]  cache_plru_new    ;
logic    [NWAYS -1:0]  cache_valid_new   ;
logic    [NWAYS -1:0]  cache_evict       ;


logic [31:0]           req_addr_ff;
logic                  l1i_req_val_ff;

logic [TAG_WIDTH -1:0] in_tag;
logic            [1:0] cl_offs;
logic [TAG_WIDTH -1:0] in_tag_ff;
logic            [1:0] cl_offs_ff;
logic                  cl_hit;
logic                  cl_hit_ff;
logic [31 :0] hit_data;
logic [31 :0] rsp_data_next;
logic [31 :0] rsp_data_ff;
logic [NWAYS     -1:0] cl_hit_vec;

logic cl_refill_ff;

genvar way_idx;

  // Latch input data;
  always_ff @(posedge clk)
    if (imem_req_i)
      req_addr_ff <= imAddr;

  always_ff @(posedge clk)
    if (rst)
      l1i_req_val_ff <= '0;
    else
      l1i_req_val_ff <= imem_req_i;

  assign in_tag = imem_req_i ? imAddr[31 -:TAG_WIDTH] : req_addr_ff[31 -:TAG_WIDTH];

  assign cl_offs = imem_req_i ? imAddr[1:0] :req_addr_ff[1:0];

  // Hit/Miss detection and data bypass interface
  always_comb begin
    for (integer idx = 0 ; idx < NWAYS; idx = idx + 1)
      cl_hit_vec[idx] = (in_tag == cache_tag_ff[idx]) & cache_state_ff[idx]; // cache_state_ff[NWAYS-1:0] are valid bits
                                                                             // cache_state_ff[NWAYS+:NWAYS] are used bits
  end

  assign cl_hit = (|cl_hit_vec) & CACHE_EN;

  always_comb begin
    hit_data    = '0;
    for (integer idx = 0 ; idx < NWAYS; idx = idx + 1)
      hit_data    |= {32{ cl_hit_vec[idx]}} & cache_data_ff[idx][32*cl_offs +:32];
  end

  assign rsp_data_next = cl_hit ? hit_data : ext_data_i[32*cl_offs +:32];
  always_ff @(posedge clk)
    if (cl_hit | ext_rsp_i)
      rsp_data_ff <= rsp_data_next;

  assign im_drdy = cl_hit_ff | cl_refill_ff;
  assign imData  = rsp_data_ff;

  // Memory interface
  assign ext_req_o  = ~cl_hit_ff & l1i_req_val_ff;
  assign ext_addr_o = {req_addr_ff[31-:TAG_WIDTH], 2'b0};

  always_ff @(posedge clk)
    if(rst)  begin
      cl_hit_ff    <= 0;
      cl_refill_ff <= 0;
    end else begin
      cl_hit_ff    <= cl_hit;
      cl_refill_ff <= ext_rsp_i;
    end

  // Refill logic
  assign cache_evict[0] = (NWAYS==1) ? '1 : ( &(cache_valid) ? ~cache_plru[0] : ~cache_valid[0]); // if cache is full, check used bit

  generate
    for (way_idx = 1; way_idx < NWAYS; way_idx = way_idx + 1) begin : g_vict
      assign cache_evict[way_idx] = &(cache_valid) ? (~cache_plru[way_idx] & &(cache_plru[way_idx -1 : 0])) // if [way_idx] used bit is low
                                                                                                           // and other used bits are high
                                                                                                           // then way_idx bit of cache_evict is high
                                          : (~cache_valid[way_idx] & &(cache_valid[way_idx -1 : 0])); // cache_evict logic for valid bits
    end : g_vict
  endgenerate

  assign cache_plru       = cache_state_ff[NWAYS+:NWAYS]; // used bits
  assign cache_valid      = cache_state_ff[NWAYS-1:0];    // valid bits

  assign cache_state_en   = (cl_hit & l1i_req_val_ff ) | ext_rsp_i; // if cpu mem request and cache hit, or memory response
                                                                    // update used and valid bits
  assign cache_valid_new  = (cache_valid | ( cache_evict & ~{NWAYS{cl_hit}})); // update valid bits for evicting cache line
  assign plru_set         = (cl_hit ? cl_hit_vec : cache_evict);    // if hit cache, mark hit cache lines as used,
                                                                    // else mark evicted cache lines as used
  assign cache_plru_new   = &(cache_plru | plru_set) ? plru_set                  // if all old used bits aren't equal new bits, take new
                                                      : (cache_plru | plru_set); // else, merge old one and new

  // used and valid bits register
  assign cache_state_next = {cache_plru_new, cache_valid_new};

  always_ff @(posedge clk)
    if(rst)
      cache_state_ff <= '0;
    else if (cache_state_en)
      cache_state_ff <= cache_state_next;

  assign cache_way_en  = cache_evict & {NWAYS{ext_rsp_i}}; // enable update for evicted lines

  // tag and data memory
  generate
    for (way_idx = 0; way_idx < NWAYS; way_idx = way_idx + 1) begin : g_cache_memories
      always_ff @(posedge clk)
        if (cache_way_en[way_idx]) begin
          cache_data_ff[way_idx] <= ext_data_i;
          cache_tag_ff[way_idx]  <= in_tag;
        end

    end : g_cache_memories
  endgenerate


endmodule
