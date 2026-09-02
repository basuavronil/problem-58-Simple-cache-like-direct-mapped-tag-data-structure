// Direct-Mapped Cache Tag/Data Structure (256 Lines x 32-Bit Words)
module direct_mapped_cache (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Request Interface
    input  wire [31:0] addr,       // 32-bit Memory Address
    input  wire [31:0] wdata,      // Data to write into cache on line fill
    input  wire        write_en,   // Line update/fill enable flag
    
    // Cache Response Outputs
    output wire [31:0] rdata,      // Data read from cache
    output wire        hit         // 1 = Hit, 0 = Miss
);

    // Cache Parameters
    localparam LINES     = 256; // 2^8 Lines
    localparam TAG_WIDTH = 20;  // Bits [31:12]
    
    // Address Field Extraction
    wire [19:0] addr_tag   = addr[31:12];
    wire [7:0]  addr_index = addr[11:4];

    // -------------------------------------------------------------
    // Internal Cache Arrays
    // -------------------------------------------------------------
    reg [TAG_WIDTH-1:0] tag_ram  [0:LINES-1]; // Holds 20-bit Tag
    reg [LINES-1:0]     valid_bit;            // Holds 1 Valid Bit per line
    reg [31:0]          data_ram [0:LINES-1]; // Holds 32-bit cached data

    integer i;

    // -------------------------------------------------------------
    // 1. Write / Line Fill Logic
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Clear valid bits on reset
            for (i = 0; i < LINES; i = i + 1) begin
                valid_bit[i] <= 1'b0;
            end
        end else if (write_en) begin
            tag_ram[addr_index]   <= addr_tag;
            data_ram[addr_index]  <= wdata;
            valid_bit[addr_index] <= 1'b1; // Mark entry valid
        end
    end

    // -------------------------------------------------------------
    // 2. Read Multiplexer & Hit Comparison Logic
    // -------------------------------------------------------------
    assign rdata = data_ram[addr_index];
    assign hit = valid_bit[addr_index] && (tag_ram[addr_index] == addr_tag);
endmodule
