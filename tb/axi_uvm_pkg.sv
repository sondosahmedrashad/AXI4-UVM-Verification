package axi_uvm_pkg;

    import uvm_pkg::*;

    `include "uvm_macros.svh"


    //==========================================================
    // AXI Transaction and Sequences
    //==========================================================

    `include "axi_sequence_item.sv"
    `include "axi_sequence.sv"
    `include "axi_sequencer.sv"


    //==========================================================
    // AXI Active Agent
    //==========================================================

    `include "axi_driver.sv"

    // Derived delayed driver used with UVM factory override
    `include "axi_driver_delay.sv"

    `include "axi_monitor.sv"
    `include "axi_agent.sv"


    //==========================================================
    // AXI Checking and Coverage
    //==========================================================

    `include "axi_reference_model.sv"
    `include "axi_scoreboard.sv"
    `include "axi_coverage.sv"


    //==========================================================
    // Passive Memory Agent
    //==========================================================

    `include "memory_transaction.sv"
    `include "memory_monitor.sv"
    `include "memory_agent.sv"
    `include "memory_checker.sv"
    `include "memory_coverage.sv"


    //==========================================================
    // Environment and Test
    //==========================================================

    `include "axi_environment.sv"
    `include "axi_test.sv"


endpackage