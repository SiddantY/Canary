module if_stage
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic           imem_resp,
    input   logic   [31:0]  imem_rdata,

    input   logic           mispredict_br_en,
    input   logic   [31:0]  mispredict_pc,

    input   logic   [63:0]  order,
    
    //HW Scheduler Port
    input   logic           hardware_scheduler_en,

    input   logic           hardware_scheduler_swap_pc,
    input   logic   [31:0]  hardware_scheduler_pc,

    output  logic           istall,
    input   logic           dstall,

    output  if_id_reg_t     if_id_reg_next
);

logic [31:0] pc, pc_prev;

always_comb
    begin

        imem_rmask = hardware_scheduler_en ? 4'b0000 : 4'b1111;//stop fetching memory when stalling,
        imem_addr = pc;

        if(imem_resp)
            begin
                istall = 1'b0;
            end
        else if(hardware_scheduler_en) //if ab to swap, keep pipes goin
            begin
            istall = 1'b0;
            end
        else
            begin
                istall = 1'b1;
            end
        
        if_id_reg_next.pc = pc;
        if_id_reg_next.branch_pred = 1'b0; // static not taken for now
        if_id_reg_next.predicted_pc = pc + 32'h4; // static not taken for now

        if_id_reg_next.rvfi.monitor_valid = hardware_scheduler_en ? 1'b0 : 1'b1;
        if_id_reg_next.rvfi.monitor_order = order;
        if_id_reg_next.rvfi.monitor_inst  = hardware_scheduler_en ? 32'h00000013 : imem_rdata;//insert nops
        if_id_reg_next.rvfi.monitor_pc_rdata = pc;
        if_id_reg_next.rvfi.monitor_pc_wdata = pc + 32'h4; // will change in execute if jal/jalr/branch
    end

pipeline_pc_reg pc_reg_dec_1(
    .clk(clk),
    .rst(rst),

    .pc(pc),
    .pc_prev(pc_prev),

    .mispredict_br_en(mispredict_br_en),
    .mispredict_pc(mispredict_pc),

    .hardware_scheduler_swap_pc(hardware_scheduler_swap_pc),
    .hardware_scheduler_pc(hardware_scheduler_pc),

    .stall(istall | dstall | hardware_scheduler_en)
);

endmodule