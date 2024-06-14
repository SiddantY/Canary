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
    output  logic           IQ_empty,
    output  logic           IQ_pop,

    output  if_id_reg_t     if_id_reg_next

);

logic [31:0] pc, pc_prev;
logic IQ_full,  IQ_push, IQ_flush;
iq_entry_t IQ_in, IQ_out;
logic br_while_fetch;

always_ff @ (posedge clk) 
    begin
        if(mispredict_br_en) begin
            br_while_fetch <= '1;
        end
        if((br_while_fetch == '1 && imem_resp) || rst) begin
            br_while_fetch <= '0;
        end
    end

always_comb
    begin
        // istall = IQ_empty; // NEW definition for istall w/ IQ
        IQ_flush = mispredict_br_en && !IQ_empty; // flush IQ on br mispred
        imem_rmask =  IQ_full ? 4'd0 : 4'b1111;
        // imem_addr = (dstall) ? pc_prev : pc;
        imem_addr = pc;
        IQ_in = '0;
        IQ_push = '0;
        IQ_pop = '0;
        if(imem_resp)
            begin
                istall = 1'b0;
                // push to instr q
                if((!IQ_full && !mispredict_br_en) || br_while_fetch) IQ_push = 1'b1;
                IQ_in.instr = imem_rdata;
                IQ_in.pc = imem_addr;
            end
        else
            begin
                istall = 1'b1;
            end


        // popping from IQ
        if(!IQ_empty) 
            begin
                IQ_pop = 1'b1;
                if_id_reg_next.inst = IQ_out.instr;
                if_id_reg_next.pc = IQ_out.pc;
                if_id_reg_next.branch_pred = 1'b0; // static not taken for now
                if_id_reg_next.predicted_pc = IQ_out.pc + 3'b100; // static not taken for now

                if_id_reg_next.rvfi.monitor_valid = 1'b1;
                if_id_reg_next.rvfi.monitor_order = order;
                if_id_reg_next.rvfi.monitor_pc_rdata = IQ_out.pc;
                if_id_reg_next.rvfi.monitor_pc_wdata = IQ_out.pc + 3'b100; // will change in execute if jal/jalr/branch
            end
        if(rst)
            begin
                if_id_reg_next = '0;
            end
    end

pipeline_pc_reg pc_reg_dec_1(
    .clk(clk),
    .rst(rst),

    .pc(pc),
    .pc_prev(pc_prev),

    .mispredict_br_en(mispredict_br_en),
    .mispredict_pc(mispredict_pc),

    .stall(istall)
);

instr_queue IQ (      
    .clk(clk),
    .rst(rst), 
    .push(IQ_push), 
    .pop(IQ_pop), 
    .rdata(IQ_in),
    .wdata(IQ_out),
    .full(IQ_full),
    .empty(IQ_empty),
    .flush(IQ_flush)
    // .IQ_num_contents()
);

endmodule
