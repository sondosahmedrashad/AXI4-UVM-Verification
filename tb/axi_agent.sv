//============================================================
// AXI UVM Agent
//============================================================

class axi_agent extends uvm_agent;

    `uvm_component_utils(axi_agent)

    axi_sequencer sequencer;
    axi_driver    driver;
    axi_monitor   monitor;


    //==========================================================
    // Constructor
    //==========================================================

    function new(string name = "axi_agent",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        // Monitor is always created
        monitor = axi_monitor::type_id::create(
            "monitor",
            this
        );


        // Driver + Sequencer only when agent is ACTIVE
        if (get_is_active() == UVM_ACTIVE) begin

            sequencer = axi_sequencer::type_id::create(
                "sequencer",
                this
            );

            driver = axi_driver::type_id::create(
                "driver",
                this
            );

        end

    endfunction


    //==========================================================
    // Connect Phase
    //==========================================================

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);


        if (get_is_active() == UVM_ACTIVE) begin

            driver.seq_item_port.connect(
                sequencer.seq_item_export
            );

        end

    endfunction


endclass
