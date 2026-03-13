//=================================================
// DDR4 Multi-Bank Access Controller — Top Level
// Supports 4 Bank Groups with output multiplexing
//=================================================

module DDR4_mult_bank_access_Controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [15:0] wdata,
    input  wire [1:0]  bg_en,
    input  wire        read_en,
    input  wire        write_en,

    output wire [15:0] rdata,
    output wire        ready,

    output wire [15:0] ddr4_dq,
    output wire [15:0] ddr4_addr,
    output wire [2:0]  ddr4_ba,
    output wire [1:0]  ddr4_bg,
    output wire        ddr4_ras_n,
    output wire        ddr4_cas_n,
    output wire        ddr4_we_n,
    output wire        ddr4_cs_n
);

    //---------------------------
    // Internal wires per group
    //---------------------------
    wire [15:0] rdata_0, rdata_1, rdata_2, rdata_3;
    wire        ready_0, ready_1, ready_2, ready_3;
    wire [15:0] dq_0,   dq_1,   dq_2,   dq_3;
    wire [15:0] addr_0, addr_1, addr_2, addr_3;
    wire [2:0]  ba_0,   ba_1,   ba_2,   ba_3;
    wire [1:0]  bg_0,   bg_1,   bg_2,   bg_3;
    wire        ras_0,  ras_1,  ras_2,  ras_3;
    wire        cas_0,  cas_1,  cas_2,  cas_3;
    wire        we_0,   we_1,   we_2,   we_3;
    wire        cs_0,   cs_1,   cs_2,   cs_3;

    //---------------------------
    // Bank Group Enable Decoder
    //---------------------------
    wire [3:0] enable = 4'b0001 << bg_en;

    //---------------------------
    // Bank Group Instantiations
    //---------------------------
    DDR4_Controller Bank_group0 (
        .clk        (clk),
        .rst_n      (rst_n),
        .addr       (addr),
        .wdata      (wdata),
        .read_en    (read_en),
        .write_en   (write_en),
        .enable     (enable[0]),
        .rdata      (rdata_0),
        .ready      (ready_0),
        .ddr4_dq    (dq_0),
        .ddr4_addr  (addr_0),
        .ddr4_ba    (ba_0),
        .ddr4_bg    (bg_0),
