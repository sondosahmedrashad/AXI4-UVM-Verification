# Clean
if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work


#============================================================
# RTL
#============================================================

vlog axi_memory.v
vlog axi4.v


#============================================================
# Interfaces
#============================================================

vlog -sv axi_interface.sv
vlog -sv memory_interface.sv


#============================================================
# Assertions
#============================================================

vlog -sv axi_assertions.sv


#============================================================
# UVM Package
#============================================================

vlog -sv +incdir+. axi_uvm_pkg.sv


#============================================================
# Top
#============================================================

vlog -sv +incdir+. axi_tb_top.sv


#============================================================
# Simulation
#============================================================

vsim -coverage -assertcover -voptargs=+acc work.axi_tb_top


run -all


#============================================================
# Save Coverage
#============================================================

coverage save axi_uvm_coverage.ucdb


coverage report \
    -details \
    -output axi_uvm_coverage_report.txt


echo "============================================================"
echo " AXI4 UVM SIMULATION COMPLETED"
echo " Coverage database: axi_uvm_coverage.ucdb"
echo " Coverage report:   axi_uvm_coverage_report.txt"
echo "============================================================"
