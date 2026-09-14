//============================================================
// AXI UVM Testbench Top
//============================================================

module axi_tb_top;

    import uvm_pkg::*;
    import axi_uvm_pkg::*;

    `include "uvm_macros.svh"


    //==========================================================
    // Clock and Reset
    //==========================================================

    logic ACLK;
    logic ARESETn;


    //==========================================================
    // AXI Interface
    //==========================================================

    axi_interface axi_if (
        .ACLK    (ACLK),
        .ARESETn (ARESETn)
    );


    //==========================================================
    // Passive Memory Interface
    //==========================================================

    memory_interface #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (10)
    ) mem_if (
        .clk   (ACLK),
        .rst_n (ARESETn)
    );


    //==========================================================
    // DUT
    //==========================================================

    axi4 dut (

        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        //======================================================
        // AXI Write Address Channel
        //======================================================

        .AWADDR  (axi_if.AWADDR),
        .AWLEN   (axi_if.AWLEN),
        .AWSIZE  (axi_if.AWSIZE),
        .AWVALID (axi_if.AWVALID),
        .AWREADY (axi_if.AWREADY),

        //======================================================
        // AXI Write Data Channel
        //======================================================

        .WDATA   (axi_if.WDATA),
        .WVALID  (axi_if.WVALID),
        .WREADY  (axi_if.WREADY),
        .WLAST   (axi_if.WLAST),

        //======================================================
        // AXI Write Response Channel
        //======================================================

        .BRESP   (axi_if.BRESP),
        .BVALID  (axi_if.BVALID),
        .BREADY  (axi_if.BREADY),

        //======================================================
        // AXI Read Address Channel
        //======================================================

        .ARADDR  (axi_if.ARADDR),
        .ARLEN   (axi_if.ARLEN),
        .ARSIZE  (axi_if.ARSIZE),
        .ARVALID (axi_if.ARVALID),
        .ARREADY (axi_if.ARREADY),

        //======================================================
        // AXI Read Data Channel
        //======================================================

        .RDATA   (axi_if.RDATA),
        .RRESP   (axi_if.RRESP),
        .RVALID  (axi_if.RVALID),
        .RREADY  (axi_if.RREADY),
        .RLAST   (axi_if.RLAST)

    );


    //==========================================================
    // AXI Assertions
    //
    // The assertions observe the same AXI signals connected
    // between the UVM driver and the DUT.
    //==========================================================

    axi_assertions axi_assertions_inst (

        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        //======================================================
        // Write Address Channel
        //======================================================

        .AWADDR  (axi_if.AWADDR),
        .AWLEN   (axi_if.AWLEN),
        .AWSIZE  (axi_if.AWSIZE),
        .AWVALID (axi_if.AWVALID),
        .AWREADY (axi_if.AWREADY),

        //======================================================
        // Write Data Channel
        //======================================================

        .WDATA   (axi_if.WDATA),
        .WVALID  (axi_if.WVALID),
        .WREADY  (axi_if.WREADY),
        .WLAST   (axi_if.WLAST),

        //======================================================
        // Write Response Channel
        //======================================================

        .BVALID  (axi_if.BVALID),
        .BREADY  (axi_if.BREADY),

        //======================================================
        // Read Address Channel
        //======================================================

        .ARADDR  (axi_if.ARADDR),
        .ARLEN   (axi_if.ARLEN),
        .ARSIZE  (axi_if.ARSIZE),
        .ARVALID (axi_if.ARVALID),
        .ARREADY (axi_if.ARREADY),

        //======================================================
        // Read Data Channel
        //======================================================

        .RVALID  (axi_if.RVALID),
        .RREADY  (axi_if.RREADY),
        .RLAST   (axi_if.RLAST)

    );


    //==========================================================
    // Passive Observation of Internal DUT Memory Signals
    //
    // These assignments only observe the internal memory-side
    // DUT signals. The UVM memory agent does not drive them.
    //==========================================================

    assign mem_if.mem_en    = dut.mem_en;
    assign mem_if.mem_we    = dut.mem_we;
    assign mem_if.mem_addr  = dut.mem_addr;
    assign mem_if.mem_wdata = dut.mem_wdata;
    assign mem_if.mem_rdata = dut.mem_rdata;


    //==========================================================
    // Clock Generation
    //
    // 10 ns period
    //==========================================================

    initial begin

        ACLK = 1'b0;

        forever
            #5 ACLK = ~ACLK;

    end


    //==========================================================
    // Reset Generation
    //==========================================================

    initial begin

        ARESETn = 1'b0;

        repeat (5)
            @(posedge ACLK);

        ARESETn = 1'b1;

    end


    //==========================================================
    // UVM Configuration and Test Start
    //==========================================================

    initial begin


        //======================================================
        // AXI Driver Virtual Interface
        //======================================================

        uvm_config_db#(
            virtual axi_interface.MASTER
        )::set(
            null,
            "uvm_test_top.env.agent.driver",
            "vif",
            axi_if
        );


        //======================================================
        // AXI Monitor Virtual Interface
        //======================================================

        uvm_config_db#(
            virtual axi_interface.MONITOR
        )::set(
            null,
            "uvm_test_top.env.agent.monitor",
            "vif",
            axi_if
        );


        //======================================================
        // Passive Memory Monitor Virtual Interface
        //======================================================

        uvm_config_db#(
            virtual memory_interface.MONITOR
        )::set(
            null,
            "uvm_test_top.env.mem_agent.monitor",
            "vif",
            mem_if
        );


        //======================================================
        // Start UVM Test
        //======================================================

        run_test("axi_test");

    end


endmodule