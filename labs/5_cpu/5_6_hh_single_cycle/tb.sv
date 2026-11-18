//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

`include "prog_config.svh"

module tb;

    logic        clk;
    logic        rst;

    wire  [31:0] imAddr;     // instruction memory address
    wire  [31:0] imData;     // instruction memory data

    logic [ 4:0] regAddr;    // debug access reg address
    wire  [31:0] regData;    // debug access reg data

    wire  [31:0] PC;
    wire  [31:0] wRAMData;   // data for writing to RAM
    wire  [31:0] rRAMData;   // data read from  RAM
    wire  [31:0] dAddr;      // addres for RAM
    wire  [31:0] ALUResult;  //
    wire         we;         // enable write to data memory

    riscvsingle cpu
    (
        .clk        ( clk       ),
        .reset      ( rst       ),
        .PC         ( PC        ),
        .Instr      ( imData    ) ,
        .MemWrite   ( we        ),
        .ALUResult  ( ALUResult ),
        .WriteData  ( wRAMData  ),
        .ReadData   ( rRAMData  )
    );

    //------------------------------------------------------------------------

    assign imAddr = PC >> 2;

    instruction_rom
    # (
        .SIZE (`INSTRUCTION_ROM_DEPTH),
        .NAME (`PROGRAM_FILE_NAME)
    )
    i_rom
    (
        .a  ( imAddr ),
        .rd ( imData )
    );

    //------------------------------------------------------------------------

    assign dAddr = ALUResult;

    dmem i_dmem
    (
        .clk ( clk      ),
        .we  ( we       ),
        .a   ( dAddr    ),
        .wd  ( wRAMData ),
        .rd  ( rRAMData )
    );

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;
    end

    //------------------------------------------------------------------------

    `ifdef MODEL_TECH
        `define STOP_OR_FINISH $stop
    `else
        `define STOP_OR_FINISH $finish
    `endif

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            // Uncomment the following `define
            // to generate a VCD file and analyze it using GTKwave

            $dumpvars;
        `endif

        regAddr <= 5'd10;  // a0 register used for I/O

        @ (negedge rst);

        repeat (1000)
        begin
            @ (posedge clk);

            `ifdef USE_RISCVTEST_HEX

                if (we)
                begin
                    if (dAddr === 108 & wRAMData === 32'hABCDE7D5)
                    begin
                        $display ("Simulation succeeded");
                        `STOP_OR_FINISH;
                    end
                    else if (dAddr !== 96)
                    begin
                        $display ("Simulation failed");
                        `STOP_OR_FINISH;
                    end
                end

            `else

                if (  ALUResult == 32'h00213d05    // Fibonacci
                    | ALUResult == 32'h1c8cfc00 )  // Factorial
                begin
                    $display ("%s PASS", `__FILE__);
                    `STOP_OR_FINISH;
                end

            `endif // `ifdef USE_RISCVTEST_HEX

        end

        $display ("%s FAIL: none of expected register values occured",
            `__FILE__);

        `STOP_OR_FINISH;
    end

    //------------------------------------------------------------------------

    int unsigned cycle = 0;
    bit was_rst = 1'b0;

    logic [31:0] prev_imAddr;
    logic [31:0] prev_regData;

    always @ (posedge clk)
    begin
        $write ("cycle %5d", cycle ++);

        if (rst)
        begin
            $write (" rst");
            was_rst <= 1'b1;
        end
        else
        begin
            $write ("    ");
        end

        if (imAddr !== prev_imAddr)
            $write (" %h", imAddr);
        else
            $write ("         ");

        if (was_rst & ~ rst & $isunknown (imData))
        begin
            $display ("%s FAIL: fetched instruction at address %x contains Xs: %x",
                `__FILE__, imAddr, imData);

            `STOP_OR_FINISH;
        end

        if (regData !== prev_regData)
            $write (" %h", regData);
        else
            $write ("         ");

        prev_imAddr  <= imAddr;
        prev_regData <= regData;

        $display;
    end

endmodule
