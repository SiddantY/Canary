module fetch
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           jump_en,
    input   logic           jalr_en,
    input   logic           jalr_done,
    input   logic   [31:0]  jalr_pc,
    input   logic   [31:0]  pc_jump,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,
    output  logic   [31:0]  imem_addr,
    input   logic   [31:0]  imem_raddr,

    input   logic           hardware_scheduler_en,

    input   logic           hardware_scheduler_swap_pc,
    input   logic   [31:0]  hardware_scheduler_pc,
    
    // NEW ICACHE SIGS
    output  logic           input_valid,
    input   logic           imem_stall,
    ///////////////////

    input   logic           flush,
    input   logic   [31:0]  missed_pc,

    output  logic           imem_read,
    output  logic   [63:0]  instruction,
    output  logic   [31:0]  pc,
    output  logic           read_resp,
    input   logic           request_new_instr, // NEEDS INCOROPATION 

    output  logic           pc_req
);

logic [31:0] iq_instruction_in; // instruction_queue_...
logic [63:0] iq_instruction_out; // instruction_queue_...
logic iq_read_enable; // instruction_queue_...
logic iq_write_enable; // instruction_queue_...
logic iq_empty; // instruction_queue_...
logic iq_full; // instruction_queue_...

// i cache stuff
logic [4:0] iq_counter;
logic iq_full_counter;

assign iq_full_counter = (iq_counter == 5'b11110) ? 1'b1 : 1'b0;
assign input_valid = hardware_scheduler_en ? 1'b0 : 1'b1;


logic [31:0] pc_prev;

logic wait_for_inst;
// assign target_pc = (dinst == '0 && 1'b0) ? dpc_rdata && dpc_wdata && 32'b0 : '0;
// assign decoded_br_en = '0;
// assign wait_for_inst = '0;

// assign bren = ben;
// assign bren = decoded_br_en;
// ONLY WORKS ON MAGIC DO TO 1 CYCLE ASSUMPTION
// DOESNT TAKE INTO ACCOUNT Q FULL (AS IT CANT BE)
always_comb
    begin

        imem_read = 1'b1; // always tryna read
        imem_addr = pc;   // always show pc
        if(imem_resp) begin
            iq_write_enable = hardware_scheduler_en ? 1'b0 : 1'b1; // set write enable to allow writing to the queue
            iq_instruction_in = hardware_scheduler_en ? 32'h0000_0013 : imem_rdata; // set data in 
        end else begin
            iq_write_enable = 1'b0; // no response so don't write to the queue
            iq_instruction_in = '0; 
        end

        if(iq_empty == 1'b0) begin // if the instruction queue is not empty keep feeding instructions
            iq_read_enable = 1'b1; // read enable allows us to pop the instruction out
            instruction = iq_instruction_out; // instruction receive and sent out
        end else begin
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
    // .pc_branch(ppc),
    .pc_branch(missed_pc),

    .hardware_scheduler_swap_pc(hardware_scheduler_swap_pc),
    .hardware_scheduler_pc(hardware_scheduler_pc),

    // .br_en(ben),
    .br_en(1'b0),
    .pc(pc),
    .flush(flush),
    .missed_pc(missed_pc),
    .request_new_inst(pc_req), // if IQ gets full, might lock up
    .pc_prev(pc_prev)
);


logic iq_write;
logic [31:0] raddr_prev;

assign iq_write =  (raddr_prev == imem_raddr || imem_raddr == '0) || hardware_scheduler_en ? 1'b0 : 1'b1;
// assign iq_write = ((~iq_full && !imem_stall && !iq_full_counter) || jalr_done) && (imem_resp &&!iq_full_counter);

always_ff @( posedge clk ) begin : wack_stall
    if(rst | (flush | jump_en | jalr_done | hardware_scheduler_en)) begin
        raddr_prev <= '0;
    end else begin
        raddr_prev <= imem_raddr;
    end
end

queue #(
    .DATA_WIDTH(64), 
    .QUEUE_DEPTH(16),
    .RD_PTR_INCR(4)
) 
instruction_queue(
    .clk(clk),
    .rst(rst),
    .jump_en(jump_en),
    .jalr_en(jalr_en),
    .jalr_done(jalr_done),
    .flush(flush),
    // .data_in({ben, ppc, imem_raddr, iq_instruction_in}), // first 32 pc, bottom 32 instr -- NEWLY ADDED PC PREV
    // .data_in({br_en_out, ppc_out, imem_raddr, iq_instruction_in}), 
    .data_in({imem_raddr, iq_instruction_in}), 
    // .data_in({br_use, ppc_use, imem_raddr, iq_instruction_in}), 
    // .write_enable(pc_req_out && !imem_stall),
    .write_enable(iq_write),
    .read_enable(request_new_instr && !iq_empty), // READ IF DE-Q REQUEST AND Q NOT EMPTY
    .queue_empty(iq_empty),
    .queue_full(),
    .queue_full_param(iq_full),
    .data_out(iq_instruction_out),
    .read_resp(read_resp)
);

assign pc_req =  (~iq_full && !imem_stall) || jalr_done;

always_ff @( posedge clk ) begin : iq_counter_stuff
    if(rst | flush) begin // ADD FLUSH TOO 
        iq_counter <= '0;
    end else begin
        if((~iq_full && !imem_stall) || jalr_done) begin

            if(!read_resp) iq_counter <= iq_counter + 1'b1;

        end else if(read_resp) begin

            iq_counter <= iq_counter - 1'b1;

        end
    end
end

endmodule
