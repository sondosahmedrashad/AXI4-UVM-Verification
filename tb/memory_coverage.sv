//============================================================
// Memory Functional Coverage
//============================================================
class memory_coverage extends uvm_subscriber #(
    memory_transaction
);

    `uvm_component_utils(memory_coverage)


    bit        op_flag;
    bit [9:0]  addr_flag;
    bit [31:0] data_flag;


    //==========================================================
    // Memory Covergroup
    //==========================================================
    covergroup mem_cg;

        option.per_instance = 1;


        //------------------------------------------------------
        // Operation
        //------------------------------------------------------
        cp_op : coverpoint op_flag {

            bins read  = {0};
            bins write = {1};

        }


        //------------------------------------------------------
        // Address regions
        //------------------------------------------------------
        cp_addr : coverpoint addr_flag {

            bins low  = {[0:255]};
            bins mid1 = {[256:511]};
            bins mid2 = {[512:767]};
            bins high = {[768:1023]};

        }


        //------------------------------------------------------
        // Data categories
        //------------------------------------------------------
        cp_data : coverpoint data_flag {

            bins zero = {32'h0000_0000};

            bins all_ones = {32'hFFFF_FFFF};

            bins other = default;

        }


        //------------------------------------------------------
        // Operation x Address
        //------------------------------------------------------
        cx_op_addr : cross cp_op, cp_addr;

    endgroup


    function new(
        string name = "memory_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

        mem_cg = new();

    endfunction


    //==========================================================
    // Receive transaction
    // Questa UVM requires formal argument name t here.
    //==========================================================
    function void write(memory_transaction t);

        op_flag =
            (t.op == memory_transaction::MEM_WRITE);

        addr_flag = t.addr;
        data_flag = t.data;

        mem_cg.sample();

    endfunction


    //==========================================================
    // Report Phase
    //==========================================================
    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(
            "MEM_COVERAGE_REPORT",
            $sformatf(
                {
                    "\n=====================================================\n",
                    " MEMORY FUNCTIONAL COVERAGE = %0.2f %%\n",
                    "====================================================="
                },
                mem_cg.get_inst_coverage()
            ),
            UVM_LOW
        )

    endfunction

endclass
