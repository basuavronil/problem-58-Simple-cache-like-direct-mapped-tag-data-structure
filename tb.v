`timescale 1ns / 1ps

module direct_mapped_cache_tb;

    reg        clk;
    reg        rst_n;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg        write_en;
    wire [31:0] rdata;
    wire       hit;

    // Instantiate the Direct-Mapped Cache DUT
    direct_mapped_cache uut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(wdata),
        .write_en(write_en),
        .rdata(rdata),
        .hit(hit)
    );

    // Waveform dump configuration for EPWave / GTKWave
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, direct_mapped_cache_tb);
    end

    // Real-time terminal output monitor
    initial begin
        $monitor("[%0t ns] rst_n=%b | addr=0x%h (Tag: 0x%h, Index: %0d) | write_en=%b wdata=0x%h | hit=%b rdata=0x%h",
                 $time, rst_n, addr, addr[31:12], addr[11:4], write_en, wdata, hit, rdata);
    end

    // 100MHz clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // 1. Initialize Signals and Assert Active-Low Reset
        clk      = 0;
        rst_n    = 0; // Assert Active-Low Reset
        addr     = 0;
        wdata    = 0;
        write_en = 0;

        // Hold reset across clock edge to clear valid bits
        @(posedge clk);
        #1;
        rst_n = 1; // Release Reset

        // 2. Test Cache Miss (Read uninitialized address 0x12345040)
        // Tag = 0x12345, Index = 4
        addr = 32'h12345040;
        #5;
        // Expected: hit = 0 (Cache Miss)

        // 3. Write Line Fill into Cache (Store data 0xDEADBEEF at address 0x12345040)
        @(posedge clk);
        write_en = 1;
        wdata    = 32'hDEADBEEF;

        // 4. Disable write & Test Cache Hit on the same address
        @(posedge clk);
        write_en = 0;
        #5;
        // Expected: hit = 1 (Cache Hit), rdata = 0xDEADBEEF

        // 5. Test Tag Conflict (Cache Miss on same index 4, but different Tag 0x99999)
        addr = 32'h99999040; // Same index 4, different tag
        #5;
        // Expected: hit = 0 (Cache Miss due to tag mismatch)

        // 6. Overwrite Index 4 with New Tag 0x99999 and New Data 0xCAFEBABE
        @(posedge clk);
        write_en = 1;
        wdata    = 32'hCAFEBABE;

        @(posedge clk);
        write_en = 0;
        #5;
        // Expected: hit = 1 (Cache Hit), rdata = 0xCAFEBABE

        // 7. Verify Old Address 0x12345040 now results in a Cache Miss (Eviction check)
        addr = 32'h12345040;
        #5;
        // Expected: hit = 0 (Evicted)

        #10;
        $finish;
    end

endmodule
