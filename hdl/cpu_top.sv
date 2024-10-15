module cpu_top(
    input   logic clk,
    input   logic fpga_clk,
    input   logic rst,

    // Memory -> Controller
    input logic r_en_CPU_to_FPGA_FIFO,                  // FPGA Reads from the CPU to FPGA FIFO
    input logic w_en_FPGA_to_CPU_FIFO,                  // FPGA Writes to FPGA to CPU FIFO

    // Controller -> Memory
    output logic empty_CPU_to_FPGA_FIFO,                // FPGA Uses to determine if CPU has written data
    output logic full_FPGA_to_CPU_FIFO,                 // FPGA Uses to determine if it can write to the FPGA to CPU FIFO

    // Controller <-> Memory
    inout wire [33:0] address_data_bus                  // 32 Bit bi-directional bus + 2 Bits for Metadata, Driven by FPGA to return read memory, Driven by CPU to provide data to be written
);

logic   [31:0]  ooo_imem_addr;
logic           ooo_imem_read;
logic   [31:0]  ooo_imem_rdata;
logic           ooo_imem_resp;
logic   [31:0]  ooo_imem_raddr;
logic           ooo_input_valid;
logic           ooo_imem_stall;

logic   [31:0]  ooo_dmem_addr;
logic   [3:0]   ooo_dmem_rmask;
logic   [3:0]   ooo_dmem_wmask;
logic   [31:0]  ooo_dmem_rdata;
logic   [31:0]  ooo_dmem_wdata;
logic           ooo_dmem_resp;

logic   [31:0]  ppl_imem_addr;
logic   [3:0]   ppl_imem_rmask;
logic   [31:0]  ppl_imem_rdata;
logic           ppl_imem_resp;

logic   [31:0]  ppl_dmem_addr;
logic   [3:0]   ppl_dmem_rmask;
logic   [3:0]   ppl_dmem_wmask;
logic   [31:0]  ppl_dmem_rdata;
logic   [31:0]  ppl_dmem_wdata;
logic           ppl_dmem_resp;

logic flush, jump_en, jalr_done;


logic   [31:0]      bmem_addr;
logic               bmem_read;
logic               bmem_write;
logic   [63:0]      bmem_wdata;

logic               bmem_ready;
logic   [31:0]      bmem_raddr;
logic   [63:0]      bmem_rdata;
logic               bmem_rvalid;

// logic               copy_bmem_ready;
// logic   [31:0]      copy_bmem_raddr;
// logic   [63:0]      copy_bmem_rdata;
// logic               copy_bmem_rvalid;


ooo_cpu ooo(
    .clk            (clk),
    .rst            (rst),

    .imem_addr(ooo_imem_addr),
    .input_valid(ooo_input_valid),
    .imem_stall(ooo_imem_stall),
    .imem_rdata(ooo_imem_rdata),
    .imem_raddr(ooo_imem_raddr),
    .imem_resp(ooo_imem_resp),

    .dmem_addr(ooo_dmem_addr),
    .dmem_rmask(ooo_dmem_rmask),
    .dmem_wmask(ooo_dmem_wmask),
    .dmem_wdata(ooo_dmem_wdata),
    .dmem_rdata(ooo_dmem_rdata),
    .dmem_resp(ooo_dmem_resp),

    .flush(flush),
    .jump_en(jump_en),
    .jalr_done(jalr_done)
);

pipeline_cpu ppl(
    .clk            (clk),
    .rst            (rst),

    .imem_addr(ppl_imem_addr),
    .imem_rmask(ppl_imem_rmask),
    .imem_rdata(ppl_imem_rdata),
    .imem_resp(ppl_imem_resp),

    .dmem_addr(ppl_dmem_addr),
    .dmem_rmask(ppl_dmem_rmask),
    .dmem_wmask(ppl_dmem_wmask),
    .dmem_rdata(ppl_dmem_rdata),
    .dmem_wdata(ppl_dmem_wdata),
    .dmem_resp(ppl_dmem_resp)
);
logic wburst_counter;
memory memory_unit(
    .clk(clk),
    .rst(rst),

    .flush(flush),
    .jump_en(jump_en),
    .jalr_en(jalr_done),

    .ooo_imem_addr(ooo_imem_addr),
    .ooo_input_valid(ooo_input_valid),
    .ooo_imem_rdata(ooo_imem_rdata),
    .ooo_imem_resp(ooo_imem_resp),
    .ooo_imem_raddr(ooo_imem_raddr),
    .ooo_imem_stall(ooo_imem_stall),

    .ooo_dmem_addr(ooo_dmem_addr),
    .ooo_dmem_rmask(ooo_dmem_rmask),
    .ooo_dmem_wmask(ooo_dmem_wmask),
    .ooo_dmem_rdata(ooo_dmem_rdata),
    .ooo_dmem_wdata(ooo_dmem_wdata),
    .ooo_dmem_resp(ooo_dmem_resp),

    .ppl_imem_addr(ppl_imem_addr),
    .ppl_imem_rmask(ppl_imem_rmask),
    .ppl_imem_rdata(ppl_imem_rdata),
    .ppl_imem_resp(ppl_imem_resp),

    .ppl_dmem_addr(ppl_dmem_addr),
    .ppl_dmem_rmask(ppl_dmem_rmask),
    .ppl_dmem_wmask(ppl_dmem_wmask),
    .ppl_dmem_rdata(ppl_dmem_rdata),
    .ppl_dmem_wdata(ppl_dmem_wdata),
    .ppl_dmem_resp(ppl_dmem_resp),

    .bmem_addr(bmem_addr),
    .bmem_read(bmem_read),
    .bmem_write(bmem_write),
    .bmem_wdata(bmem_wdata),
    
    .bmem_ready(bmem_ready),
    .bmem_raddr(bmem_raddr),
    .bmem_rdata(bmem_rdata),
    .bmem_rvalid(bmem_rvalid),
    .wburst_counter(wburst_counter)
);


fpga_mem_controller fpga_mem_controller(
    .clk(clk),
    .fpga_clk(fpga_clk),
    .rst(rst),

    // Caches -> Controller
    .bmem_addr(bmem_addr),
    .bmem_read(bmem_read),
    .bmem_write(bmem_write),
    .bmem_wdata(bmem_wdata),

    // Controller -> Caches
    .bmem_ready(bmem_ready),
    .bmem_raddr(bmem_raddr),
    .bmem_rdata(bmem_rdata),
    .bmem_rvalid(bmem_rvalid),
    .wburst_counter(wburst_counter),

    // Memory -> Controller
    .r_en_CPU_to_FPGA_FIFO(r_en_CPU_to_FPGA_FIFO),
    .w_en_FPGA_to_CPU_FIFO(w_en_FPGA_to_CPU_FIFO),

    // Controller -> Memory
    .empty_CPU_to_FPGA_FIFO(empty_CPU_to_FPGA_FIFO),
    .full_FPGA_to_CPU_FIFO(full_FPGA_to_CPU_FIFO),

    // Controller <-> Memory
    .address_data_bus(address_data_bus)
);

endmodule