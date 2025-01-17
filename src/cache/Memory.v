module Memory (
    input  wire clk_in,  // system clock signal
    input  wire rst_in,  // reset signal
    input  wire rdy_in,  // ready signal, pause cpu when low

    input  wire [7:0]  data_in,        // data input bus
    output wire [7:0]  data_out,       // data output bus
    output wire [31:0] addr_bus,       // address bus (only 17:0 is used)
    output wire        write_signal,   // write/read signal (1 for write)
    input  wire        io_full_signal,

    input  wire        task_valid,  // task flag
    input  wire        task_write, // write/read signal (1 for write)
    input  wire [31:0] task_addr,  // target address
    // length encoding: 
    // len[1:0] 0 - byte, 1 - half word, 2 - word
    // len[2]   signed/unsigned
    input  wire [2:0]  task_len,
    input  wire [31:0] task_data,  // data to write
    output reg         task_ready, // operation finished
    output wire [31:0] result_out  // result
);

    function [31:0] compute_result;
        input [2:0] len;
        input [31:0] prior_result;
        input [7:0] data_in;
        case (len)
            3'b000:  compute_result = {24'b0, data_in};
            3'b100:  compute_result = {{24{data_in[7]}}, data_in};
            3'b001:  compute_result = {16'b0, data_in, prior_result[7:0]};
            3'b101:  compute_result = {{16{data_in[7]}}, data_in, prior_result[7:0]};
            3'b010:  compute_result = {data_in, prior_result[23:0]};
            default: compute_result = 0;
        endcase
    endfunction

    reg         active_flag;
    reg  [31:0] current_task_addr;
    reg         current_task_write;
    reg  [2:0]  current_task_len;
    reg  [2:0]  state_cycle;
    reg  [31:0] temp_addr;
    reg  [7:0]  temp_data;
    reg         temp_write_flag;
    reg  [31:0] temp_result;

    wire        is_io_region = task_addr[17:16] == 2'b11;
    wire        can_write    = !(is_io_region && task_write && io_full_signal);

    wire        task_pending = task_valid && !task_ready && can_write;

    wire        immediate    = state_cycle == 0 && task_pending;
    assign write_signal = immediate ? task_write : temp_write_flag;
    assign addr_bus     = immediate ? task_addr : temp_addr;
    assign data_out     = immediate ? task_data[7:0] : temp_data;

    assign result_out = compute_result(current_task_len, temp_result, data_in);

    always @(posedge clk_in) begin
        if (rst_in) begin
            active_flag        <= 0;
            current_task_addr  <= 0;
            current_task_write <= 0;
            current_task_len   <= 0;
            state_cycle        <= 0;
            temp_addr          <= 0;
            temp_data          <= 0;
            temp_write_flag    <= 0;
            temp_result        <= 0;
            task_ready         <= 0;
        end
        else if (rdy_in) begin
            if (task_ready) begin
                task_ready <= 0;
            end
            else begin
                case (state_cycle)
                    3'b000: begin  
                        if (task_pending) begin
                            temp_result      <= task_data;
                            active_flag      <= 1;
                            current_task_len <= task_len;
                            current_task_addr<= task_addr;
                            current_task_write <= task_write;
                            if (task_len[1:0]) begin
                                state_cycle  <= 3'b001;
                                temp_addr    <= task_addr + 1;
                                temp_data    <= task_data[15:8];
                                temp_write_flag <= task_write;
                            end
                            else begin
                                state_cycle  <= 3'b000;
                                temp_addr    <= task_addr[17:16] == 2'b11 ? 0 : task_addr;
                                temp_data    <= 0;
                                temp_write_flag <= 0;
                                task_ready  <= 1;
                            end
                        end
                    end
                    3'b001: begin
                        temp_result[7:0] <= data_in;
                        if (current_task_len[1:0] == 2'b01) begin
                            state_cycle  <= 3'b000;
                            temp_data    <= 0;
                            temp_write_flag <= 0;
                            task_ready  <= 1;
                        end
                        else begin
                            state_cycle  <= 3'b010;
                            temp_addr    <= current_task_addr + 2;
                            temp_data    <= task_data[23:16];
                        end
                    end
                    3'b010: begin
                        temp_result[15:8] <= data_in;
                        temp_addr        <= current_task_addr + 3;
                        temp_data        <= task_data[31:24];
                        state_cycle      <= 3'b011;
                    end
                    3'b011: begin
                        temp_result[23:16] <= data_in;
                        state_cycle       <= 3'b000;
                        temp_data         <= 0;
                        temp_write_flag   <= 0;
                        task_ready        <= 1;
                    end
                endcase
            end
        end
    end

endmodule
