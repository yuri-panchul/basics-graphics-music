`ifndef SWAP_BITS_SVH
`define SWAP_BITS_SVH

//----------------------------------------------------------------------------

`define SWAP_BITS(dst, src)                                      \
                                                                 \
    generate                                                     \
        genvar dst``_i;                                          \
                                                                 \
        for (dst``_i = 0; dst``_i < $bits (dst); dst``_i ++)     \
        begin : dst``_label                                      \
            assign dst [dst``_i] = src [$left (dst) - dst``_i];  \
        end                                                      \
    endgenerate                                                  \

//----------------------------------------------------------------------------

`endif
