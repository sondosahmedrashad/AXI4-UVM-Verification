//============================================================
// AXI UVM Scoreboard
//============================================================

class axi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_scoreboard)

    // Receives transactions from AXI monitor
    uvm_analysis_imp #(axi_transaction, axi_scoreboard) analysis_export;

    axi_reference_model ref_model;

    int pass_count;
    int fail_count;


    //==========================================================
    // Constructor
    //==========================================================

    function new(string name = "axi_scoreboard",
                 uvm_component parent = null);

        super.new(name, parent);

        analysis_export = new("analysis_export", this);

        pass_count = 0;
        fail_count = 0;

    endfunction


    //==========================================================
    // Build Phase
    //==========================================================

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        ref_model = axi_reference_model::type_id::create(
            "ref_model"
        );

    endfunction


    //==========================================================
    // Analysis Write Function
    //
    // Called automatically whenever monitor executes:
    //
    //     ap.write(tr);
    //
    //==========================================================

    function void write(axi_transaction tr);

        check_transaction(tr);

    endfunction


    //==========================================================
    // Check Transaction
    //==========================================================

    function void check_transaction(axi_transaction tr);

        bit ok;

        ok = 1'b1;


        //======================================================
        // General LAST Check
        //======================================================

        if (!tr.saw_last) begin

            `uvm_error(
                "AXI_SCB",
                $sformatf(
                    "addr=%0h op=%s: LAST was not observed correctly",
                    tr.addr,
                    tr.op.name()
                )
            )

            ok = 1'b0;

        end


        //======================================================
        // WRITE CHECK
        //======================================================

        if (tr.op == axi_transaction::WRITE) begin

            bit [1:0] exp_response;


            //==================================================
            // Burst Length Check
            //==================================================

            if (tr.data.size() != tr.len + 1) begin

                `uvm_error(
                    "AXI_SCB_WRITE",
                    $sformatf(
                        "addr=%0h burst length mismatch: got %0d beats, expected %0d",
                        tr.addr,
                        tr.data.size(),
                        tr.len + 1
                    )
                )

                ok = 1'b0;

            end


            //==================================================
            // WLAST Check
            //==================================================

            else if (!tr.saw_last) begin

                `uvm_error(
                    "AXI_SCB_WRITE",
                    $sformatf(
                        "addr=%0h WLAST not asserted on final beat",
                        tr.addr
                    )
                )

                ok = 1'b0;

            end


            //==================================================
            // Reference Model Prediction
            //==================================================

            ref_model.predict_write(
                tr,
                exp_response
            );


            //==================================================
            // BRESP Check
            //==================================================

            if (tr.response !== exp_response) begin

                `uvm_error(
                    "AXI_SCB_WRITE",
                    $sformatf(
                        "addr=%0h BRESP mismatch: expected=%0b got=%0b",
                        tr.addr,
                        exp_response,
                        tr.response
                    )
                )

                ok = 1'b0;

            end

        end


        //======================================================
        // READ CHECK
        //======================================================

        else begin

            bit [31:0] exp_rdata[];
            bit [1:0]  exp_response;
            bit [15:0] exp_addrs[];


            //==================================================
            // Reference Model Prediction
            //==================================================

            ref_model.predict_read(
                tr,
                exp_rdata,
                exp_response
            );


            ref_model.expected_addr_sequence(
                tr,
                exp_addrs
            );


            //==================================================
            // Burst Length Check
            //==================================================

            if (tr.read_data.size() != tr.len + 1) begin

                `uvm_error(
                    "AXI_SCB_READ",
                    $sformatf(
                        "addr=%0h burst length mismatch: got %0d beats, expected %0d",
                        tr.addr,
                        tr.read_data.size(),
                        tr.len + 1
                    )
                )

                ok = 1'b0;

            end

            else begin


                //==============================================
                // RLAST Check
                //==============================================

                if (!tr.saw_last) begin

                    `uvm_error(
                        "AXI_SCB_READ",
                        $sformatf(
                            "addr=%0h RLAST not asserted on final beat",
                            tr.addr
                        )
                    )

                    ok = 1'b0;

                end


                //==============================================
                // Read Data Check
                //==============================================

                for (int i = 0;
                     i < tr.read_data.size();
                     i++) begin


                    if (tr.read_data[i] !== exp_rdata[i]) begin

                        `uvm_error(
                            "AXI_SCB_READ",
                            $sformatf(
                                "addr=%0h(base) beat=%0d expected_addr=%0h DATA mismatch: expected=%0h got=%0h",
                                tr.addr,
                                i,
                                exp_addrs[i],
                                exp_rdata[i],
                                tr.read_data[i]
                            )
                        )

                        ok = 1'b0;

                    end

                end

            end


            //==================================================
            // RRESP Check
            //==================================================

            if (tr.response !== exp_response) begin

                `uvm_error(
                    "AXI_SCB_READ",
                    $sformatf(
                        "addr=%0h RRESP mismatch: expected=%0b got=%0b",
                        tr.addr,
                        exp_response,
                        tr.response
                    )
                )

                ok = 1'b0;

            end

        end


        //======================================================
        // PASS / FAIL Counters
        //======================================================

        if (ok) begin

            pass_count++;

            `uvm_info(
                "AXI_SCB_PASS",
                $sformatf(
                    "Transaction PASS: op=%s addr=0x%04h",
                    tr.op.name(),
                    tr.addr
                ),
                UVM_MEDIUM
            )

        end

        else begin

            fail_count++;

        end

    endfunction


    //==========================================================
    // Report Phase
    //==========================================================

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);


        `uvm_info(
            "AXI_SCOREBOARD_REPORT",
            $sformatf(
                "\n=====================================================\n AXI SCOREBOARD FINAL REPORT\n   PASS  = %0d\n   FAIL  = %0d\n   TOTAL = %0d\n=====================================================",
                pass_count,
                fail_count,
                pass_count + fail_count
            ),
            UVM_NONE
        )

    endfunction


endclass
