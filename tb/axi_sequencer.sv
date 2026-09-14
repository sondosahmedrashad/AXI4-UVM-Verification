//============================================================
// AXI UVM Sequencer
//============================================================

class axi_sequencer extends uvm_sequencer #(axi_transaction);

    `uvm_component_utils(axi_sequencer)


    //==========================================================
    // Constructor
    //==========================================================

    function new(string name = "axi_sequencer",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction


endclass
