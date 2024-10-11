module cpu_top
import rv32i_types::*;
(
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

rvfi_commit_packet_t committer;
mem_wb_reg_t mem_wb_reg;

logic valid_commit_ooo, valid_commit_ppl;

logic thread_aligned;

logic [63:0] order_ppl;

logic rob_empty;

logic hardware_scheduler_swap_pc;

logic   [31:0]  ppl_data[32];

logic   [31:0]  ooo_data[NUM_REGS];

logic [$clog2(NUM_REGS)-1:0] rrf_arch_to_physical[32];

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

    .rob_empty(rob_empty),

    .ppl_data(ppl_data),
    .data(ooo_data),
    .rrf_arch_to_physical(rrf_arch_to_physical),
    .ppl_order(order_ppl),

    //HW sched ports
    .ooo_mult_counter_en(ooo_mult_counter_en),
    .ooo_mem_op_counter_en(ooo_mem_op_counter_en),
    .ooo_flush_counter_en(ooo_flush_counter_en),
    .ooo_rob_full_en(ooo_rob_full_en),
    .ooo_alu_op_counter_en(ooo_alu_op_counter_en),

    .hardware_scheduler_en(hardware_scheduler_en),

    .hardware_scheduler_swap_pc(hardware_scheduler_swap_pc),
    .hardware_scheduler_pc(mem_wb_reg.rvfi.monitor_pc_wdata - 32'h4),

    .committer(committer),
    .valid_commit_ooo(valid_commit_ooo)
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

    .hardware_scheduler_en(hardware_scheduler_en),
    .hardware_scheduler_swap_pc(hardware_scheduler_swap_pc),
    .hardware_scheduler_pc(committer.pc_wdata),

    .data(ppl_data),
    .ooo_data(ooo_data),
    .rrf_arch_to_physical(rrf_arch_to_physical),
    .ooo_order(committer.order),
    
    .mem_wb_reg(mem_wb_reg),
    .valid_commit_ppl(valid_commit_ppl),
    .order(order_ppl)    
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
    .clk(clk),
    .rst(rst),

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

    .rob_empty(rob_empty),

    .hardware_scheduler_enable(hardware_scheduler_en),
    .hardware_scheduler_swap_pc(hardware_scheduler_swap_pc)
);


always_ff @(posedge clk) begin
    if(rst) begin
        thread_aligned <= 1'b1;
    end else begin
        if(hardware_scheduler_swap_pc) thread_aligned <= ~thread_aligned;
    end
end

// Monitor 0 Sigs
logic monitor_valid;
logic [63:0] monitor_order;
logic [31:0] monitor_inst;
logic [4:0] monitor_rs1_addr;
logic [4:0] monitor_rs2_addr;
logic [31:0] monitor_rs1_rdata;
logic [31:0] monitor_rs2_rdata;
logic [4:0] monitor_rd_addr;
logic [31:0] monitor_rd_wdata;
logic [31:0] monitor_pc_rdata;
logic [31:0] monitor_pc_wdata;
logic [31:0] monitor_mem_addr;
logic [3:0] monitor_mem_rmask;
logic [3:0] monitor_mem_wmask;
logic [31:0] monitor_mem_rdata;
logic [31:0] monitor_mem_wdata;

always_comb
    begin
        if(rst)
            begin
                monitor_valid = '0;
                monitor_order = '0;
                monitor_inst = '0;
                monitor_rs1_addr = '0;
                monitor_rs2_addr = '0;
                monitor_rs1_rdata = '0;
                monitor_rs2_rdata = '0;
                monitor_rd_addr = '0;
                monitor_rd_wdata = '0;
                monitor_pc_rdata = '0;
                monitor_pc_wdata = '0;
                monitor_mem_addr = '0;
                monitor_mem_rmask = '0;
                monitor_mem_wmask = '0;
                monitor_mem_rdata = '0;
                monitor_mem_wdata = '0;
            end
        else
            begin
                monitor_valid = thread_aligned ? valid_commit_ooo : valid_commit_ppl;
                monitor_order = thread_aligned ? committer.order : order_ppl;
                monitor_inst = thread_aligned ? committer.inst : mem_wb_reg.rvfi.monitor_inst;
                monitor_rs1_addr = thread_aligned ? committer.rs1_addr : mem_wb_reg.rvfi.monitor_rs1_addr;
                monitor_rs2_addr = thread_aligned ? committer.rs2_addr : mem_wb_reg.rvfi.monitor_rs2_addr;
                monitor_rs1_rdata = thread_aligned ? committer.rs1_rdata : mem_wb_reg.rvfi.monitor_rs1_rdata;
                monitor_rs2_rdata = thread_aligned ? committer.rs2_rdata : mem_wb_reg.rvfi.monitor_rs2_rdata;
                monitor_rd_addr = thread_aligned ? committer.rd_addr : mem_wb_reg.rvfi.monitor_rd_addr;
                monitor_rd_wdata = thread_aligned ? committer.rd_wdata : mem_wb_reg.rvfi.monitor_rd_wdata;
                monitor_pc_rdata = thread_aligned ? committer.pc_rdata : mem_wb_reg.rvfi.monitor_pc_rdata;
                monitor_pc_wdata = thread_aligned ? committer.pc_wdata : mem_wb_reg.rvfi.monitor_pc_wdata;
                monitor_mem_addr = thread_aligned ? committer.mem_addr : mem_wb_reg.rvfi.monitor_mem_addr;
                monitor_mem_rmask = thread_aligned ? committer.mem_rmask : mem_wb_reg.rvfi.monitor_mem_rmask;
                monitor_mem_wmask = thread_aligned ? committer.mem_wmask : mem_wb_reg.rvfi.monitor_mem_wmask;
                monitor_mem_rdata = thread_aligned ? committer.mem_rdata : mem_wb_reg.rvfi.monitor_mem_rdata;
                monitor_mem_wdata = thread_aligned ? committer.mem_wdata : mem_wb_reg.rvfi.monitor_mem_wdata;
            end
    end

// monitor1 sigs
logic monitor_valid1;
logic [63:0] monitor_order1;
logic [31:0] monitor_inst1;
logic [4:0] monitor_rs1_addr1;
logic [4:0] monitor_rs2_addr1;
logic [31:0] monitor_rs1_rdata1;
logic [31:0] monitor_rs2_rdata1;
logic [4:0] monitor_rd_addr1;
logic [31:0] monitor_rd_wdata1;
logic [31:0] monitor_pc_rdata1;
logic [31:0] monitor_pc_wdata1;
logic [31:0] monitor_mem_addr1;
logic [3:0] monitor_mem_rmask1;
logic [3:0] monitor_mem_wmask1;
logic [31:0] monitor_mem_rdata1;
logic [31:0] monitor_mem_wdata1;

always_comb
    begin : rvfi_signals_ppl
        
        if(rst)
            begin
                monitor_valid1 = '0;
                monitor_order1 = '0;
                monitor_inst1 = '0;
                monitor_rs1_addr1 = '0;
                monitor_rs2_addr1 = '0;
                monitor_rs1_rdata1 = '0;
                monitor_rs2_rdata1 = '0;
                monitor_rd_addr1 = '0;
                monitor_rd_wdata1 = '0;
                monitor_pc_rdata1 = '0;
                monitor_pc_wdata1 = '0;
                monitor_mem_addr1 = '0;
                monitor_mem_rmask1 = '0;
                monitor_mem_wmask1 = '0;
                monitor_mem_rdata1 = '0;
                monitor_mem_wdata1 = '0;
            end
        else
            begin
                monitor_valid1 = thread_aligned ? valid_commit_ppl : valid_commit_ooo;
                monitor_order1 = thread_aligned ? order_ppl : committer.order;
                monitor_inst1 = thread_aligned ? mem_wb_reg.rvfi.monitor_inst : committer.inst;
                monitor_rs1_addr1 = thread_aligned ? mem_wb_reg.rvfi.monitor_rs1_addr : committer.rs1_addr;
                monitor_rs2_addr1 = thread_aligned ? mem_wb_reg.rvfi.monitor_rs2_addr : committer.rs2_addr;
                monitor_rs1_rdata1 = thread_aligned ? mem_wb_reg.rvfi.monitor_rs1_rdata : committer.rs1_rdata;
                monitor_rs2_rdata1 = thread_aligned ? mem_wb_reg.rvfi.monitor_rs2_rdata : committer.rs2_rdata;
                monitor_rd_addr1 = thread_aligned ? mem_wb_reg.rvfi.monitor_rd_addr : committer.rd_addr;
                monitor_rd_wdata1 = thread_aligned ? mem_wb_reg.rvfi.monitor_rd_wdata : committer.rd_wdata;
                monitor_pc_rdata1 = thread_aligned ? mem_wb_reg.rvfi.monitor_pc_rdata : committer.pc_rdata;
                monitor_pc_wdata1 = thread_aligned ? mem_wb_reg.rvfi.monitor_pc_wdata : committer.pc_wdata;
                monitor_mem_addr1 = thread_aligned ? mem_wb_reg.rvfi.monitor_mem_addr : committer.mem_addr;
                monitor_mem_rmask1 = thread_aligned ? mem_wb_reg.rvfi.monitor_mem_rmask : committer.mem_rmask;
                monitor_mem_wmask1 = thread_aligned ? mem_wb_reg.rvfi.monitor_mem_wmask : committer.mem_wmask;
                monitor_mem_rdata1 = thread_aligned ? mem_wb_reg.rvfi.monitor_mem_rdata : committer.mem_rdata;
                monitor_mem_wdata1 = thread_aligned ? mem_wb_reg.rvfi.monitor_mem_wdata : committer.mem_wdata;
            end

    end : rvfi_signals_ppl

endmodule