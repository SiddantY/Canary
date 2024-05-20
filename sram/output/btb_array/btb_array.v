// OpenRAM SRAM model
// Words: 256
// Word size: 32

module btb_array(
`ifdef USE_POWER_PINS
    vdd,
    gnd,
`endif
// Port 0: W
    clk0,csb0,addr0,din0,
// Port 1: R
    clk1,csb1,addr1,dout1
  );

  parameter DATA_WIDTH = 32 ;
  parameter ADDR_WIDTH = 8 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;

`ifdef USE_POWER_PINS
    inout vdd;
    inout gnd;
`endif
  input  clk0; // clock
  input   csb0; // active low chip select
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  input  clk1; // clock
  input   csb1; // active low chip select
  input [ADDR_WIDTH-1:0]  addr1;
  output [DATA_WIDTH-1:0] dout1;

  reg [DATA_WIDTH-1:0]    mem [0:RAM_DEPTH-1];

  reg [ADDR_WIDTH-1:0]  addr0_reg;
  reg [DATA_WIDTH-1:0]  din0_reg;

  always @(posedge clk0)
  begin
    if( !csb0 ) begin
      addr0_reg <= addr0;
      din0_reg <= din0;
    end
  end

  reg [ADDR_WIDTH-1:0]  addr1_reg;
  reg [DATA_WIDTH-1:0]  dout1;

  always @(posedge clk1)
  begin
    if( !csb1 ) begin
      addr1_reg <= addr1;
    end
  end


  always @ (posedge clk0)
  begin : MEM_WRITE0
    begin
        mem[addr0_reg][31:0] <= din0_reg[31:0];
    end
  end

  always @ (*)
  begin : MEM_READ1
    dout1 = mem[addr1_reg];
  end

endmodule
