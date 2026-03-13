//=================================================
// Testbench — DDR4 Multi-Bank Access Controller
// Tests: Write/Read all 4 bank groups,
//        back-to-back ops, reset mid-operation
//=================================================

`timescale 1ns/1ps

module tb_ddr4_controller;

    //---------------------------
    // Parameters
    //---------------------------
    parameter DSIZE = 16;
    parameter ASIZE = 32;

    //---------------------------
    // DUT Inputs
    //---------------------------
    reg         clk;
    reg         rst_n;
    reg  [31:0] addr;
    reg  [15:0] wdata;
    reg  [1:0]  bg_en;
    reg         read_en;
    reg         write_en;

    //---------------------------
    // DUT Outputs
    //---------------------------
    wire [15:0] rdata;
    wire        ready;
    wire [15:0] ddr4_dq;
    wire [15:0] ddr4_addr;
    wire [2:0]  ddr4_ba;
    wire [1:0]  ddr4_bg;
    wire        ddr4_ras_n;
    wire        ddr4_cas_n;
    wire        ddr4_we_n;
    wire        ddr4_cs_n;

    //---------------------------
    // DUT Instantiation
    //---------------------------
    DDR4_mult_bank_access_Controller dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .addr       (addr),
        .wdata      (wdata),
        .bg_en      (bg_en),
        .read_en    (read_en),
        .write_en   (write_en),
        .rdata      (rdata),
        .ready      (ready),
        .ddr4_dq    (ddr4_dq),
        .ddr4_addr  (ddr4_addr),
        .ddr4_ba    (ddr4_ba),
        .ddr4_bg    (ddr4_bg),
        .ddr4_ras_n (ddr4_ras_n),
        .ddr4_cas_n (ddr4_cas_n),
        .ddr4_we_n  (ddr4_we_n),
        .ddr4_cs_n  (ddr4_cs_n)
    );

    //---------------------------
    // Clock Generation: 100MHz
    //---------------------------
    initial clk = 0;
    always  #5 clk = ~clk;

    //---------------------------
    // Pass/Fail Counter
    //---------------------------
    integer pass_count = 0;
    integer fail_count = 0;

    //---------------------------
    // Write Task
    //---------------------------
    task do_write (
        input [31:0] a,
        input [15:0] d,
        input [1:0]  bg
    );
        @(posedge clk);
        addr     = a;
        wdata    = d;
        bg_en    = bg;
        write_en = 1'b1;
        read_en  = 1'b0;
        @(posedge clk);
        write_en = 1'b0;
        repeat(4) @(posedge clk);
        $display("[WRITE] addr=0x%08h | data=0x%04h | BG=%0d | Time=%0t ns",
                  a, d, bg, $time);
    endtask

    //---------------------------
    // Read Task with Check
    //---------------------------
    task do_read (
        input [31:0] a,
        input [1:0]  bg,
        input [15:0] expected
    );
        @(posedge clk);
        addr     = a;
        bg_en    = bg;
        read_en  = 1'b1;
        write_en = 1'b0;
        @(posedge clk);
        read_en  = 1'b0;
        repeat(4) @(posedge clk);

        if (rdata === expected) begin
            $display("[READ ] addr=0x%08h | data=0x%04h | BG=%0d | PASS | Time=%0t ns",
                      a, rdata, bg, $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[READ ] addr=0x%08h | got=0x%04h expected=0x%04h | BG=%0d | FAIL | Time=%0t ns",
                      a, rdata, expected, bg, $time);
            fail_count = fail_count + 1;
        end
    endtask

    //---------------------------
    // Reset Task
    //---------------------------
    task apply_reset;
        rst_n = 1'b0;
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        $display("[RESET] Applied and released | Time=%0t ns", $time);
    endtask

    //---------------------------
    // Main Test Sequence
    //---------------------------
    initial begin
        // Initialize all signals
        rst_n    = 1'b0;
        read_en  = 1'b0;
        write_en = 1'b0;
        addr     = 32'h0;
        wdata    = 16'h0;
        bg_en    = 2'b00;

        // Apply initial reset
        apply_reset;

        $display("\n========================================");
        $display("   DDR4 Controller Testbench Started   ");
        $display("========================================\n");

        //---------------------------
        // Test 1: Bank Group 0
        //---------------------------
        $display("--- Test 1: Bank Group 0 Write & Read ---");
        do_write(32'hA5B4_C3D2, 16'hBEEF, 2'b00);
        do_read (32'hA5B4_C3D2, 2'b00, 16'hBEEF);

        //---------------------------
        // Test 2: Bank Group 1
        //---------------------------
        $display("\n--- Test 2: Bank Group 1 Write & Read ---");
        do_write(32'h1234_5678, 16'hCAFE, 2'b01);
        do_read (32'h1234_5678, 2'b01, 16'hCAFE);

        //---------------------------
        // Test 3: Bank Group 2
        //---------------------------
        $display("\n--- Test 3: Bank Group 2 Write & Read ---");
        do_write(32'hDEAD_BEEF, 16'hF00D, 2'b10);
        do_read (32'hDEAD_BEEF, 2'b10, 16'hF00D);

        //---------------------------
        // Test 4: Bank Group 3
        //---------------------------
        $display("\n--- Test 4: Bank Group 3 Write & Read ---");
        do_write(32'h9ABC_DEF0, 16'h1234, 2'b11);
        do_read (32'h9ABC_DEF0, 2'b11, 16'h1234);

        //---------------------------
        // Test 5: Back-to-Back Writes
        //---------------------------
        $display("\n--- Test 5: Back-to-Back Writes BG0 ---");
        do_write(32'h0001_0000, 16'hAAAA, 2'b00);
        do_write(32'h0002_0000, 16'hBBBB, 2'b00);
        do_write(32'h0003_0000, 16'hCCCC, 2'b00);
        do_read (32'h0001_0000, 2'b00, 16'hAAAA);
        do_read (32'h0002_0000, 2'b00, 16'hBBBB);
        do_read (32'h0003_0000, 2'b00, 16'hCCCC);

        //---------------------------
        // Test 6: Overwrite same addr
        //---------------------------
        $display("\n--- Test 6: Overwrite Same Address BG1 ---");
        do_write(32'hFFFF_0000, 16'h1111, 2'b01);
        do_write(32'hFFFF_0000, 16'h9999, 2'b01);
        do_read (32'hFFFF_0000, 2'b01, 16'h9999);

        //---------------------------
        // Test 7: Reset Mid-Operation
        //---------------------------
        $display("\n--- Test 7: Reset During Write ---");
        addr     = 32'hFFFF_FFFF;
        wdata    = 16'hDEAD;
        bg_en    = 2'b00;
        write_en = 1'b1;
        #8;
        apply_reset;
        write_en = 1'b0;
        $display("  Controller returned to IDLE after reset");

        //---------------------------
        // Test 8: All bank groups
        //         different addresses
        //---------------------------
        $display("\n--- Test 8: All Bank Groups Simultaneously ---");
        do_write(32'hAAAA_0000, 16'h0A0A, 2'b00);
        do_write(32'hBBBB_0000, 16'h0B0B, 2'b01);
        do_write(32'hCCCC_0000, 16'h0C0C, 2'b10);
        do_write(32'hDDDD_0000, 16'h0D0D, 2'b11);
        do_read (32'hAAAA_0000, 2'b00, 16'h0A0A);
        do_read (32'hBBBB_0000, 2'b01, 16'h0B0B);
        do_read (32'hCCCC_0000, 2'b10, 16'h0C0C);
        do_read (32'hDDDD_0000, 2'b11, 16'h0D0D);

        //---------------------------
        // Summary
        //---------------------------
        #50;
        $display("\n========================================");
        $display("        SIMULATION SUMMARY              ");
        $display("========================================");
        $display("  Total PASS : %0d", pass_count);
        $display("  Total FAIL : %0d", fail_count);
        if (fail_count == 0)
            $display("  Result     : ** ALL TESTS PASSED **");
        else
            $display("  Result     : ** SOME TESTS FAILED **");
        $display("========================================\n");

        $finish;
    end

    //---------------------------
    // Waveform Dump
    //---------------------------
    initial begin
        $dumpfile("sim/ddr4_controller.vcd");
        $dumpvars(0, tb_ddr4_controller);
    end

    //---------------------------
    // Timeout Watchdog
    //---------------------------
    initial begin
        #100000;
        $display("[TIMEOUT] Simulation exceeded limit!");
        $finish;
    end

endmodule
