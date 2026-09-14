//============================================================
// AXI UVM Test
//============================================================

class axi_test extends uvm_test;

    `uvm_component_utils(axi_test)


    //==========================================================
    // Environment
    //==========================================================

    axi_environment env;


    //==========================================================
    // Test Configuration
    //==========================================================

    int unsigned random_transactions = 20;


    //==========================================================
    // Constructor
    //==========================================================

    function new(
        string name = "axi_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================

    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        //======================================================
        // UVM Factory Override
        //
        // Every request for axi_driver will create
        // axi_driver_delay instead.
        //======================================================

        axi_driver::type_id::set_type_override(
            axi_driver_delay::get_type()
        );


        `uvm_info(
            "AXI_TEST",
            "Factory override: axi_driver -> axi_driver_delay",
            UVM_LOW
        )


        //======================================================
        // Create Environment
        //======================================================

        env =
            axi_environment::type_id::create(
                "env",
                this
            );

    endfunction


    //==========================================================
    // Run Phase
    //==========================================================

    task run_phase(
        uvm_phase phase
    );

        axi_single_write_sequence      single_write_seq;
        axi_single_read_sequence       single_read_seq;
        axi_burst_write_sequence       burst_write_seq;
        axi_burst_read_sequence        burst_read_seq;
        axi_invalid_address_sequence   invalid_addr_seq;
        axi_boundary_cross_sequence    boundary_seq;

        axi_coverage_closure_sequence  coverage_seq;

        axi_memory_coverage_sequence   memory_coverage_seq;


        //======================================================
        // Raise Objection
        //======================================================

        phase.raise_objection(this);


        `uvm_info(
            "AXI_TEST",
            "============================================================",
            UVM_NONE
        )

        `uvm_info(
            "AXI_TEST",
            "AXI UVM VERIFICATION TEST START",
            UVM_NONE
        )

        `uvm_info(
            "AXI_TEST",
            $sformatf(
                "Random transaction count = %0d",
                random_transactions
            ),
            UVM_NONE
        )

        `uvm_info(
            "AXI_TEST",
            "============================================================",
            UVM_NONE
        )


        //======================================================
        // Wait for Reset Release
        //======================================================

        wait (
            env.agent.driver.vif.ARESETn == 1'b1
        );

        repeat (2)
            @(posedge env.agent.driver.vif.ACLK);


        //======================================================
        // Single Write Test
        //======================================================

        single_write_seq =
            axi_single_write_sequence::type_id::create(
                "single_write_seq"
            );

        single_write_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // Single Read Test
        //======================================================

        single_read_seq =
            axi_single_read_sequence::type_id::create(
                "single_read_seq"
            );

        single_read_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // Burst Write Test
        //======================================================

        burst_write_seq =
            axi_burst_write_sequence::type_id::create(
                "burst_write_seq"
            );

        burst_write_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // Burst Read Test
        //======================================================

        burst_read_seq =
            axi_burst_read_sequence::type_id::create(
                "burst_read_seq"
            );

        burst_read_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // Invalid Address Test
        //======================================================

        invalid_addr_seq =
            axi_invalid_address_sequence::type_id::create(
                "invalid_addr_seq"
            );

        invalid_addr_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // 4 KB Boundary Crossing Test
        //======================================================

        boundary_seq =
            axi_boundary_cross_sequence::type_id::create(
                "boundary_seq"
            );

        boundary_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // AXI Functional Coverage Closure Test
        //======================================================

        coverage_seq =
            axi_coverage_closure_sequence::type_id::create(
                "coverage_seq"
            );

        coverage_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // Memory Functional Coverage Closure Test
        //======================================================

        memory_coverage_seq =
            axi_memory_coverage_sequence::type_id::create(
                "memory_coverage_seq"
            );

        memory_coverage_seq.start(
            env.agent.sequencer
        );


        //======================================================
        // Allow Final Monitor / Scoreboard Processing
        //======================================================

        repeat (20)
            @(posedge env.agent.driver.vif.ACLK);


        //======================================================
        // End of Test
        //======================================================

        `uvm_info(
            "AXI_TEST",
            "============================================================",
            UVM_NONE
        )

        `uvm_info(
            "AXI_TEST",
            "AXI UVM VERIFICATION TEST COMPLETE",
            UVM_NONE
        )

        `uvm_info(
            "AXI_TEST",
            $sformatf(
                "Driver processed %0d transactions",
                env.agent.driver.driven_transactions
            ),
            UVM_NONE
        )

        `uvm_info(
            "AXI_TEST",
            "============================================================",
            UVM_NONE
        )


        //======================================================
        // Drop Objection
        //======================================================

        phase.drop_objection(this);

    endtask


endclass