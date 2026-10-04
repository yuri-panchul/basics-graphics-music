# Query the installed part database only. No project or license checkout is needed.
package require ::quartus::device

set part [lindex $quartus(args) 0]
if {![regexp {^[A-Za-z0-9]+$} $part]} {
    puts stderr "Invalid device identifier"
    exit 1
}

if {[catch {get_part_info -family $part} family] || $family eq ""} {
    puts stderr "Device $part is unavailable in this installation"
    exit 1
}

puts "BGM_DEVICE_SUPPORTED=$part"
exit 0
