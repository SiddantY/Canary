module cpu_top(
    input   logic clk,
    input   logic rst,

    output logic   [31:0]      bmem_addr,
    output logic               bmem_read,
    output logic               bmem_write,
    output logic   [63:0]      bmem_wdata,
    
    input logic               bmem_ready,
    input logic   [31:0]      bmem_raddr,
    input logic   [63:0]      bmem_rdata,
    input logic               bmem_rvalid
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

// AMO INSTRUCTION SIGNALS

logic [31:0] ppl_locked_address;
logic        ppl_lock;

logic ppl_amo;


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
    .dmem_resp(ppl_dmem_resp),

    .locked_address(ppl_locked_address),
    .lock(ppl_lock),
    .amo(ppl_amo)
);

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

    .ppl_locked_address(ppl_locked_address),
    .ppl_lock(ppl_lock),

    .ppl_amo(ppl_amo),

    .bmem_addr(bmem_addr),
    .bmem_read(bmem_read),
    .bmem_write(bmem_write),
    .bmem_wdata(bmem_wdata),
    
    .bmem_ready(bmem_ready),
    .bmem_raddr(bmem_raddr),
    .bmem_rdata(bmem_rdata),
    .bmem_rvalid(bmem_rvalid)
);

endmodule