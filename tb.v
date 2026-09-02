`timescale 1ns / 1ps

module tb_direct_mapped_cache;

    reg         clk;
    reg         rst_n;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg         write_en;

    wire [31:0] rdata;
    wire        hit;

    // Instantiate UUT
    direct_mapped_cache uut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(wdata),
        .write_en(write_en),
        .rdata(rdata),
        .hit(hit)
    );

    // Clock Generator (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n    = 0;
        addr     = 32'h0;
        wdata    = 32'h0;
        write_en = 0;

        #20;
        rst_n = 1;
        #20;

        // ---------------------------------------------------------
        // Test 1: Cold Miss on Address 0x12345080
        // ---------------------------------------------------------
        addr = 32'h12345080; 
        #10;
        $display("[TEST 1] Addr: 0x%h | Hit: %b | Expected: 0 (Miss)", addr, hit);

        // ---------------------------------------------------------
        // Test 2: Line Fill / Write Data to Address 0x12345080
        // ---------------------------------------------------------
        @(posedge clk);
        write_en <= 1'b1;
        wdata    <= 32'hABCD_1234;
        @(posedge clk);
        write_en <= 1'b0;

        // ---------------------------------------------------------
        // Test 3: Read back Address 0x12345080 (Should Hit!)
        // ---------------------------------------------------------
        addr = 32'h12345080;
        #10;
        $display("[TEST 3] Addr: 0x%h | Hit: %b | Data: 0x%h | Expected: Hit with 0xABCD1234", 
                  addr, hit, rdata);

        // ---------------------------------------------------------
        // Test 4: Same Index (0x80), Different Tag (Conflict Miss)
        // ---------------------------------------------------------
        addr = 32'h99999080; // Same index [11:4] = 0x08, Tag changes to 0x99999
        #10;
        $display("[TEST 4] Addr: 0x%h | Hit: %b | Expected: 0 (Conflict Miss)", addr, hit);

        #50;
        $finish;
    end

endmodule
