module cpu_top(
    input   logic clk,
    input   logic fpga_clk,
    input   logic rst,

    output logic   [31:0]      bmem_addr,
    output logic               bmem_read,
    output logic               bmem_write,
    output logic   [63:0]      bmem_wdata,
    
    input logic               bmem_ready,
    input logic   [31:0]      bmem_raddr,
    input logic   [63:0]      bmem_rdata,
    input logic               bmem_rvalid,

    // Memory -> Controller
    input logic [31:0] address_data_bus_m_to_c,
    input logic resp_m_to_c,
    input logic r_en,

    // Controller -> Memory
    output logic [31:0] address_data_bus_c_to_m,
    output logic address_on_c_to_m,
    output logic data_on_c_to_m,
    output logic read_en_c_to_m,
    output logic write_en_c_to_m,
    output logic fifo_empty
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


// logic   [31:0]      bmem_addr;
// logic               bmem_read;
// logic               bmem_write;
// logic   [63:0]      bmem_wdata;

// logic               bmem_ready;
// logic   [31:0]      bmem_raddr;
// logic   [63:0]      bmem_rdata;
// logic               bmem_rvalid;

logic               copy_bmem_ready;
logic   [31:0]      copy_bmem_raddr;
logic   [63:0]      copy_bmem_rdata;
logic               copy_bmem_rvalid;


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
    
    .bmem_ready(copy_bmem_ready),
    .bmem_raddr(copy_bmem_raddr),
    .bmem_rdata(copy_bmem_rdata),
    .bmem_rvalid(copy_bmem_rvalid),
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
    .bmem_ready(copy_bmem_ready),
    .bmem_raddr(copy_bmem_raddr),
    .bmem_rdata(copy_bmem_rdata),
    .bmem_rvalid(copy_bmem_rvalid),
    .wburst_counter(wburst_counter),

    // Memory -> Controller
    .address_data_bus_m_to_c(address_data_bus_m_to_c),
    .resp_m_to_c(resp_m_to_c),
    .r_en(r_en),

    // Controller -> Memory
    .address_data_bus_c_to_m(address_data_bus_c_to_m),
    .address_on_c_to_m(address_on_c_to_m),
    .data_on_c_to_m(data_on_c_to_m),
    .read_en_c_to_m(read_en_c_to_m),
    .write_en_c_to_m(write_en_c_to_m),
    .fifo_empty(fifo_empty)
);

endmodule