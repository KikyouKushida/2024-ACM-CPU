// RISCV32 CPU top module
// Port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,         // System clock signal
  input  wire                 rst_in,         // Reset signal
  input  wire                 rdy_in,         // Ready signal, pause CPU when low

  input  wire [ 7:0]          mem_din,        // Data input bus
  output reg  [ 7:0]          mem_dout,       // Data output bus
  output reg  [31:0]          mem_a,          // Address bus (only 17:0 is used)
  output reg                  mem_wr,         // Write/read signal (1 for write)
  
  input  wire                 io_buffer_full, // 1 if UART buffer is full
  
  output wire [31:0]          dbgreg_dout     // CPU register output (debugging demo)
);

  // Internal registers and wires
  reg [31:0] pc;                               // Program counter
  reg [31:0] registers[0:31];                  // 32 general-purpose registers
  reg [31:0] instruction;                      // Current instruction register
  reg [31:0] clock_count;                      // Clock count register
  reg halt;                                    // CPU halt signal

  // Assign debugging output (e.g., register[0])
  assign dbgreg_dout = registers[0];

  // Memory operation handling
  always @(posedge clk_in) begin
    if (rst_in) begin
      pc <= 0;
      halt <= 0;
      clock_count <= 0;
      mem_a <= 0;
      mem_dout <= 0;
      mem_wr <= 0;
      integer i;
      for (i = 0; i < 32; i = i + 1) begin
        registers[i] <= 0;
      end
    end else if (!rdy_in) begin
      
    end else if (!halt) begin
      
      clock_count <= clock_count + 1;

      mem_a <= pc;
      mem_wr <= 0; 
      instruction <= {24'b0, mem_din};

      //Decode

      //
    end
  end

endmodule
