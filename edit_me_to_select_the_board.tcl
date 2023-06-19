#!/usr/bin/env tclsh

# Uncomment the line with the board you are working with

# set board de10_lite
# set board omdazz
# set board zeowaa

set file_to_edit [file normalize [info script]]

foreach dir [glob -directory boards -type d *] {
  lappend available_boards [file tail $dir]
}

if {! [info exists board]} {
  puts "[info script]:\
       Uncomment the line with the board you are working with\
       inside the file $file_to_edit.\
       The available boards: $available_boards"
  exit 1
}

if {! ($board in $available_boards)} {
  puts "[info script]: $board is not in available boards: $available_boards"
  exit 1
}
