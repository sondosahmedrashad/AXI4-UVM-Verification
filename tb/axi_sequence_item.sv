class axi_transaction extends uvm_sequence_item;

    typedef enum bit {
        READ  = 1'b0,
        WRITE = 1'b1
    } op_t;


    //==========================================================
    // Transaction Fields
    //==========================================================

    rand op_t         op;
    rand bit [15:0]   addr;
    rand bit [7:0]    len;
    rand bit [2:0]    size;
    rand bit [31:0]   data[];


    //==========================================================
    // Fields filled by Driver / Monitor
    //==========================================================

    bit [31:0]        read_data[];
    bit [1:0]         response;
    bit               saw_last;


    //==========================================================
    // Temporary compatibility field
    //
    // In full UVM, this will later be removed because
    // test completion is controlled by UVM phases,
    // sequences and objections.
    //==========================================================

    bit               end_of_test = 0;


    //==========================================================
    // UVM Factory Registration
    //==========================================================

    `uvm_object_utils_begin(axi_transaction)

        `uvm_field_enum(op_t, op, UVM_ALL_ON)

        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(len, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)

        `uvm_field_array_int(data, UVM_ALL_ON)
        `uvm_field_array_int(read_data, UVM_ALL_ON)

        `uvm_field_int(response, UVM_ALL_ON)
        `uvm_field_int(saw_last, UVM_ALL_ON)
        `uvm_field_int(end_of_test, UVM_ALL_ON)

    `uvm_object_utils_end


    //==========================================================
    // Constraints
    //==========================================================

    constraint c_supported_size {

        size inside {[0:2]};

    }


    constraint c_reasonable_len {

        len inside {[0:7]};

    }


    constraint c_data_size {

        data.size() == (len + 1);

    }


    constraint c_alignment {

        (addr % (1 << size)) == 0;

    }


    // Most random traffic stays inside the implemented
    // 4 KB memory window.
    constraint c_mostly_valid_addr {

        addr dist {

            [16'h0000 : 16'h0FFF] :/ 90,
            [16'h1000 : 16'hFFFF] :/ 10

        };

    }


    //==========================================================
    // Constructor
    //==========================================================

    function new(string name = "axi_transaction");

        super.new(name);

    endfunction


    //==========================================================
    // Helper Function
    //
    // AXI LEN encoding:
    //
    // beats = LEN + 1
    //==========================================================

    function int unsigned beats();

        return int'(len) + 1;

    endfunction


    //==========================================================
    // Custom Display
    //==========================================================

    function void display(string tag = "AXI_TR");

        `uvm_info(
            tag,
            $sformatf(
                "op=%s addr=0x%04h len=%0d(beats=%0d) size=%0d response=%02b",
                (op == WRITE) ? "WRITE" : "READ",
                addr,
                len,
                beats(),
                size,
                response
            ),
            UVM_MEDIUM
        )


        if (op == WRITE) begin

            foreach (data[i]) begin

                `uvm_info(
                    tag,
                    $sformatf(
                        "WDATA[%0d] = 0x%08h",
                        i,
                        data[i]
                    ),
                    UVM_MEDIUM
                )

            end

        end
        else begin

            foreach (read_data[i]) begin

                `uvm_info(
                    tag,
                    $sformatf(
                        "RDATA[%0d] = 0x%08h",
                        i,
                        read_data[i]
                    ),
                    UVM_MEDIUM
                )

            end

        end

    endfunction


endclass
