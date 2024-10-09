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

logic ooo_amo, ooo_lock;
logic [31:0] ooo_locked_address;

//OoO Counter Enables
logic ooo_mult_counter_en;
logic ooo_mem_op_counter_en;
logic ooo_flush_counter_en;
logic ooo_rob_full_en;
logic ooo_alu_op_counter_en;
//PPL Counter Enables
logic ppl_mult_counter_en;
logic ppl_mem_op_counter_en;
logic ppl_flush_counter_en;
logic ppl_rob_full_threshold;
logic ppl_alu_op_counter_en;

logic hardware_scheduler_en;
ooo_cpu ooo(
    .clk            (clk),
    .rst            (rst),

    .imem_addr(ooo_imem_addr),
    .input_valid(ooo_input_valid),//i_cache enable
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
    .jalr_done(jalr_done),

    .amo(ooo_amo),
    .address_to_lock(ooo_locked_address),
    .lock(ooo_lock),

    //HW sched ports
    .ooo_mult_counter_en(ooo_mult_counter_en),
    .ooo_mem_op_counter_en(ooo_mem_op_counter_en),
    .ooo_flush_counter_en(ooo_flush_counter_en),
    .ooo_rob_full_en(ooo_rob_full_en),
    .ooo_alu_op_counter_en(ooo_alu_op_counter_en),

    .hardware_scheduler_en(hardware_scheduler_en)

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
    .amo(ppl_amo),

    // Counter Enables - PPL
    .ppl_mult_counter_en(ppl_mult_counter_en),
    .ppl_mem_op_counter_en(ppl_mem_op_counter_en),
    .ppl_flush_counter_en(ppl_flush_counter_en),
    .ppl_rob_full_threshold(ppl_rob_full_threshold),
    .ppl_alu_op_counter_en(ppl_alu_op_counter_en),

    .hardware_scheduler_en(hardware_scheduler_en)
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

    .ooo_locked_address(ooo_locked_address),
    .ooo_lock(ooo_lock),
    .ooo_amo(ooo_amo),

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

hardware_scheduler hw_sch (
    .clk(),
    .rst(),

    // Counter Enables - OOO

    .ooo_mult_counter_en(ooo_mult_counter_en),
    .ooo_mem_op_counter_en(ooo_mem_op_counter_en),
    .ooo_flush_counter_en(ooo_flush_counter_en),
    .ooo_rob_full_en(ooo_rob_full_en),
    .ooo_alu_op_counter_en(ooo_alu_op_counter_en),

    // Counter Enables - PPL
    
    .ppl_mult_counter_en(ppl_mult_counter_en),
    .ppl_mem_op_counter_en(ppl_mem_op_counter_en),
    .ppl_flush_counter_en(ppl_flush_counter_en),
    .ppl_rob_full_threshold(ppl_rob_full_threshold),
    .ppl_alu_op_counter_en(ppl_alu_op_counter_en),

    .hardware_scheduler_en(hardware_scheduler_en)
);

endmodule