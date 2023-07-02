[ -z "${setup_source_bash_already_run-}" ] && \
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

is_command_available_or_error quartus_pgm " from Intel FPGA Quartus Prime package"

if [ "$OSTYPE" = "linux-gnu" ]
then
    rules_dir=/etc/udev/rules.d
    rules_file="$script_dir/90-intel-fpga.rules"

    if ! grep -q USB-Blaster $rules_dir/*
    then
        error "No rules for USB Blaster detected in $rules_dir."  \
              "Please put it there and reboot: sudo cp $rules_file $rules_dir"
    fi

    killall jtagd 2>/dev/null || true
fi

quartus_pgm -l &> cable_list

cable_name_1=$(set +o pipefail; grep "1) " cable_list | sed 's/.*1) //')
cable_name_2=$(set +o pipefail; grep "2) " cable_list | sed 's/.*2) //')

if [ -n "${cable_name_1-}" ]
then
    if [ -n "${cable_name_2-}" ]
    then
        warning "more than one cable is connected:" \
                "$cable_name_1 and $cable_name_2"
    fi

    info "using cable $cable_name_1"

    config_file_1=fpga_project.sof
    config_file_2=fpga_project.pof

    config_file=$config_file_1

    if ! [ -f $config_file ]
    then
        config_file=$config_file_2

        if ! [ -f $config_file ]
        then
            error "Neither $config_file_1 nor $config_file_2" \
                  "config file is available"
        fi
    fi

    quartus_pgm --no_banner -c "$cable_name_1" --mode=jtag -o "P;$config_file"
else
    error "cannot detect a USB-Blaster cable connected" \
          "for $fpga_board FPGA board"
fi

rm cable_list
