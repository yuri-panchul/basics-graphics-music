# Build one lab for one Cmod A7 configuration of Claude with Vivado and check
# the result: the clock primitives, TM1638, timing and the bitstream.
#
# vivado -mode batch -nojournal -nolog \
#     -source scripts/tests/build_cmod_a7_35_claude.tcl \
#     -tclargs labs/3_music/3_11_microphone_monitor cmod_a7_35_claude_tiny_vga_640
#
# Run it in an empty directory: it writes the reports and lab.bit there.
# The sources and the include directories are the ones of
# scripts/fpga/xilinx_vivado_synthesize.tcl, which 03_synthesize_for_fpga.bash
# runs. The script prints CMOD_A7_CLAUDE_BUILD_OK on success and stops with an
# error otherwise. test_cmod_a7_35_claude.py runs it when BGM_TEST_VIVADO=1.

if {$argc != 2} {
    error "Expected two arguments: a lab directory and a Cmod A7 configuration"
}

lassign $argv lab_name board_name

set repo  [file normalize [file join [file dirname [info script]] ../..]]
set lab   [file join $repo $lab_name]
set board [file join $repo boards $board_name]

if {! [string match cmod_a7_35*_claude* $board_name] || ! [file isdirectory $board]} {
    error "Not a Cmod A7 configuration of Claude: $board_name"
}

if {! [file exists $lab/lab_top.sv]} {
    error "No lab_top.sv in $lab"
}

source $board/board_specific.tcl

create_project -in_memory -part $part_name
set_param general.maxThreads 2

read_verilog -sv [glob $repo/labs/common/*.sv]

foreach file [glob -nocomplain $lab/*.v $lab/*.sv] {
    if {[file tail $file] ne "tb.sv"} {
        read_verilog -sv $file
    }
}

if {[file exists $lab/filelist.f]} {
    set fp [open $lab/filelist.f r]

    while {[gets $fp line] >= 0} {
        if {$line ne ""} {
            read_verilog -sv $lab/$line
        }
    }

    close $fp
}

read_verilog -sv [glob $repo/peripherals/*.sv]
read_verilog -sv [glob $board/*.sv]
read_xdc $board/board_specific.xdc

synth_design -top board_specific_top -verilog_define XILINX_VIVADO \
             -include_dirs $repo/labs/common -include_dirs $repo/peripherals

# The MMCM is in the configurations with 640 in the name only

set n_mmcm [llength [get_cells -quiet -hier -filter {REF_NAME =~ MMCM* || REF_NAME =~ PLLE*}]]

if {[string match *_no_pll_* $board_name]} {
    set expected_mmcm 0
} else {
    set expected_mmcm 1
}

if {$n_mmcm != $expected_mmcm} {
    error "$n_mmcm MMCM or PLL cells, expected $expected_mmcm"
}

# TM1638 is in the configurations without _no_tm1638 only. The lab may turn
# it off as well, but the shared script does not read the lab's own
# lab_specific_board_config.svh: see the TODO in the README of the board.

set n_tm1638 [llength [get_cells -quiet -hier -filter {NAME =~ *i_tm1638*}]]

if {[string match *_no_tm1638_* $board_name] && $n_tm1638 != 0} {
    error "TM1638 controller cells in a configuration without TM1638"
}

if {! [string match *_no_tm1638_* $board_name] && $n_tm1638 == 0} {
    error "No TM1638 controller cells"
}

if {[llength [get_cells -quiet -hier -filter {PRIMITIVE_SUBGROUP == latch}]] != 0} {
    error "The design has latches"
}

opt_design
place_design
route_design

report_timing_summary -file timing_summary.rpt
report_utilization    -file utilization.rpt
report_drc            -file drc.rpt

set setup_slack [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
set hold_slack  [get_property SLACK [get_timing_paths -delay_type min -max_paths 1]]

if {$setup_slack < 0 || $hold_slack < 0} {
    error "Timing failed: setup slack $setup_slack ns, hold slack $hold_slack ns"
}

write_bitstream -force lab.bit

# Slice LUTs and Slice Registers, as utilization.rpt counts them: one slice
# LUT may hold two LUT cells, so counting the LUT cells gives more

set utilization [report_utilization -return_string]

if {! [regexp {\|\s*Slice LUTs\*?\s*\|\s*(\d+)\s*\|} $utilization -> luts] ||
    ! [regexp {\|\s*Slice Registers\s*\|\s*(\d+)\s*\|} $utilization -> ffs]} {
    error "No Slice LUTs or Slice Registers in the utilization report"
}

puts "CMOD_A7_CLAUDE_BUILD_OK board=$board_name lab=$lab_name mmcm=$n_mmcm tm1638_cells=$n_tm1638 setup_ns=$setup_slack hold_ns=$hold_slack luts=$luts ffs=$ffs"
