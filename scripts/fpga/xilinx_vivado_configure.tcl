
set project_name    "system"
set hw_device       "xc7a100t_0"

open_project "$project_name.xpr"; # open Vivado project
open_hw;                          # open the Hardware Manager
connect_hw_server;                # open a connection to a hardware server
open_hw_target;                   # connect to the board

# set a file to be programmed
set_property PROGRAM.FILE "$project_name.bit" [get_hw_devices $hw_device];

# chip programming
program_hw_devices [get_hw_devices $hw_device]
#refresh_hw_device -update_hw_probes false [lindex [get_hw_devices $hw_device] 0]

# connections and project closing
close_hw_target
disconnect_hw_server
close_hw
close_project
