//============================================================
// AXI UVM Driver
//============================================================

class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    // Virtual interface used to drive the DUT
    virtual axi_interface.MASTER vif;

    int unsigned driven_transactions;


    //==========================================================
    // Constructor
    //==========================================================

    function new(
        string name = "axi_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

        driven_transactions = 0;

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================

    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        if (!uvm_config_db#(
                virtual axi_interface.MASTER
            )::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "AXI_DRIVER",
                "Failed to get virtual interface from uvm_config_db"
            )

        end

    endfunction


    //==========================================================
    // Reset Master-Driven Signals
    //==========================================================

    task reset_master_signals();

        vif.AWADDR  <= '0;
        vif.AWLEN   <= '0;
        vif.AWSIZE  <= '0;
        vif.AWVALID <= 1'b0;

        vif.WDATA   <= '0;
        vif.WVALID  <= 1'b0;
        vif.WLAST   <= 1'b0;

        vif.BREADY  <= 1'b0;

        vif.ARADDR  <= '0;
        vif.ARLEN   <= '0;
        vif.ARSIZE  <= '0;
        vif.ARVALID <= 1'b0;

        vif.RREADY  <= 1'b0;

    endtask


    //==========================================================
    // Wait for Reset Release
    //==========================================================

    task wait_for_reset_release();

        reset_master_signals();

        wait (vif.ARESETn === 1'b1);

        @(negedge vif.ACLK);

    endtask


    //==========================================================
    // Drive AXI Write Transaction
    //
    // Declared virtual so derived drivers can override it.
    //==========================================================

    virtual task drive_write(
        axi_transaction tr
    );

        int unsigned beat_count;


        //======================================================
        // AW Channel
        //======================================================

        @(negedge vif.ACLK);

        vif.AWADDR  <= tr.addr;
        vif.AWLEN   <= tr.len;
        vif.AWSIZE  <= tr.size;
        vif.AWVALID <= 1'b1;


        // Hold address/control stable until handshake
        do begin

            @(posedge vif.ACLK);

        end
        while (!(vif.AWVALID && vif.AWREADY));


        @(negedge vif.ACLK);

        vif.AWVALID <= 1'b0;


        //======================================================
        // W Channel
        //======================================================

        beat_count = tr.beats();


        for (int i = 0; i < beat_count; i++) begin

            vif.WDATA  <= tr.data[i];
            vif.WLAST  <= (i == beat_count - 1);
            vif.WVALID <= 1'b1;


            // Hold write data stable until handshake
            do begin

                @(posedge vif.ACLK);

            end
            while (!(vif.WVALID && vif.WREADY));


            @(negedge vif.ACLK);

            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;

        end


        //======================================================
        // B Channel
        //======================================================

        vif.BREADY <= 1'b1;


        do begin

            @(posedge vif.ACLK);

        end
        while (!(vif.BVALID && vif.BREADY));


        tr.response = vif.BRESP;


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b0;


        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "WRITE completed: addr=0x%04h len=%0d size=%0d response=%02b",
                tr.addr,
                tr.len,
                tr.size,
                tr.response
            ),
            UVM_MEDIUM
        )

    endtask


    //==========================================================
    // Drive AXI Read Transaction
    //
    // Declared virtual so derived drivers can override it.
    //==========================================================

    virtual task drive_read(
        axi_transaction tr
    );

        int unsigned beat_index;
        int unsigned expected_beats;


        //======================================================
        // AR Channel
        //======================================================

        @(negedge vif.ACLK);

        vif.ARADDR  <= tr.addr;
        vif.ARLEN   <= tr.len;
        vif.ARSIZE  <= tr.size;
        vif.ARVALID <= 1'b1;

        vif.RREADY  <= 1'b0;


        // Hold address/control until handshake
        do begin

            @(posedge vif.ACLK);

        end
        while (!(vif.ARVALID && vif.ARREADY));


        @(negedge vif.ACLK);

        vif.ARVALID <= 1'b0;


        //======================================================
        // Prepare Read Data Storage
        //======================================================

        expected_beats = tr.beats();

        tr.read_data = new[expected_beats];

        beat_index  = 0;
        tr.saw_last = 1'b0;


        //======================================================
        // R Channel
        //======================================================

        vif.RREADY <= 1'b1;


        while (beat_index < expected_beats) begin

            @(posedge vif.ACLK);


            if (vif.RVALID && vif.RREADY) begin

                tr.read_data[beat_index] = vif.RDATA;
                tr.response              = vif.RRESP;

                if (vif.RLAST)
                    tr.saw_last = 1'b1;

                beat_index++;

            end

        end


        @(negedge vif.ACLK);

        vif.RREADY <= 1'b0;


        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "READ completed: addr=0x%04h len=%0d size=%0d response=%02b",
                tr.addr,
                tr.len,
                tr.size,
                tr.response
            ),
            UVM_MEDIUM
        )

    endtask


    //==========================================================
    // Run Phase
    //==========================================================

    task run_phase(
        uvm_phase phase
    );

        axi_transaction tr;


        wait_for_reset_release();


        `uvm_info(
            "AXI_DRIVER",
            "AXI UVM Driver started",
            UVM_LOW
        )


        forever begin

            //==================================================
            // Request next transaction from Sequencer
            //==================================================

            seq_item_port.get_next_item(tr);


            //==================================================
            // Execute transaction
            //==================================================

            if (tr.op == axi_transaction::WRITE) begin

                drive_write(tr);

            end

            else begin

                drive_read(tr);

            end


            driven_transactions++;


            //==================================================
            // Inform Sequencer that transaction is complete
            //==================================================

            seq_item_port.item_done();

        end

    endtask


    //==========================================================
    // Report Phase
    //==========================================================

    function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);


        `uvm_info(
            "AXI_DRIVER_REPORT",
            $sformatf(
                "Total AXI transactions driven = %0d",
                driven_transactions
            ),
            UVM_LOW
        )

    endfunction


endclass