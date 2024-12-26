# Component descriptions

## tb

The component is the top level of modeling, implemented on the basis of a template https://github.com/DigitalDesignSchool/ce2020labs/tree/master/next_step/dsmv/test_template

Includes the lab_top component - the top level of the laboratory work.

The same test signal key is connected to the sw and key ports of the lab_top component. During simulation, the key signal is used to control the output to the seven-segment indicator.
Depending on the type of the debug board, the output to the seven-segment indicator will be controlled either via the sw signal or via the key signal.

Includes three processes:
* pr_main - defines command line parameters, waits for test completion, outputs test result
* pr_timeout - implements test exit by timeout
* pr_test_case - generates a sequence of test actions

Includes the tb_pkg.svh file, which implements the following procedures:

* test_finish - outputs the test execution result
* test_init - generates initial signal values
* test_seq_key0 - generates a sequence of button presses 0
* test_seq_key1 - generates a sequence of button presses 1
* tb_uart_send - transmits a byte via the uart_rx signal
* tb_uart_receive - receives a byte via the uart_tx signal
* test_seq_uart_p0 - transmits a simple sequence via uart
* test_seq_uart_p1 - transmits a sequence and checks the result of reception inside lab_top
* test_seq_uart_p2 - takes a sequence and compares it to the expected one

## lab_top

The component is the top level of the lab. It is included in the top level component for the selected debug board and in the top level component of the simulation.

Includes config.svh from the labs/common directory

Includes the following components:
* uart_receiver - receiving data via UART
* uart_transmitter - transmitting data via UART
* hex_parser - decoding data
* seven_segment_display - output to the seven-segment display

The pr_case_number process selects the data source for displaying on the seven-segment display

The SIMULATION parameter determines the values ​​of the update_hz and timeout_in_seconds parameters depending on the mode. In the simulation mode, the update rate of the seven-segment display must be higher so that the update process is visible during the simulation session.

## uart_receiver

The component is designed to receive one byte via UART. The component parameters are the clock frequency and the UART transmission speed. Depending on the parameters, the width of the counter, load_counter_value and initial load_counter_value signals is determined.

Basic algorithm:
* determining the 1->0 front for the rx signal
* pause 3/2 period - skipping the start bit and moving to the middle of bit 0
* cycle of receiving eight data bits and one stop bit

The received byte is output to the byte_data signal and is accompanied by the byte_valid signal

To eliminate metastability, the rx signal is passed through two triggers - rx_sync1 and rx_sync

## uart_transmitter

The component is designed to transmit one byte via UART. The component parameters are the clock frequency and the UART transmission speed. Depending on the parameters, the width of the counter, load_counter_value signals and the initial value of load_counter_value are determined.

The byte_ready=1 signal means that one byte is ready to be transferred. The byte_valid=1 signal, provided that byte_ready=1, starts transferring a byte of data.

## hex_parser

The component decodes the codes of the hexadecimal digits '0', '1' ... '9', 'A', 'B', 'C', 'D', 'E', 'F' and the string return code 0x0A. The output signals out_address, out_data and out_valid are generated, which can be used to write data to memory.

The out_address signal increases after all the characters of the word have been received. It is assumed that the sequence of characters is transmitted without pauses. If the pause exceeds the time specified in the timeout_in_seconds parameter, the address counter is reset to zero and begins waiting for the next sequence.

### Sequence example

Input sequence transmitted via UART (terminal view)

```
    01234567
    89ABCDEF
```

Input sequence


|   in_char     |   Symbol  |
|   :----:      |   :----:  |
|   0x30        |   0   |
|   0x31        |   1   |
|   0x32        |   2   |
|   0x33        |   3   |
|   0x34        |   4   |
|   0x35        |   5   |
|   0x36        |   6   |
|   0x37        |   7   |
|   0x0A        |   CR  |
|   0x38        |   8   |
|   0x39        |   9   |
|   0x40        |   A   |
|   0x41        |   B   |
|   0x42        |   C   |
|   0x43        |   D   |
|   0x44        |   E   |
|   0x45        |   F   |
|   0x0A        |   CR  |

Output sequence:

|   out_address |   out_data    |
|   :----:      |   :----:      |
|   0x0000      |   0x01234567  |
|   0x0004      |   0x89ABCDEF  |
