# Additional tasks

## Control of data selection for display

Depending on the value of the key signal, the number signal is generated, which is displayed on the seven-segment indicator. The test does not check the correctness of the output to the indicator

It is necessary to form the task test_check_number() that will generate an enumeration of the key signal values ​​and check the formation of the number signal.

## "Hello world!" finite state machine

It is necessary to add a finite state machine that, after reset, will transmit the string "Hello world from <board_name>!" to the UART. After transmitting the string, the machine should work in echo mode, the received bytes are transmitted back to the UART. Instead of <board_name> there should be the name of the debug board.

## Parsing the input sequence

It is necessary to add a finite state machine that will analyze the input sequence.

Requirements:
1. Transmit all received bytes to the UART
2. Detect the key string "what is your name?" in the input sequence
3. When a key string is detected, return the following in response: "I am <board name>"
4. During the response, it is necessary to remember the received bytes and return them after the response is transmitted