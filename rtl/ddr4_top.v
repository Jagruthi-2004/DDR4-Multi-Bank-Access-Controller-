//DDR4 Controller Design

//=========================
// Top-Level Module
//=========================
module DDR4_mult_bank_access_Controller (
    input wire clk,
    input wire rst_n,
    input wire [31:0] addr,
    input wire [15:0] wdata,
    input wire [1:0] bg_en,
    input wire read_en,
    input wire write_en,

    output wire [15:0] rdata,
    output wire ready,

    output wire [15:0] ddr4_dq,
    output wire [15:0] ddr4_addr,
    output wire [2:0] ddr4_ba,
    output wire [1:0] ddr4_bg,
    output wire ddr4_ras_n,
    output wire ddr4_cas_n,
    output wire ddr4_we_n,
    output wire ddr4_cs_n
);

    // Internal wires for output multiplexing
    wire [15:0] rdata_0, rdata_1, rdata_2, rdata_3;
    wire ready_0, ready_1, ready_2, ready_3;
    wire [15:0] dq_0, dq_1, dq_2, dq_3;
    wire [15:0] addr_0, addr_1, addr_2, addr_3;
    wire [2:0]  ba_0, ba_1, ba_2, ba_3;
    wire [1:0]  bg_0, bg_1, bg_2, bg_3;
    wire ras_0, ras_1, ras_2, ras_3;
    wire cas_0, cas_1, cas_2, cas_3;
    wire we_0, we_1, we_2, we_3;
    wire cs_0, cs_1, cs_2, cs_3;

    wire [3:0] enable = 4'b0001 << bg_en;

    DDR4_Controller Bank_group0 (
        .clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata),
        .read_en(read_en), .write_en(write_en), .enable(enable[0]),
        .rdata(rdata_0), .ready(ready_0), .ddr4_dq(dq_0), .ddr4_addr(addr_0),
        .ddr4_ba(ba_0), .ddr4_bg(bg_0), .ddr4_ras_n(ras_0), .ddr4_cas_n(cas_0),
        .ddr4_we_n(we_0), .ddr4_cs_n(cs_0)
    );

    DDR4_Controller Bank_group1 (
        .clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata),
        .read_en(read_en), .write_en(write_en), .enable(enable[1]),
        .rdata(rdata_1), .ready(ready_1), .ddr4_dq(dq_1), .ddr4_addr(addr_1),
        .ddr4_ba(ba_1), .ddr4_bg(bg_1), .ddr4_ras_n(ras_1), .ddr4_cas_n(cas_1),
        .ddr4_we_n(we_1), .ddr4_cs_n(cs_1)
    );

    DDR4_Controller Bank_group2 (
        .clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata),
        .read_en(read_en), .write_en(write_en), .enable(enable[2]),
        .rdata(rdata_2), .ready(ready_2), .ddr4_dq(dq_2), .ddr4_addr(addr_2),
        .ddr4_ba(ba_2), .ddr4_bg(bg_2), .ddr4_ras_n(ras_2), .ddr4_cas_n(cas_2),
        .ddr4_we_n(we_2), .ddr4_cs_n(cs_2)
    );

    DDR4_Controller Bank_group3 (
        .clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata),
        .read_en(read_en), .write_en(write_en), .enable(enable[3]),
        .rdata(rdata_3), .ready(ready_3), .ddr4_dq(dq_3), .ddr4_addr(addr_3),
        .ddr4_ba(ba_3), .ddr4_bg(bg_3), .ddr4_ras_n(ras_3), .ddr4_cas_n(cas_3),
        .ddr4_we_n(we_3), .ddr4_cs_n(cs_3)
    );

    // Output multiplexing
    assign rdata      = (enable[0]) ? rdata_0 : (enable[1]) ? rdata_1 : (enable[2]) ? rdata_2 : rdata_3;
    assign ready      = (enable[0]) ? ready_0 : (enable[1]) ? ready_1 : (enable[2]) ? ready_2 : ready_3;
    assign ddr4_dq    = (enable[0]) ? dq_0    : (enable[1]) ? dq_1    : (enable[2]) ? dq_2    : dq_3;
    assign ddr4_addr  = (enable[0]) ? addr_0  : (enable[1]) ? addr_1  : (enable[2]) ? addr_2  : addr_3;
    assign ddr4_ba    = (enable[0]) ? ba_0    : (enable[1]) ? ba_1    : (enable[2]) ? ba_2    : ba_3;
    assign ddr4_bg    = (enable[0]) ? bg_0    : (enable[1]) ? bg_1    : (enable[2]) ? bg_2    : bg_3;
    assign ddr4_ras_n = (enable[0]) ? ras_0   : (enable[1]) ? ras_1   : (enable[2]) ? ras_2   : ras_3;
    assign ddr4_cas_n = (enable[0]) ? cas_0   : (enable[1]) ? cas_1   : (enable[2]) ? cas_2   : cas_3;
    assign ddr4_we_n  = (enable[0]) ? we_0    : (enable[1]) ? we_1    : (enable[2]) ? we_2    : we_3;
    assign ddr4_cs_n  = (enable[0]) ? cs_0    : (enable[1]) ? cs_1    : (enable[2]) ? cs_2    : cs_3;

