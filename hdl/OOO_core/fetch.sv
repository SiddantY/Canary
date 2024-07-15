module fetch
import rv32i_types::*;
#(
    parameter IQ_DATA_WIDTH = 64,
    parameter IQ_DEPTH = 16
)
(
    input   logic           clk,
    input   logic           rst,
    input   logic   [31:0]  pc_branch,
    input   logic           br_en,
    input   logic           jump_en,
    input   logic           jalr_en,
    input   logic           jalr_done,
    input   logic   [31:0]  jalr_pc,
    input   logic   [31:0]  pc_jump,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,
    input   logic           flush,
    input   logic   [31:0]  missed_pc,
    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    output  logic   [IQ_DATA_WIDTH-1:0]  instruction,
    output  logic   [31:0]  pc,
    input   logic branch_recovery,
    input   logic [31:0] brr_pc,
    output  logic           read_resp,
    input   logic           request_new_instr // NEEDS INCOROPATION 
);

logic [31:0] iq_instruction_in; // instruction_queue_...
logic [IQ_DATA_WIDTH-1:0] iq_instruction_out; // instruction_queue_...
logic iq_read_enable; // instruction_queue_...
logic iq_write_enable; // instruction_queue_...
logic iq_empty; // instruction_queue_...
logic iq_full; // instruction_queue_...


logic [31:0] pc_prev;
logic [31:0] pc_tmp;

// ONLY WORKS ON MAGIC DO TO 1 CYCLE ASSUMPTION
// DOESNT TAKE INTO ACCOUNT Q FULL (AS IT CANT BE)
always_comb
    begin
        imem_addr = pc; // set imem_addr to the pc val to get current instruction

        if(imem_resp) // if imem responds
            begin
                iq_write_enable = 1'b1; // set write enable to allow writing to the queue
                iq_instruction_in = imem_rdata; // set data in 

                imem_rmask = 4'b1111; // always read 32 bits from the i-cache
            end
        else // if imem doesn't respond
            begin
                iq_write_enable = 1'b0; // no response so don't write to the queue
                iq_instruction_in = imem_rdata; // shoud be 'x, but doesn't matter since we're only reading

                imem_rmask = 4'b1111; // keep imem_rmask to be 4'b1111 all the time since we're only reading 32-bits always and needs to stay this way due to mem_spec
            end
        
        if(iq_empty == 1'b0) // if the instruction queue is not empty keep feeding instructions
            begin
                iq_read_enable = 1'b1; // read enable allows us to pop the instruction out
                instruction = iq_instruction_out; // instruction receive and sent out
            end
        else
            begin
                iq_read_enable = 1'b0; // read enable set to 0, there are not instructions to send out
                instruction = iq_instruction_out; // instruction set to x's, might need to be modified. 
            end

    end

pc_reg pc_rec(
    .clk(clk),
    .rst(rst),
    .pc_jump(pc_jump),
    .jump_en(jump_en),
    .jalr_done(jalr_done),
    .jalr_pc(jalr_pc),
    .pc_branch(pc_branch),
    .br_en(br_en),
    .flush(flush),
    .missed_pc(missed_pc),
    .branch_recovery(branch_recovery), // from execute
    .brr_pc(brr_pc), // from execute
    .pc(pc),
    .request_new_inst((~iq_full && imem_resp) || jalr_done),
    .pc_prev(pc_prev),
    .pc_tmp(pc_tmp)
);

queue #(
    .DATA_WIDTH(IQ_DATA_WIDTH), 
    .QUEUE_DEPTH(IQ_DEPTH)
) 
instruction_queue(
    .clk(clk),
    .rst(rst),
    .jump_en(jump_en),
    .jalr_en(jalr_en),
    .jalr_done(jalr_done),
    .flush(flush | branch_recovery),
    .data_in({pc_tmp, iq_instruction_in}), // first 32 pc, bottom 32 instr -- NEWLY ADDED PC PREV
    .write_enable(iq_write_enable),
    .read_enable(request_new_instr && !iq_empty), // READ IF DE-Q REQUEST AND Q NOT EMPTY
    .queue_empty(iq_empty),
    .queue_full(iq_full),
    .data_out(iq_instruction_out),
    .read_resp(read_resp)
);


endmodule