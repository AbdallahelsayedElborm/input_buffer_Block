
# ==========================================
# ZedBoard - Timing Constraints
# ==========================================

# On-board 100 MHz Clock
set_property PACKAGE_PIN Y9 [get_ports clk]

# Clock I/O Standard
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Clock Definition
# 100 MHz = 10 ns
create_clock -name sys_clk -period 3.1 [get_ports clk]