endmodule


//=========================
// DDR4_Controller
//=========================
module DDR4_Controller (
    input wire clk,
    input wire rst_n,
    input wire [31:0] addr,
    input wire [15:0] wdata,
    input wire read_en,
    input wire write_en,
    input wire enable,

    output reg [15:0] rdata,
    output reg ready,

    output reg [15:0] ddr4_dq,
    output reg [15:0] ddr4_addr,
    output reg [2:0]  ddr4_ba,
    output reg [1:0]  ddr4_bg,
    output reg ddr4_ras_n,
    output reg ddr4_cas_n,
    output reg ddr4_we_n,
    output reg ddr4_cs_n
);

    localparam ROW_BITS = 16;
    localparam COL_BITS = 10;
    localparam DATA_WIDTH = 16;

    localparam IDLE = 3'b000, ACTIVATE = 3'b001, READ = 3'b010,
               WRITE = 3'b011, PRECHARGE = 3'b100;

    reg [2:0] state, next_state;
    reg [15:0] row_addr;
    reg [9:0] col_addr;
    reg [2:0] bank_addr;
    reg [1:0] bank_group;

    reg [DATA_WIDTH-1:0] mem [0:(1 << 22) - 1];

    wire [21:0] mem_index = {bank_group, bank_addr, row_addr, col_addr};

    always @(*) begin
        row_addr   = addr[31:16];
        col_addr   = addr[15:6];
        bank_addr  = addr[5:3];
        bank_group = addr[2:1];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (enable)
            state <= next_state;
        else
            state <= IDLE;
    end

    always @(*) begin
        next_state = state;
        ready = 0;
        ddr4_ras_n = 1;
        ddr4_cas_n = 1;
        ddr4_we_n = 1;
        ddr4_cs_n = 1;

        case (state)
            IDLE: begin
                ready = 1;
                if (read_en || write_en)
                    next_state = ACTIVATE;
            end

            ACTIVATE: begin
                ddr4_cs_n = 0;
                ddr4_ras_n = 0;
                ddr4_addr = row_addr;
                ddr4_ba = bank_addr;
                ddr4_bg = bank_group;
                next_state = (read_en) ? READ : WRITE;
            end

            READ: begin
                ddr4_cs_n = 0;
                ddr4_cas_n = 0;
                ddr4_addr = col_addr;
                ddr4_ba = bank_addr;
                ddr4_bg = bank_group;
                rdata = mem[mem_index];
                next_state = PRECHARGE;
            end

            WRITE: begin
                ddr4_cs_n = 0;
                ddr4_we_n = 0;
                ddr4_addr = col_addr;
                ddr4_ba = bank_addr;
                ddr4_bg = bank_group;
                ddr4_dq = wdata;
                mem[mem_index] = wdata;
                next_state = PRECHARGE;
            end

            PRECHARGE: begin
                ddr4_cs_n = 0;
                ddr4_ras_n = 0;
                ddr4_we_n = 0;
                next_state = IDLE;
            end
        endcase
    end
endmodule
