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

    output  logic           istall,
    input   logic           dstall,

    output  if_id_reg_t     if_id_reg_next
);

logic [31:0] pc, pc_prev;

logic resp_received;
logic [31:0] held_inst;

always_ff @(posedge clk) begin
    if(rst) begin
        resp_received <= 1'b0;
        held_inst <= '0;
    end else begin
        if(imem_resp) begin
            resp_received <= 1'b1;
            held_inst <= imem_rdata;
        end

        if(~(istall | dstall)) begin
            resp_received <= 1'b0;
        end
    end
end

always_comb
    begin

        imem_rmask = resp_received ? 4'b0 : 4'b1111;
        imem_addr = pc;

        if(imem_resp | resp_received)
            begin
                istall = 1'b0;
            end
        else
            begin
                istall = 1'b1;
            end
        
        if_id_reg_next.pc = pc;
        if_id_reg_next.branch_pred = 1'b0; // static not taken for now
        if_id_reg_next.predicted_pc = pc + 3'b100; // static not taken for now

        if_id_reg_next.rvfi.monitor_valid = 1'b1;
        if_id_reg_next.rvfi.monitor_order = order;
        if_id_reg_next.rvfi.monitor_inst  = resp_received ? held_inst : imem_rdata;
        if_id_reg_next.rvfi.monitor_pc_rdata = pc;
        if_id_reg_next.rvfi.monitor_pc_wdata = pc + 3'b100; // will change in execute if jal/jalr/branch
    end

pipeline_pc_reg pc_reg_dec_1(
    .clk(clk),
    .rst(rst),

    .pc(pc),
    .pc_prev(pc_prev),

    .mispredict_br_en(mispredict_br_en),
    .mispredict_pc(mispredict_pc),

    .stall(istall | dstall)
);

endmodule
