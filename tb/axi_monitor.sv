//============================================================
// AXI UVM Monitor
//============================================================

class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    virtual axi_interface.MONITOR vif;

    // Sends monitored transactions to scoreboard / coverage
    uvm_analysis_port #(axi_transaction) ap;


    //==========================================================
    // Constructor
    //==========================================================

    function new(string name = "axi_monitor",
                 uvm_component parent = null);

        super.new(name, parent);

        ap = new("ap", this);

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(
                virtual axi_interface.MONITOR
            )::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "AXI_MONITOR",
                "Failed to get virtual interface from uvm_config_db"
            )

        end

    endfunction


    //==========================================================
    // Run Phase
    //==========================================================

    task run_phase(uvm_phase phase);

        fork

            monitor_write();
            monitor_read();

        join

    endtask


    //==========================================================
    // WRITE MONITOR
    //==========================================================

    task monitor_write();

        forever begin

            axi_transaction tr;

            bit [31:0] data_q[$];

            int unsigned expected_beats;
            int unsigned beat_count;

            bit last_seen;
            bit last_on_final_beat;


            //==================================================
            // Capture AW Handshake
            //==================================================

            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.ARESETn &&
                     vif.AWVALID &&
                     vif.AWREADY));


            tr = axi_transaction::type_id::create("write_tr", this);

            tr.op   = axi_transaction::WRITE;
            tr.addr = vif.AWADDR;
            tr.len  = vif.AWLEN;
            tr.size = vif.AWSIZE;


            expected_beats = int'(vif.AWLEN) + 1;

            beat_count         = 0;
            last_seen          = 1'b0;
            last_on_final_beat = 1'b0;

            data_q.delete();


            //==================================================
            // Capture W Beats
            //==================================================

            while (beat_count < expected_beats) begin

                @(posedge vif.ACLK);


                if (!vif.ARESETn) begin

                    `uvm_error(
                        "AXI_MONITOR_WRITE",
                        "Reset occurred during active WRITE transaction"
                    )

                    break;

                end


                if (vif.WVALID && vif.WREADY) begin

                    data_q.push_back(vif.WDATA);


                    if (vif.WLAST) begin

                        last_seen = 1'b1;


                        if (beat_count == expected_beats - 1) begin

                            last_on_final_beat = 1'b1;

                        end
                        else begin

                            `uvm_error(
                                "AXI_MONITOR_WRITE",
                                $sformatf(
                                    "WLAST asserted early: beat=%0d expected_final=%0d",
                                    beat_count,
                                    expected_beats - 1
                                )
                            )

                        end

                    end


                    if ((beat_count == expected_beats - 1) &&
                        !vif.WLAST) begin

                        `uvm_error(
                            "AXI_MONITOR_WRITE",
                            $sformatf(
                                "WLAST missing on final beat %0d",
                                beat_count
                            )
                        )

                    end


                    beat_count++;

                end

            end


            //==================================================
            // Build WRITE Transaction
            //==================================================

            tr.data = new[data_q.size()];

            foreach (data_q[i])
                tr.data[i] = data_q[i];


            tr.saw_last = last_seen &&
                          last_on_final_beat;


            //==================================================
            // Capture B Handshake
            //==================================================

            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.BVALID &&
                     vif.BREADY));


            tr.response = vif.BRESP;


            //==================================================
            // Publish Transaction
            //==================================================

            ap.write(tr);


            `uvm_info(
                "AXI_MONITOR",
                $sformatf(
                    "WRITE monitored: addr=0x%04h len=%0d size=%0d response=%02b",
                    tr.addr,
                    tr.len,
                    tr.size,
                    tr.response
                ),
                UVM_MEDIUM
            )

        end

    endtask


    //==========================================================
    // READ MONITOR
    //==========================================================

    task monitor_read();

        forever begin

            axi_transaction tr;

            bit [31:0] rdata_q[$];

            bit [1:0] last_rresp;

            int unsigned expected_beats;
            int unsigned beat_count;

            bit last_seen;
            bit last_on_final_beat;


            //==================================================
            // Capture AR Handshake
            //==================================================

            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.ARESETn &&
                     vif.ARVALID &&
                     vif.ARREADY));


            tr = axi_transaction::type_id::create("read_tr", this);

            tr.op   = axi_transaction::READ;
            tr.addr = vif.ARADDR;
            tr.len  = vif.ARLEN;
            tr.size = vif.ARSIZE;


            expected_beats = int'(vif.ARLEN) + 1;

            beat_count         = 0;
            last_seen          = 1'b0;
            last_on_final_beat = 1'b0;

            rdata_q.delete();

            last_rresp = 2'b00;


            //==================================================
            // Capture R Beats
            //==================================================

            while (beat_count < expected_beats) begin

                @(posedge vif.ACLK);


                if (!vif.ARESETn) begin

                    `uvm_error(
                        "AXI_MONITOR_READ",
                        "Reset occurred during active READ transaction"
                    )

                    break;

                end


                if (vif.RVALID &&
                    vif.RREADY) begin

                    rdata_q.push_back(vif.RDATA);

                    last_rresp = vif.RRESP;


                    if (vif.RLAST) begin

                        last_seen = 1'b1;


                        if (beat_count == expected_beats - 1) begin

                            last_on_final_beat = 1'b1;

                        end
                        else begin

                            `uvm_error(
                                "AXI_MONITOR_READ",
                                $sformatf(
                                    "RLAST asserted early: beat=%0d expected_final=%0d",
                                    beat_count,
                                    expected_beats - 1
                                )
                            )

                        end

                    end


                    if ((beat_count == expected_beats - 1) &&
                        !vif.RLAST) begin

                        `uvm_error(
                            "AXI_MONITOR_READ",
                            $sformatf(
                                "RLAST missing on final beat %0d",
                                beat_count
                            )
                        )

                    end


                    beat_count++;

                end

            end


            //==================================================
            // Build READ Transaction
            //==================================================

            tr.read_data = new[rdata_q.size()];

            foreach (rdata_q[i])
                tr.read_data[i] = rdata_q[i];


            tr.response = last_rresp;

            tr.saw_last =
                last_seen &&
                last_on_final_beat;


            //==================================================
            // Publish Transaction
            //==================================================

            ap.write(tr);


            `uvm_info(
                "AXI_MONITOR",
                $sformatf(
                    "READ monitored: addr=0x%04h len=%0d size=%0d response=%02b",
                    tr.addr,
                    tr.len,
                    tr.size,
                    tr.response
                ),
                UVM_MEDIUM
            )

        end

    endtask

endclass
