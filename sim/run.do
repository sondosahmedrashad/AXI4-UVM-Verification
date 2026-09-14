# ============================================================
# Locate repository root
# ============================================================

set SCRIPT_DIR   [file dirname [file normalize [info script]]]
set PROJECT_ROOT [file normalize [file join $SCRIPT_DIR ..]]

cd $PROJECT_ROOT


# ============================================================
# Clean work library
# ============================================================

if {[file exists work]} {
    vdel -all
}

vlib work
vmap work work


# ============================================================
# RTL
# ============================================================

vlog -sv +cover=bcesft rtl/axi_memory.v
vlog -sv +cover=bcesft rtl/axi4.v


# ============================================================
# Interfaces
# ============================================================

vlog -sv +incdir+tb tb/axi_interface.sv
vlog -sv +incdir+tb tb/memory_interface.sv


# ============================================================
# Assertions
# ============================================================

vlog -sv +incdir+tb tb/axi_assertions.sv


# ============================================================
# UVM Package
# The package includes the remaining UVM classes
# ============================================================

vlog -sv +incdir+tb tb/axi_uvm_pkg.sv


# ============================================================
# Top-Level Testbench
# ============================================================

vlog -sv +incdir+tb tb/axi_tb_top.sv


# ============================================================
# Simulation
# ============================================================

vsim -coverage \
     -assertcover \
     -voptargs=+acc \
     work.axi_tb_top


# ============================================================
# Run
# ============================================================

run -all


# ============================================================
# Save Coverage
# ============================================================

coverage save sim/axi_uvm_coverage.ucdb


# ============================================================
# Generate Coverage Report
# ============================================================

coverage report \
    -details \
    -output sim/axi_uvm_coverage_report.txt


# ============================================================
# Completion Message
# ============================================================

echo "============================================================"
echo " AXI4 UVM SIMULATION COMPLETED"
echo " Coverage database: sim/axi_uvm_coverage.ucdb"
echo " Coverage report:   sim/axi_uvm_coverage_report.txt"
echo "============================================================"
