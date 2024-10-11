module pipeline_cpu
import rv32i_types::*;
(
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp,

    //HW Scheduler Ports
    output   logic           ppl_mult_counter_en,
    output   logic           ppl_mem_op_counter_en,
    output   logic           ppl_flush_counter_en,
    output   logic           ppl_rob_full_threshold,
    output   logic           ppl_alu_op_counter_en,
    
    input   logic           hardware_scheduler_en,

    input   logic           hardware_scheduler_swap_pc,
    input   logic   [31:0]  hardware_scheduler_pc,


    output  logic   [31:0]  locked_address,
    output  logic           lock,

    output  logic           amo,

    output  logic   [31:0]  data[32],
    input   logic   [31:0]  ooo_data[NUM_REGS],
    input logic [$clog2(NUM_REGS)-1:0] rrf_arch_to_physical[32],

    input  logic    [63:0]      ooo_order,

    output mem_wb_reg_t mem_wb_reg,
    output logic valid_commit_ppl,

    output logic [63:0] order

    

    // Single memory port connection when caches are integrated into design (CP3 and after)
    
    // output logic   [31:0]      bmem_addr,
    // output logic               bmem_read,
    // output logic               bmem_write,
    // output logic   [63:0]      bmem_wdata,
    // input logic               bmem_ready,

    // input logic   [31:0]      bmem_raddr,
    // input logic   [63:0]      bmem_rdata,
    // input logic               bmem_rvalid
    
);

// logic [63:0] order;

logic istall;
logic dstall;

// logic   [31:0]  imem_addr;
// logic   [3:0]   imem_rmask;
// logic   [31:0]  imem_rdata;
// logic           imem_resp;
// logic   [31:0]  dmem_addr;
// logic   [3:0]   dmem_rmask;
// logic   [3:0]   dmem_wmask;
// logic   [31:0]  dmem_rdata;
// logic   [31:0]  dmem_wdata;
// logic           dmem_resp;

// make dmem_happy_for_now
// assign dmem_addr = '0;
// assign dmem_rmask = '0;
// assign dmem_wmask = '0;
// assign dmem_wdata = '0;

// Pipeline register declarations:
if_id_reg_t if_id_reg_next, if_id_reg;
id_ex_reg_t id_ex_reg_next, id_ex_reg;
ex_mem_reg_t ex_mem_reg_next, ex_mem_reg;
mem_wb_reg_t mem_wb_reg_next;

// rd_v
logic [31:0] rd_v;

logic br_en;
logic [31:0] mispredict_pc;

// rvfi signals


always_ff @(posedge clk) // reworks according to monitor_valid @TODO
    begin : order_control_block
        
        if(rst)
            begin
                order <= '0;
            end
        else
            begin
                if(hardware_scheduler_swap_pc)
                    begin
                        order <= ooo_order + 1'b1;
                    end
                else if(mem_wb_reg.rvfi.monitor_valid && ~dstall && ~istall)
                    begin
                        order <= order + 1'b1;
                    end
            end

    end : order_control_block

always_ff @(posedge clk)
    begin : pipeline_register_control
        
        if(rst)
            begin
                if_id_reg <= '0;
                id_ex_reg <= '0;
                ex_mem_reg <= '0;
                mem_wb_reg <= '0;
            end
        else
            begin
                if(istall | dstall) // or dstall
                    begin
                        if_id_reg <= br_en ? '0 : if_id_reg;
                        id_ex_reg <= id_ex_reg;
                        ex_mem_reg <= ex_mem_reg;
                        mem_wb_reg <= mem_wb_reg;
                    end
                else
                    begin
                        if_id_reg <= br_en ? '0 : if_id_reg_next;
                        id_ex_reg <= br_en ? '0 : id_ex_reg_next;
                        ex_mem_reg <= ex_mem_reg_next;
                        mem_wb_reg <= mem_wb_reg_next;
                    end
            end
    
    end : pipeline_register_control

logic [31:0] ld_forward_val;

