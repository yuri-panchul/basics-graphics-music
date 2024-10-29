

// package tb_pkg;

//     //virtual tb_if   _s;

// endpackage


task test_finish (
    input int 	    test_id,
    input string	test_name,
    input int		result
);
begin

fd = $fopen( "global.txt", "a" );

$display("");
$display("");

if( 1==result ) begin
$fdisplay( fd, "test_id=%-5d test_name: %15s         TEST_PASSED", 
test_id, test_name );
$display(      "test_id=%-5d test_name: %15s         TEST_PASSED", 
test_id, test_name );
end else begin
$fdisplay( fd, "test_id=%-5d test_name: %15s         TEST_FAILED *******", 
test_id, test_name );
$display(      "test_id=%-5d test_name: %15s         TEST_FAILED *******", 
test_id, test_name );
end

$fclose( fd );

$display("");
$display("");

$finish();
end endtask  


task test_init;

    uart_rx <= 1;

    key <= '0;

endtask


// ImitSimulate a button 0 press
task test_seq_key0;

    $display( "test_seq_key0() - start");

    for( int loop=1;  loop<1000; loop++ ) begin

        key[0] <= 1;    
        #500;
        key[0] <= 0;    
        #500;

    end

    $display( "test_seq_key0() - complete");

endtask

// ImitSimulate a button 1 press
task test_seq_key1;

    $display( "test_seq_key1() - start");

    for( int loop=1;  loop<1000; loop++ ) begin        

        key[1] <= 1;    
        #500;
        key[1] <= 0;    
        #800;

    end

    $display( "test_seq_key1() - complete");

endtask


// task test_seq_p2;

//     //tb_uart_send( 8'hAA );

//     for( int ii=0; ii<16; ii++ ) begin
//         //@(posedge clk iff display_number[3:0]==ii ); // ожидание вывода очередной цифры на младшую цифру индикатора
//         for( int kk=0; display_number[3:0]!=ii; kk++ )
//             @(posedge clk);
//     end

// endtask

localparam  baud_rate           = 115200;
localparam  clk_frequency       = clk_mhz * 1000 * 1000;
localparam  clk_cycles_in_symbol = clk_frequency / baud_rate;

// Transferring a symbol via UART
task tb_uart_send(  input   byte  val  );

    //localparam
    @(posedge clk);
    uart_rx <= 1;

    @(posedge clk);
    uart_rx <= 0;

    for( int ii=0; ii<clk_cycles_in_symbol; ii++ ) @(posedge clk);

    for( int jj=0; jj<8; jj++ ) begin
        uart_rx = val[jj];    
        for( int ii=0; ii<clk_cycles_in_symbol; ii++ ) @(posedge clk);
    end

    @(posedge clk);
    uart_rx <= 1;
    for( int ii=0; ii<clk_cycles_in_symbol; ii++ ) @(posedge clk);

endtask


// Receiving a symbol from UART
task tb_uart_receive(  output   byte  val  );

    logic   wait_1;
    logic   wait_0;
    int     cnt_bit;
  
    wait_1 = 1;
    wait_0 = 0;
    cnt_bit = 0;

    for( int ii=0; ~uart_tx  ; ii++ ) begin
        @(posedge clk);
    end

    wait_1 = 0;
    wait_0 = 1;

    for( int ii=0; uart_tx  ; ii++ ) begin
        @(posedge clk);
    end

    wait_0 = 0;

    for( int ii=0; ii<clk_cycles_in_symbol/2; ii++ ) @(posedge clk);


    for( int jj=0; jj<8; jj++ ) begin
        for( int ii=0; ii<clk_cycles_in_symbol; ii++ ) @(posedge clk);
        val[jj] = uart_tx;    
        cnt_bit++;
    end

    for( int ii=0; ii<clk_cycles_in_symbol; ii++ ) @(posedge clk);


endtask


logic [31:0]    last_bytes;
logic [31:0]    word_address;
logic [31:0]    word_data;

assign last_bytes   = i_lab_top.last_bytes;
assign word_address = i_lab_top.word_address;
assign word_data    = i_lab_top.word_data;


// Transmitting a simple sequence of characters via UART
task test_seq_uart_p0();

    $display( "test_seq_uart_p0() - start");

    tb_uart_send( 8'hAA );
    // tb_uart_send( 8'h01 );
    // tb_uart_send( 8'h02 );
    // tb_uart_send( 8'h03 );

    $display( "test_seq_uart_p0() - complete");

endtask    

// Transmitting a sequence of characters via UART
task test_seq_uart_p1();

    byte            val[9];
    int             cnt_error=0;
    logic [31:0]    expect_last_bytes;
    logic [31:0]    expect_address;
    logic [31:0]    expect_data;
    
    val[0] = 8'h30;
    val[1] = 8'h31;
    val[2] = 8'h32;
    val[3] = 8'h33;
    val[4] = 8'h34;
    val[5] = 8'h35;
    val[6] = 8'h36;
    val[7] = 8'h37;
    val[8] = 8'h0A;

    expect_last_bytes = { val[5], val[6], val[7], val[8] };
    expect_address    = 32'h0004;
    expect_data       = 32'h01234567;

    $display( "test_seq_uart_p1() - start");

    for( int ii=0; ii<9; ii++ )
        tb_uart_send( val[ii] );
    
    if( last_bytes==expect_last_bytes ) begin
        $display( "last_bytes: %h - Ok", last_bytes );
    end else begin
        $display( "last_bytes: %h  expect: %h - ERROR", last_bytes, expect_last_bytes );
        cnt_error++;
    end

    if( word_address==expect_address ) begin
        $display( "word_address: %h - Ok", word_address );
    end else begin
        $display( "word_address: %h expect: %h - ERROR", word_address, expect_address );
        cnt_error++;
    end

    if( word_data==expect_data ) begin
        $display( "word_data: %h - Ok", word_data );
    end else begin
        $display( "word_data: %h expect: %h - ERROR", word_data, expect_data );
        cnt_error++;
    end

    if( 0==cnt_error )
        test_uart_p1 = 1;

    $display( "test_seq_uart_p1() - complete");

endtask


// Receiving a sequence of characters via UART
task test_seq_uart_p2();

    byte            val[9];
    byte            val_rx[9];
    int             cnt_error=0;
    
    $display( "test_seq_uart_p2() - start");

    val[0] = 8'h30;
    val[1] = 8'h31;
    val[2] = 8'h32;
    val[3] = 8'h33;
    val[4] = 8'h34;
    val[5] = 8'h35;
    val[6] = 8'h36;
    val[7] = 8'h37;
    val[8] = 8'h0A;

    for( int ii=0; ii<9; ii++ ) begin
        tb_uart_receive( val_rx[ii] );
    end

    for( int ii=0; ii<9; ii++ ) begin
        if( val[ii]==val_rx[ii]) begin
            $display( "tb_receive: %2d %h - Ok", ii, val_rx[ii] );
        end else begin
            $display( "tb_receive: %2d %h expect: %h - ERROR", ii, val_rx[ii], val[ii] );
            cnt_error++;
        end
    end

    if( 0==cnt_error )
        test_uart_p2 = 1;

    $display( "test_seq_uart_p2() - complete");

endtask