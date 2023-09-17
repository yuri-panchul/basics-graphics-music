create_clock -period 20 [get_ports clkin_50]

derive_clock_uncertainty

set_false_path -from [get_ports {user_pb[*]}    ] -to [all_clocks]
set_false_path -from [get_ports {user_dipsw[*]} ] -to [all_clocks]

set_false_path -from * -to [get_ports {led[*]}]

set_false_path -from * -to seven_seg_a
set_false_path -from * -to seven_seg_b
set_false_path -from * -to seven_seg_c
set_false_path -from * -to seven_seg_d
set_false_path -from * -to seven_seg_e
set_false_path -from * -to seven_seg_f
set_false_path -from * -to seven_seg_g
set_false_path -from * -to seven_seg_dp
set_false_path -from * -to seven_seg_minus
set_false_path -from * -to seven_seg_sel

set_false_path -from * -to speaker_out
