//============================================================
// AXI UVM Reference Model
//============================================================

class axi_reference_model extends uvm_object;

    `uvm_object_utils(axi_reference_model)

    localparam int DEPTH      = 1024;
    localparam int ADDR_WIDTH = 16;

    bit [31:0] mem_model [0:DEPTH-1];


    //==========================================================
    // Constructor
    //==========================================================

    function new(string name = "axi_reference_model");

        super.new(name);

        reset_model();

    endfunction


    //==========================================================
    // Reset Reference Memory
    //==========================================================

    function void reset_model();

        for (int i = 0; i < DEPTH; i++) begin

            mem_model[i] = '0;

        end

    endfunction


    //==========================================================
    // Check Transaction Validity
    //==========================================================

    function bit is_valid(
        bit [ADDR_WIDTH-1:0] addr,
        bit [7:0]            len,
        bit [2:0]            size
    );

        int unsigned total_bytes;

        bit boundary_cross;
        bit in_range;


        total_bytes =
            (int'(len) + 1) * (1 << size);


        boundary_cross =
            ((addr & 16'h0FFF) + total_bytes)
            > 16'h1000;


        in_range =
            ((addr >> 2) < DEPTH);


        return (
            in_range &&
            !boundary_cross
        );

    endfunction


    //==========================================================
    // Predict WRITE Transaction
    //==========================================================

    function void predict_write(
        axi_transaction tr,
        output bit [1:0] exp_response
    );

        bit [ADDR_WIDTH-1:0] addr;
        bit [ADDR_WIDTH-1:0] incr;

        bit valid;


        addr  = tr.addr;
        incr  = (1 << tr.size);

        valid =
            is_valid(
                tr.addr,
                tr.len,
                tr.size
            );


        if (valid) begin

            foreach (tr.data[i]) begin

                mem_model[addr >> 2] =
                    tr.data[i];

                addr += incr;

            end


            exp_response = 2'b00;

        end

        else begin

            exp_response = 2'b10;

        end

    endfunction


    //==========================================================
    // Predict READ Transaction
    //==========================================================

    function void predict_read(
        axi_transaction tr,

        output bit [31:0] exp_rdata[],
        output bit [1:0]  exp_response
    );

        bit [ADDR_WIDTH-1:0] addr;
        bit [ADDR_WIDTH-1:0] incr;

        bit valid;


        addr  = tr.addr;
        incr  = (1 << tr.size);

        valid =
            is_valid(
                tr.addr,
                tr.len,
                tr.size
            );


        exp_rdata =
            new[tr.len + 1];


        if (valid) begin

            for (int i = 0;
                 i <= tr.len;
                 i++) begin

                exp_rdata[i] =
                    mem_model[addr >> 2];

                addr += incr;

            end


            exp_response = 2'b00;

        end

        else begin

            for (int i = 0;
                 i <= tr.len;
                 i++) begin

                exp_rdata[i] = '0;

            end


            exp_response = 2'b10;

        end

    endfunction


    //==========================================================
    // Generate Expected Address Sequence
    //==========================================================

    function void expected_addr_sequence(
        axi_transaction tr,
        output bit [ADDR_WIDTH-1:0] addrs[]
    );

        bit [ADDR_WIDTH-1:0] addr;
        bit [ADDR_WIDTH-1:0] incr;


        addr = tr.addr;

        incr =
            (1 << tr.size);


        addrs =
            new[tr.len + 1];


        for (int i = 0;
             i <= tr.len;
             i++) begin

            addrs[i] = addr;

            addr += incr;

        end

    endfunction


endclass