always_comb
    begin : ld_to_prev_area_saving_mux

        unique case (ex_mem_reg.funct3)
            lb : ld_forward_val = {{24{dmem_rdata[7 +8 *ex_mem_reg.alu_result[1:0]]}}, dmem_rdata[8 *ex_mem_reg.alu_result[1:0] +: 8 ]};
            lbu: ld_forward_val = {{24{1'b0}}                          , dmem_rdata[8 *ex_mem_reg.alu_result[1:0] +: 8 ]};
            lh : ld_forward_val = {{16{dmem_rdata[15+16*ex_mem_reg.alu_result[1]  ]}}, dmem_rdata[16*ex_mem_reg.alu_result[1]   +: 16]};
            lhu: ld_forward_val = {{16{1'b0}}                          , dmem_rdata[16*ex_mem_reg.alu_result[1]   +: 16]};
            lw : ld_forward_val = dmem_rdata;
            default: ld_forward_val = 'x;
        endcase

    end : ld_to_prev_area_saving_mux

if_stage if_stage_dec_1(
    .clk(clk),
    .rst(rst),
    
    .hardware_scheduler_en(hardware_scheduler_en),

    .hardware_scheduler_swap_pc(hardware_scheduler_swap_pc),
    .hardware_scheduler_pc(hardware_scheduler_pc),

    .imem_addr(imem_addr),
    .imem_rmask(imem_rmask),
    .imem_resp(imem_resp),
    .imem_rdata(imem_rdata),

    .mispredict_br_en(br_en), // ouput from execute stage @TODO
    .mispredict_pc(mispredict_pc),

    .order(order),

    .istall(istall),
    .dstall(dstall),

    .if_id_reg_next(if_id_reg_next)
);

id_stage id_stage_dec_1 // could split fetch into interface with imem and receive resp stages
(
    .clk(clk),
    .rst(rst),

    .inst(if_id_reg.rvfi.monitor_inst), // imem_rdata
    .if_id_reg(if_id_reg),

    .valid_write(valid_commit_ppl),

    .regf_we(mem_wb_reg.regf_we), // All 3 from writeback stage
    .rd_s(mem_wb_reg.rd_s),
    .rd_v(rd_v),

    .hardware_scheduler_swap_pc(hardware_scheduler_swap_pc),

    .data(data),
    .ooo_data(ooo_data),

    .rrf_arch_to_physical(rrf_arch_to_physical),

    .id_ex_reg_next(id_ex_reg_next)
);

ex_stage ex_stage_dec_1 // ex stage could be split into 2 where muxes and alu split by a register
(
    .id_ex_reg(id_ex_reg),

    .ex_mem_reg_next(ex_mem_reg_next),

    .dstall(dstall),

    .mem_read_next(ex_mem_reg.mem_read),
    .ld_forward_val(ld_forward_val),

    .rd_v_wb(rd_v), // output of wb_mux
    .rd_s_wb(mem_wb_reg.rd_s),
    .write_back_wb(mem_wb_reg.regf_we & mem_wb_reg.rvfi.monitor_valid), // from writeback

    .rd_v_mem(ex_mem_reg.alu_result), // if load dmem_rdata ? 
    .rd_s_mem(ex_mem_reg.rd_s),
    .write_back_mem(ex_mem_reg.regf_we & ex_mem_reg.rvfi.monitor_valid), // from mem

    .br_en(br_en),
    .mispredict_pc(mispredict_pc)
);

mem_stage mem_stage_dec_1
(
    .clk(clk),
    .rst(rst),

    .ex_mem_reg(ex_mem_reg),

    .dmem_rdata(dmem_rdata), // could bring the mux out to save area
    .dmem_resp(dmem_resp),

    .dmem_rmask(dmem_rmask),
    .dmem_wmask(dmem_wmask),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),

    .dstall(dstall),

    .istall(istall),

    .mem_wb_reg_next(mem_wb_reg_next),

    .locked_address(locked_address),
    .lock(lock),
    .amo(amo)
);

wb_stage wb_stage_dec_1
(
    .mem_wb_reg(mem_wb_reg),
    .rd_v(rd_v)
);

// cache_unit cache_unit (.*);

assign ppl_mult_counter_en = (mem_wb_reg.rvfi.monitor_valid && ~dstall && ~istall && mem_wb_reg.rvfi.monitor_inst[6:0] == op_b_reg && mem_wb_reg.rvfi.monitor_inst[31:25] == 7'b0000001) ? 1'b1 : 1'b0;
assign ppl_mem_op_counter_en = (mem_wb_reg.rvfi.monitor_valid && ~dstall && ~istall && (mem_wb_reg.rvfi.monitor_inst[6:0] == op_b_load || mem_wb_reg.rvfi.monitor_inst[6:0] == op_b_store)) ? 1'b1 : 1'b0;
assign ppl_flush_counter_en = br_en && !istall && !dstall;
assign ppl_rob_full_threshold = 1'b0;
assign ppl_alu_op_counter_en = (mem_wb_reg.rvfi.monitor_valid && ~dstall && ~istall && (mem_wb_reg.rvfi.monitor_inst[6:0] == op_b_reg || mem_wb_reg.rvfi.monitor_inst[6:0] == op_b_imm || mem_wb_reg.rvfi.monitor_inst[6:0] == op_b_lui || mem_wb_reg.rvfi.monitor_inst[6:0] == op_b_auipc)) ? 1'b1 : 1'b0;

assign valid_commit_ppl = mem_wb_reg.rvfi.monitor_valid && ~dstall && ~istall;
endmodule : pipeline_cpu