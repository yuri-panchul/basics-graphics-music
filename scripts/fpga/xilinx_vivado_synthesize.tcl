
# path where project will be created
set project_path [pwd]
set script_path [file dirname [file normalize [info script]]]

# global settings
# YURI REMOVE set project_name    "system"
set project_name    "fpga_project"
set project_part    "xc7a100tcsg324-1"
# YURI TO REMOVE set testbench_top   "testbench"

# source files path
#YURI REPLACE set rtl_path $project_path/../rtl
# YURI TO REMOVE set tb_path  $project_path/../tb

# YURI TO REMOVE # load project local settings
# YURI TO REMOVE source $project_path/../run/script_vivado.tcl

# create project
create_project $project_name $project_path -part $project_part -force

# fill 'sources_1' fileset

set sources_1 [list \
[file normalize ../../common/config.svh ]  \
[file normalize ../top.sv]  \
[file normalize ../../../boards/nexys_a7/board_specific_top.sv]  \
]

set_property top "board_specific_top" [get_filesets sources_1]

if {[info exists source_files]} {
    add_files -norecurse -fileset [get_filesets sources_1] $source_files
}

set constrs_1 {
../../../boards/nexys_a7/board_specific.xdc
}

# fill 'constrs_1' fileset
if {[info exists constr_files]} {
    add_files -norecurse -fileset [get_filesets constrs_1] $constr_files
}

# fill 'sim_1' fileset
if {[info exists sim_files]} {
    set obj [get_filesets sim_1]
    add_files -norecurse -fileset $obj $sim_files
    set_property top $testbench_top $obj
}

# define macros VIVADO_SYNTHESIS
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-verilog_define VIVADO_SYNTHESIS} -objects [get_runs synth_1]

puts "INFO: Project created:$project_name"

# YURI NEW LINE
close_project

# YURI REMOVE set project_name  "system"
set synth_task    "synth_1"
set impl_task     "impl_1"
set timing_report "timing_1"

#-----------------------------------------------------------------------------

open_project "$project_name.xpr"

# run synthesis
launch_runs $synth_task
wait_on_run -verbose $synth_task

# run implementation
launch_runs $impl_task
wait_on_run -verbose $impl_task

# write bitstream
open_run $impl_task -name $impl_task
write_bitstream "$project_name.bit"
