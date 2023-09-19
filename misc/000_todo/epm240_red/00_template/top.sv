module top
(
    input  clk_12, clk_14, clk_62, clk_64,

    inout          pin_1 , pin_2 , pin_3 , pin_4 , pin_5 , pin_6 , pin_7 , pin_8 ,
                                                   pin_15, pin_16, pin_17, pin_18, pin_19,
           pin_20, pin_21,                                 pin_26, pin_27, pin_28, pin_29,
           pin_30,                 pin_33, pin_34, pin_35, pin_36, pin_37, pin_38, pin_39,
           pin_40, pin_41, pin_42, pin_43, pin_44,                 pin_47, pin_48, pin_49,
           pin_50, pin_51, pin_52, pin_53, pin_54, pin_55, pin_56, pin_57, pin_58,
                   pin_61,                                 pin_66, pin_67, pin_68, pin_69,
           pin_70, pin_71, pin_72, pin_73, pin_74, pin_75, pin_76, pin_77, pin_78,
                   pin_81, pin_82, pin_83, pin_84, pin_85, pin_86, pin_87, pin_88, pin_89,
           pin_90, pin_91, pin_92,                 pin_95, pin_96, pin_97, pin_98, pin_99,
           pin_100
);

    logic [31:0] cnt_12;

    always_ff @ (posedge clk_12)
        cnt_12 <= cnt_12 + 1'd1;

    assign pin_50 = cnt_12 [31];
    assign pin_51 = cnt_12 [23];

    logic [31:0] cnt_14;

    always_ff @ (posedge clk_14)
        cnt_14 <= cnt_14 + 1'd1;

    assign pin_52 = cnt_14 [31];
    assign pin_53 = cnt_14 [23];

    logic [31:0] cnt_62;

    always_ff @ (posedge clk_62)
        cnt_62 <= cnt_62 + 1'd1;

    assign pin_54 = cnt_62 [31];
    assign pin_55 = cnt_62 [23];

    logic [31:0] cnt_64;

    always_ff @ (posedge clk_64)
        cnt_64 <= cnt_64 + 1'd1;

    assign pin_56 = cnt_64 [31];
    assign pin_57 = cnt_64 [23];

    assign pin_58 = |
    {
                pin_1 , pin_2 , pin_3 , pin_4 , pin_5 , pin_6 , pin_7 , pin_8 ,
                                                pin_15, pin_16, pin_17, pin_18, pin_19,
        pin_20, pin_21,                                 pin_26, pin_27, pin_28, pin_29,
        pin_30,                 pin_33, pin_34, pin_35, pin_36, pin_37, pin_38, pin_39,
        pin_40, pin_41, pin_42, pin_43, pin_44,                 pin_47, pin_48, pin_49,
        pin_50, pin_51, pin_52, pin_53, pin_54, pin_55, pin_56, pin_57, pin_58,
                pin_61,                                 pin_66, pin_67, pin_68, pin_69,
        pin_70, pin_71, pin_72, pin_73, pin_74, pin_75, pin_76, pin_77, pin_78,
                pin_81, pin_82, pin_83, pin_84, pin_85, pin_86, pin_87, pin_88, pin_89,
        pin_90, pin_91, pin_92,                 pin_95, pin_96, pin_97, pin_98, pin_99,
        pin_100
    };

endmodule
