`include "config.svh"

// HC-SR04 Ultrasonic Distance Sensor

module ultrasonic_distance_sensor
# (
    parameter clk_frequency           = 50000000,
              relative_distance_width = 8
)
(
    input        clk,
    input        rst,
    output logic trig,
    input        echo,

    output logic [relative_distance_width - 1:0] relative_distance
);

    // Datasheet: http://www.micropik.com/PDF/HCSR04.pdf
    // Time is measured in clk cycles unless noted otherwise

    localparam

        speed_of_sound_meters_per_second   = 343,
        max_range_in_centimeters           = 400,  // From datasheet

        measurement_cycle_in_milliseconds  = 200,  // From datasheet min is 60
        trig_time_in_microseconds          = 10,   // From datasheet

        measurement_cycle_time
            = measurement_cycle_in_milliseconds * (clk_frequency / 1000),

        trig_time
            = trig_time_in_microseconds * (clk_frequency / 1000000),

        echo_clk_cycles_per_centimeters

            =   clk_frequency
              * 2    // Sound wave goes 2 ways
              / speed_of_sound_meters_per_second
              / 100, // Number of centimeters in meter

        max_echo_time
            = max_range_in_centimeters * echo_clk_cycles_per_centimeters,

        // To accomodate values up to measurement_cycle_time - 1
        trig_cnt_width = $clog2 (measurement_cycle_time),

        // To accomodate values up to max_echo_time
        echo_cnt_width = $clog2 (max_echo_time + 1);

    `ifdef SIMULATION_ONLY

    initial
    begin
        $display ( "speed_of_sound_meters_per_second  : %0d", speed_of_sound_meters_per_second  );
        $display ( "max_range_in_centimeters          : %0d", max_range_in_centimeters          );
        $display ( "measurement_cycle_in_milliseconds : %0d", measurement_cycle_in_milliseconds );
        $display ( "trig_time_in_microseconds         : %0d", trig_time_in_microseconds         );
        $display ( "measurement_cycle_time            : %0d", measurement_cycle_time            );
        $display ( "trig_time                         : %0d", trig_time                         );
        $display ( "echo_clk_cycles_per_centimeters   : %0d", echo_clk_cycles_per_centimeters   );
        $display ( "max_echo_time                     : %0d", max_echo_time                     );
        $display ( "trig_cnt_width                    : %0d", trig_cnt_width                    );
        $display ( "echo_cnt_width                    : %0d", echo_cnt_width                    );
    end

    `endif

    logic [trig_cnt_width - 1:0] trig_cnt;

    always @ (posedge clk or posedge rst)
        if (rst)
            trig_cnt <= 0;
        else if (trig_cnt == measurement_cycle_time - 1)
            trig_cnt <= 0;
        else
            trig_cnt <= trig_cnt + 1;

    // We have to wait after rst and after each measurement

    always @ (posedge clk)
        if (rst)
            trig <= 0;
        else if (trig_cnt == measurement_cycle_time - trig_time - 1)
            trig <= 1;
        else if (trig_cnt == measurement_cycle_time - 1)
            trig <= 0;

    logic prev_echo;

    always @ (posedge clk)
        if (rst)
            prev_echo <= 0;
        else
            prev_echo <= echo;

    wire posedge_echo = ~ prev_echo &   echo;
    wire negedge_echo =   prev_echo & ~ echo;

    logic [echo_cnt_width - 1:0] echo_cnt;

    always @ (posedge clk)
        if (rst)
        begin
            echo_cnt          <= 0;
            relative_distance <= 0;
        end
        else if (posedge_echo)
        begin
            echo_cnt <= 0;
        end
        else if (negedge_echo)
        begin
            relative_distance
                <= echo_cnt [   echo_cnt_width - 1
                              : echo_cnt_width - relative_distance_width ];
        end
        else
        begin
            echo_cnt <= echo_cnt + 1;
        end

endmodule
