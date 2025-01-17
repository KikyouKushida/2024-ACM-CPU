`include "const.v"

module InstuctionCache #(
    parameter int CacheBits = ICACHE_SIZE_BIT
) (
    input  wire clk_in,
    input  wire rst_in,
    input  wire rdy_in,

    input  wire [31:0] addr,
    output wire hit,
    output wire [31:0] data_out,
    input  wire write_enable,
    input  wire [31:0] write_data
);

    localparam int CacheSize = 1 << CacheBits;
    localparam int TagWidth = 30 - CacheBits;

    wire [TagWidth-1:0] addr_tag = addr[31:2+CacheBits];
    wire [CacheBits-1:0] addr_index = addr[2+CacheBits-1:2];

    reg [CacheSize-1:0] entry_valid;
    reg [31:0] data_store [CacheSize-1:0];
    reg [TagWidth-1:0] tag_store [CacheSize-1:0];

    assign hit = entry_valid[addr_index] && (tag_store[addr_index] == addr_tag);
    assign data_out = data_store[addr_index];

    always @(posedge clk_in) begin
        if (rst_in) begin
            integer i;
            for (i = 0; i < CacheSize; i = i + 1) begin
                entry_valid[i] <= 0;
                data_store[i] <= 0;
                tag_store[i] <= 0;
            end
        end
        else if (!rdy_in) begin
            // do nothing
        end
        else if (write_enable) begin
            entry_valid[addr_index] <= 1;
            data_store[addr_index] <= write_data;
            tag_store[addr_index] <= addr_tag;
        end
    end

endmodule
