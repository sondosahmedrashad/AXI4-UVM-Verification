//============================================================
// AXI UVM Functional Coverage
//============================================================

class axi_coverage extends uvm_subscriber #(axi_transaction);

    `uvm_component_utils(axi_coverage)


    //==========================================================
    // Coverage Sampling Variables
    //==========================================================

    bit       addr_valid_flag;
    bit       boundary_cross_flag;
    bit [1:0] resp_flag;
    bit       is_write_flag;
    bit [7:0] len_flag;
    bit [2:0] size_flag;


    //==========================================================
    // Covergroup
    //==========================================================

    covergroup cg;

        option.per_instance = 1;


        //======================================================
        // READ / WRITE Operation
        //======================================================

        cp_op: coverpoint is_write_flag {

            bins wr = {1};
            bins rd = {0};

        }


        //======================================================
        // Address Validity
        //======================================================

        cp_addr_valid: coverpoint addr_valid_flag {

            bins valid   = {1};
            bins invalid = {0};

        }


        //======================================================
        // 4 KB Boundary Crossing
        //======================================================

        cp_boundary: coverpoint boundary_cross_flag {

            bins no_cross = {0};
            bins crossed  = {1};

        }


        //======================================================
        // Burst Length
        //======================================================

        cp_len: coverpoint len_flag {

            bins single      = {0};
            bins burst_small = {[1:3]};
            bins burst_mid   = {[4:15]};
            bins burst_large = {[16:255]};

        }


        //======================================================
        // Transfer Size
        //======================================================

        cp_size: coverpoint size_flag {

            bins byte_xfer = {0};
            bins half_xfer = {1};
            bins word_xfer = {2};

            illegal_bins unsupported_size = {[3:7]};

        }


        //======================================================
        // AXI Response
        //======================================================

        cp_resp: coverpoint resp_flag {

            bins okay   = {2'b00};
            bins slverr = {2'b10};

        }


        //======================================================
        // Cross Coverage
        //======================================================

        cx_op_resp:
            cross cp_op, cp_resp;


        cx_op_len:
            cross cp_op, cp_len;


        cx_len_size:
            cross cp_len, cp_size;


        //======================================================
        // Validity vs Response
        //======================================================

        cx_valid_resp:
            cross cp_addr_valid, cp_resp {

                ignore_bins valid_slverr =
                    binsof(cp_addr_valid.valid) &&
                    binsof(cp_resp.slverr);

                ignore_bins invalid_okay =
                    binsof(cp_addr_valid.invalid) &&
                    binsof(cp_resp.okay);

            }


        //======================================================
        // Boundary Crossing vs Response
        //======================================================

        cx_boundary_resp:
            cross cp_boundary, cp_resp {

                ignore_bins crossed_okay =
                    binsof(cp_boundary.crossed) &&
                    binsof(cp_resp.okay);

            }

    endgroup


    //==========================================================
    // Constructor
    //==========================================================

    function new(
        string name = "axi_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

        cg = new();

    endfunction


    //==========================================================
    // Check 4 KB Boundary Crossing
    //==========================================================

    function bit crosses_4kb(
        axi_transaction tr
    );

        int unsigned bytes_per_beat;
        int unsigned total_bytes;
        int unsigned last_addr;


        bytes_per_beat =
            (1 << tr.size);


        total_bytes =
            (tr.len + 1) *
            bytes_per_beat;


        last_addr =
            tr.addr +
            total_bytes -
            1;


        return (
            tr.addr[15:12] !=
            last_addr[15:12]
        );

    endfunction


    //==========================================================
    // Check Address Validity
    //==========================================================

    function bit is_valid_addr(
        axi_transaction tr
    );

        int unsigned bytes_per_beat;
        int unsigned total_bytes;
        int unsigned last_addr;


        bytes_per_beat =
            (1 << tr.size);


        total_bytes =
            (tr.len + 1) *
            bytes_per_beat;


        last_addr =
            tr.addr +
            total_bytes -
            1;


        // Starting address outside memory range
        if ((tr.addr >> 2) >= 1024)
            return 0;


        // End of burst outside memory range
        if ((last_addr >> 2) >= 1024)
            return 0;


        // AXI burst crosses 4 KB boundary
        if (tr.addr[15:12] !=
            last_addr[15:12])
            return 0;


        return 1;

    endfunction


    //==========================================================
    // Analysis Write Function
    //==========================================================

    function void write(
        axi_transaction t
    );


        //======================================================
        // Convert Transaction Fields to Coverage Variables
        //======================================================

        is_write_flag =
            (t.op == axi_transaction::WRITE);


        len_flag =
            t.len;


        size_flag =
            t.size;


        addr_valid_flag =
            is_valid_addr(t);


        boundary_cross_flag =
            crosses_4kb(t);


        resp_flag =
            t.response;


        //======================================================
        // Sample Functional Coverage
        //======================================================

        cg.sample();


        `uvm_info(
            "AXI_COVERAGE",
            $sformatf(
                "Sampled transaction: op=%s addr=0x%04h len=%0d size=%0d resp=%02b coverage=%0.2f%%",
                t.op.name(),
                t.addr,
                t.len,
                t.size,
                t.response,
                cg.get_inst_coverage()
            ),
            UVM_HIGH
        )

    endfunction


    //==========================================================
    // Report Phase
    //==========================================================

    function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);


        `uvm_info(
            "AXI_COVERAGE_REPORT",
            $sformatf(
                "\n=====================================================\n FUNCTIONAL COVERAGE = %0.2f %%\n=====================================================",
                cg.get_inst_coverage()
            ),
            UVM_NONE
        )

    endfunction


endclass