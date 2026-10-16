# This profile fixes CLOCK1_50 at 50 MHz and the HDMI pixel rate at 25 MHz.
create_clock -name clock1_50 -period 20.000 [get_ports {CLOCK1_50}]

# These registers may disappear in labs that do not consume their outputs.
set slow_clock_regs [get_registers -nowarn {*i_slow_clk_gen*slow_clk_raw}]
if {[get_collection_size $slow_clock_regs] > 0} {
    # The real 1 Hz period exceeds Quartus's 2147483.647 ns time limit.
    # Use a conservative 625 Hz timing model (1.6 ms). The actual divider is
    # 50000000 = 80000 * 625; the odd ratio makes BOTH actual edge polarities
    # subsets of the model's edges. Extra model edges preserve or tighten
    # setup/hold and recovery/removal checks; the RTL still generates 1 Hz.
    create_generated_clock -name lab_slow_clk_model -divide_by 80000 \
        -source [get_ports {CLOCK1_50}] $slow_clock_regs
}

# The inherited I2C divider toggles after counting 0..2500 inclusive.
# Its complete period is 2 * (50_000_000 / 20_000 + 1), not 2500 cycles.
set i2c_clock_regs [get_registers -nowarn {*i_i2c_hdmi_conf*mI2C_CTRL_CLK}]
if {[get_collection_size $i2c_clock_regs] > 0} {
    create_generated_clock -name i2c_controller_clk -divide_by 5002 \
        -source [get_ports {CLOCK1_50}] $i2c_clock_regs
}

set pixel_clock_regs [get_registers -nowarn {*i_vga*clk_en}]
if {[get_collection_size $pixel_clock_regs] > 0} {
    # Model the divider first so the forwarded clock retains its complete
    # register-to-output path latency when checking the ADV7513 interface.
    # After reset, slow_clk_raw rises on the first fast edge and clk_en on the
    # second: keep their 20 ns relative phase for slow-clocked HDMI lab data.
    create_generated_clock -name pixel_clk_internal -divide_by 2 -offset 20.000 \
        -source [get_ports {CLOCK1_50}] $pixel_clock_regs
    create_generated_clock -name hdmi_pixel_clk -divide_by 1 \
        -master_clock pixel_clk_internal -source $pixel_clock_regs \
        [get_ports {HDMI_TX_CLK}]

    # ADV7513 Rev. B datasheet, Table 1: setup 1.8 ns, hold 1.3 ns.
    # Component-only baseline: PCB/data-vs-clock path skew is assumed zero.
    # Board timing closure must account for the actual external path delays.
    set_output_delay -clock hdmi_pixel_clk -max 1.8 \
        [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]
    set_output_delay -clock hdmi_pixel_clk -min -1.3 \
        [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]
}

# The generated Reset Release IP contributes its own internal-clock SDC.
derive_clock_uncertainty

# Human controls and the HDMI interrupt are asynchronous to CLOCK1_50.
set_false_path -from [get_ports {KEY[*] SW[*] HDMI_TX_INT}]
set_false_path -to [get_ports {LEDR[*]}]

# GPIO and low-rate control interfaces have no external timing model here.
# A lab using a synchronous external device must replace these exceptions
# with the interface's input/output delays and clock relationships.
set_false_path -from [get_ports {GPIO_0[*] GPIO_1[*] I2C_SDA}]
set_false_path -to [get_ports {GPIO_0[*] GPIO_1[*] I2C_SCL I2C_SDA}]
set_false_path -to [get_ports {HDMI_I2S0 HDMI_LRCLK HDMI_MCLK HDMI_SCLK}]
