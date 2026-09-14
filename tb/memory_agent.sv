//============================================================
// Passive Memory Agent
//============================================================
class memory_agent extends uvm_agent;

    `uvm_component_utils(memory_agent)


    memory_monitor monitor;


    function new(
        string name = "memory_agent",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        monitor =
            memory_monitor::type_id::create(
                "monitor",
                this
            );

    endfunction

endclass
