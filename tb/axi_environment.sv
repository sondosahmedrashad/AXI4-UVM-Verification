//============================================================
// AXI UVM Environment
//============================================================
class axi_environment extends uvm_env;

    `uvm_component_utils(axi_environment)


    //==========================================================
    // Active AXI Verification Components
    //==========================================================

    axi_agent      agent;
    axi_scoreboard scoreboard;
    axi_coverage   coverage;


    //==========================================================
    // Passive Memory Verification Components
    //==========================================================

    memory_agent    mem_agent;
    memory_checker  mem_checker;
    memory_coverage mem_coverage;


    function new(
        string name = "axi_environment",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        //------------------------------------------------------
        // AXI side
        //------------------------------------------------------

        agent =
            axi_agent::type_id::create(
                "agent",
                this
            );

        scoreboard =
            axi_scoreboard::type_id::create(
                "scoreboard",
                this
            );

        coverage =
            axi_coverage::type_id::create(
                "coverage",
                this
            );


        //------------------------------------------------------
        // Memory side
        //------------------------------------------------------

        mem_agent =
            memory_agent::type_id::create(
                "mem_agent",
                this
            );

        mem_checker =
            memory_checker::type_id::create(
                "mem_checker",
                this
            );

        mem_coverage =
            memory_coverage::type_id::create(
                "mem_coverage",
                this
            );

    endfunction


    //==========================================================
    // Connect Phase
    //==========================================================
    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);


        //------------------------------------------------------
        // AXI Monitor connections
        //------------------------------------------------------

        agent.monitor.ap.connect(
            scoreboard.analysis_export
        );

        agent.monitor.ap.connect(
            coverage.analysis_export
        );


        //------------------------------------------------------
        // Passive Memory Monitor connections
        //------------------------------------------------------

        mem_agent.monitor.ap.connect(
            mem_checker.analysis_export
        );

        mem_agent.monitor.ap.connect(
            mem_coverage.analysis_export
        );

    endfunction

endclass