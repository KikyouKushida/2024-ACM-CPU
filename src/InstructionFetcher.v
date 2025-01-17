module InstFetcher (
    input  wire clk_in,        // clock signal
    input  wire rst_in,      // rst_in signal
    input  wire rdy_in,      // pause when low

    // instruction cache interface
    output wire        fetch_inst,
    output reg  [31:0] current_PC,
    input  wire        inst_valid,
    input  wire [31:0] inst_data,

    // decoder signals
    input  wire        dec_stall,
    input  wire        dec_clear,
    input  wire [31:0] dec_new_PC,
    output reg         inst_valid_out,
    output reg  [31:0] inst_PC,
    output reg  [31:0] fetched_inst,

    input wire        rob_rst_in,
    input wire [31:0] rob_target_PC
);

    // Internal state
    reg fetch_stall;

    // Next PC computation
    wire [31:0] next_PC = rob_rst_in ? rob_target_PC :
                          dec_clear ? dec_new_PC :
                          current_PC + 4;

    always @(posedge clk_in) begin
        if (rst_in) begin
            current_PC <= 0;
            inst_valid_out <= 0;
            inst_PC <= 0;
            fetched_inst <= 0;
            fetch_stall <= 0;
        end
        else if (!rdy_in) begin
            // pause when not rdy_in
        end
        else if (rob_rst_in || (fetch_stall && dec_clear)) begin
            current_PC <= next_PC;
            inst_valid_out <= 0;
            inst_PC <= 0;
            fetched_inst <= 0;
            fetch_stall <= 0;
        end
        else if (inst_valid && inst_data && !fetch_stall && !dec_stall) begin
            current_PC <= next_PC;
            inst_valid_out <= 1;
            inst_PC <= current_PC;
            fetched_inst <= inst_data;

            // Check for control instructions that cause a stall
            case (inst_data[6:0])
                7'b1101111, 7'b1100111, 7'b1100011: begin
                    fetch_stall <= 1;
                end
            endcase
        end
    end

    assign fetch_inst = !fetch_stall;

endmodule
