//=================================================
// DDR4 Single Bank Group Controller
// FSM: IDLE → ACTIVATE → READ/WRITE → PRECHARGE
//=================================================

module DDR4_Controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [15:0] wdata,
    input  wire        read_en,
    input  wire        write_en,
    input  wire        enable,

    output reg  [15:0] rdata,
    output reg         ready,

    output reg  [15:0] ddr4_dq,
    output reg  [15:0] ddr4_addr,
    output reg  [2:0]  ddr4_ba,
    output reg  [1:0]  ddr4_bg,
    output reg         ddr4_ras_n,
    output reg         ddr4_cas_n,
    output reg         ddr4_we_n,
    output reg         ddr4_cs_n
);

    //---------------------------
    // Parameters
    //---------------------------
    localparam ROW_BITS  = 16;
    localparam COL_BITS  = 10;
    localparam DATA_WIDTH = 16;

    //---------------------------
    // FSM State Encoding
    //---------------------------
    localparam IDLE      = 3'b000,
               ACTIVATE  = 3'b001,
               READ      = 3'b010,
               WRITE     = 3'b011,
               PRECHARGE = 3'b100;

    //---------------------------
    // Internal Registers
    //---------------------------
    reg [2:0] state, next_state;
    reg [15:0] row_addr;
    reg [9:0]  col_addr;
    reg [2:0]  bank_addr;
    reg [1:0]  bank_group;

    //---------------------------
    // Memory Array
    //---------------------------
    reg [DATA_WIDTH-1:0] mem [0:(1 << 22) - 1];

    //---------------------------
    // Memory Index
    //---------------------------
    wire [21:0] mem_index = {bank_group, bank_addr, row_addr[9:0], col_addr};

    //---------------------------
    // Address Decode
    //---------------------------
    always @(*) begin
        row_addr   = addr[31:16];
        col_addr   = addr[15:6];
        bank_addr  = addr[5:3];
        bank_group = addr[2:1];
    end

    //---------------------------
    // State Register
    //---------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (enable)
            state <= next_state;
        else
            state <= IDLE;
    end

    //---------------------------
    // Next State & Output Logic
    //---------------------------
    always @(*) begin
        // Defaults
        next_state = state;
        ready      = 1'b0;
        ddr4_ras_n = 1'b1;
        ddr4_cas_n = 1'b1;
        ddr4_we_n  = 1'b1;
        ddr4_cs_n  = 1'b1;
        ddr4_addr  = 16'b0;
        ddr4_ba    = 3'b0;
        ddr4_bg    = 2'b0;
        ddr4_dq    = 16'b0;
        rdata      = 16'b0;

        case (state)

            //---------------------------
            // IDLE State
            //---------------------------
            IDLE: begin
                ready = 1'b1;
                if (read_en || write_en)
                    next_state = ACTIVATE;
            end

            //---------------------------
            // ACTIVATE State
            // Assert RAS, send row addr
            //---------------------------
            ACTIVATE: begin
                ddr4_cs_n  = 1'b0;
                ddr4_ras_n = 1'b0;
                ddr4_addr  = row_addr;
                ddr4_ba    = bank_addr;
                ddr4_bg    = bank_group;
                next_state = read_en ? READ : WRITE;
            end

            //---------------------------
            // READ State
            // Assert CAS, send col addr
            //---------------------------
            READ: begin
                ddr4_cs_n  = 1'b0;
                ddr4_cas_n = 1'b0;
                ddr4_addr  = {6'b0, col_addr};
                ddr4_ba    = bank_addr;
                ddr4_bg    = bank_group;
                rdata      = mem[mem_index];
                next_state = PRECHARGE;
            end

            //---------------------------
            // WRITE State
            // Assert WE, send col addr
            //---------------------------
            WRITE: begin
                ddr4_cs_n = 1'b0;
                ddr4_we_n = 1'b0;
                ddr4_addr = {6'b0, col_addr};
                ddr4_ba   = bank_addr;
                ddr4_bg   = bank_group;
                ddr4_dq   = wdata;
                mem[mem_index] = wdata;
                next_state = PRECHARGE;
            end

            //---------------------------
            // PRECHARGE State
            // Assert RAS + WE to close row
            //---------------------------
            PRECHARGE: begin
                ddr4_cs_n  = 1'b0;
                ddr4_ras_n = 1'b0;
                ddr4_we_n  = 1'b0;
                next_state = IDLE;
            end

            default: next_state = IDLE;

        endcase
    end

endmodule
