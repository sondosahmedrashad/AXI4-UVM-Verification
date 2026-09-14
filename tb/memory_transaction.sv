//============================================================
// Memory Transaction
//============================================================
class memory_transaction extends uvm_sequence_item;

    typedef enum bit {
        MEM_READ  = 1'b0,
        MEM_WRITE = 1'b1
    } mem_op_t;


    mem_op_t op;

    bit [9:0]  addr;
    bit [31:0] data;


    `uvm_object_utils_begin(memory_transaction)

        `uvm_field_enum(
            mem_op_t,
            op,
            UVM_ALL_ON
        )

        `uvm_field_int(
            addr,
            UVM_ALL_ON
        )

        `uvm_field_int(
            data,
            UVM_ALL_ON
        )

    `uvm_object_utils_end


    function new(string name = "memory_transaction");
        super.new(name);
    endfunction

endclass
