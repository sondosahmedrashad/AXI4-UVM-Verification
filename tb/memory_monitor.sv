//============================================================
// Passive Memory Monitor
//============================================================
class memory_monitor extends uvm_monitor;

    `uvm_component_utils(memory_monitor)


    virtual memory_interface.MONITOR vif;

    uvm_analysis_port #(memory_transaction) ap;

    int unsigned monitored_transactions;


    function new(
        string name = "memory_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        ap = new("ap", this);

        monitored_transactions = 0;

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(
            virtual memory_interface.MONITOR
        )::get(
            this,
            "",
            "vif",
            vif
        )) begin

            `uvm_fatal(
                "MEM_MON_NO_VIF",
                "Memory virtual interface was not found"
            )

        end

    endfunction


    //==========================================================
    // Run Phase
    //==========================================================
    task run_phase(uvm_phase phase);

        memory_transaction tr;

        `uvm_info(
            "MEM_MONITOR",
            "Passive memory monitor started",
            UVM_MEDIUM
        )


        forever begin

            @(posedge vif.clk);

            if (!vif.rst_n)
                continue;


            //--------------------------------------------------
            // Memory access detected
            //--------------------------------------------------
            if (vif.mem_en) begin

                tr =
                    memory_transaction::type_id::create(
                        "tr"
                    );

                tr.addr = vif.mem_addr;


                //------------------------------------------------
                // WRITE
                //------------------------------------------------
                if (vif.mem_we) begin

                    tr.op   = memory_transaction::MEM_WRITE;
                    tr.data = vif.mem_wdata;

                    monitored_transactions++;

                    ap.write(tr);

                    `uvm_info(
                        "MEM_MONITOR",
                        $sformatf(
                            "WRITE monitored: addr=0x%0h data=0x%08h",
                            tr.addr,
                            tr.data
                        ),
                        UVM_HIGH
                    )

                end


                //------------------------------------------------
                // READ
                //
                // axi4_memory uses a synchronous read.
                // Sample mem_rdata after the memory NBA update.
                //------------------------------------------------
                else begin

                    tr.op = memory_transaction::MEM_READ;

                    #1step;

                    tr.data = vif.mem_rdata;

                    monitored_transactions++;

                    ap.write(tr);

                    `uvm_info(
                        "MEM_MONITOR",
                        $sformatf(
                            "READ monitored: addr=0x%0h data=0x%08h",
                            tr.addr,
                            tr.data
                        ),
                        UVM_HIGH
                    )

                end

            end

        end

    endtask


    //==========================================================
    // Report Phase
    //==========================================================
    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(
            "MEM_MONITOR_REPORT",
            $sformatf(
                "Total memory accesses monitored = %0d",
                monitored_transactions
            ),
            UVM_LOW
        )

    endfunction

endclass
