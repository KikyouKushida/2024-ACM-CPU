module Cache (
    input  wire clk_in,
    input  wire rst_in,
    input  wire rdy_in,

    input  wire [7:0]  mem_din,
    output wire [7:0]  mem_dout,
    output wire [31:0] mem_a,
    output wire        mem_wr,
    input  wire        io_buffer_full,

    input  wire rob_clear,

    input  wire inst_valid,
    input  wire [31:0] PC,
    output wire inst_ready,
    output wire [31:0] inst_res,

    input  wire        data_valid,
    input  wire        data_wr,
    input  wire [2:0]  data_size,
    input  wire [31:0] data_addr,
    input  wire [31:0] data_value,
    output wire        data_ready,
    output wire [31:0] data_res
);

    reg         mc_enable;
    reg         mc_wr;
    reg  [31:0] mc_addr;
    reg  [2:0]  mc_len;
    reg  [31:0] mc_data;
    wire        mc_ready;
    wire [31:0] mc_res;
    wire        inst_hit;
    wire [31:0] inst_result;
    wire        inst_write_enable;

    InstuctionCache i_cache (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .addr(PC),
        .hit(inst_hit),
        .res(inst_result),
        .we(inst_write_enable),
        .data(mc_res)
    );

    MemoryController mem_ctrl (
        .clk_in(clk_in),
        .rst_in(rst_in | rob_clear),
        .rdy_in(rdy_in),

        .mem_din(mem_din),
        .mem_dout(mem_dout),
        .mem_a(mem_a),
        .mem_wr(mem_wr),
        .io_buffer_full(io_buffer_full),

        .valid(mc_enable),
        .wr(mc_wr),
        .addr(mc_addr),
        .len(mc_len),
        .data(mc_data),
        .ready(mc_ready),
        .res(mc_res)
    );

    reg work_state;
    reg operation_type;

    assign data_ready = work_state && operation_type && mc_ready;
    assign data_res = mc_res;
    assign inst_ready = inst_hit;
    assign inst_res = inst_result;
    assign inst_write_enable = work_state && !operation_type && mc_ready;

    always @(posedge clk_in) begin
        if (rst_in | rob_clear) begin
            work_state <= 0;
            operation_type <= 0;
            mc_enable <= 0;
            mc_wr <= 0;
            mc_addr <= 0;
            mc_len <= 0;
            mc_data <= 0;
        end
        else if (!rdy_in) begin
            // do nothing
        end
        else if (!work_state) begin
            if (data_valid) begin
                work_state <= 1;
                operation_type <= 1;
                mc_enable <= 1;
                mc_wr <= data_wr;
                mc_addr <= data_addr;
                mc_len <= data_size;
                mc_data <= data_value;
            end
            else if (inst_valid && !inst_ready) begin
                work_state <= 1;
                operation_type <= 0;
                mc_enable <= 1;
                mc_wr <= 0;
                mc_addr <= PC;
                mc_len <= 3'b010;
                mc_data <= 0;
            end
        end
        else if (mc_ready) begin
            work_state <= 0;
            mc_enable <= 0;
        end
    end

endmodule
