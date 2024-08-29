module load_store_queue
import rv32i_types::*;
#(
    parameter   QUEUE_DEPTH =   64
)

(
    input   logic                       clk,
    input   logic                       rst,
    input   logic                       flush,
    input   ld_st_queue_t               data_in,
    input   logic                       write_enable,
    input   logic                       read_enable,
    input   logic   [NUM_REGS-1:0]             phys_valid_vector,
    input   logic   [$clog2(ROB_SIZE)-1:0]               rob_head,
    output  logic                       queue_empty,
    output  logic                       queue_full,
    output  logic [$clog2(NUM_REGS)-1:0]    pr1_s_ld_st,
    output  logic [$clog2(NUM_REGS)-1:0]    pr2_s_ld_st, 
    output  ld_st_queue_t               data_out,
    output  logic                       read_resp
);

ld_st_queue_t data_queue [QUEUE_DEPTH]; // queue

logic [$clog2(QUEUE_DEPTH)-1:0] read_ptr; // read loc
logic [$clog2(QUEUE_DEPTH)-1:0] write_ptr; // write loc


int i;
always_ff @(posedge clk)
    begin
        if(rst || flush) // clear the queue
            begin
                for(i = 0; i < QUEUE_DEPTH; i++); // set queue to zeroes
                    begin
                        //data_queue[i%QUEUE_DEPTH] <= '0;
                        data_queue[i%QUEUE_DEPTH].opcode <= '0; // can and should only have ld or st opcodes
                        data_queue[i%QUEUE_DEPTH].funct3 <= '0; // 8/16/32 tings
                        // bit [31:0] dmem_addr_or_rdwdata; // if ld dmem_addr, if st rd_wdata
                        data_queue[i%QUEUE_DEPTH].pr1_s_ld_st <= '0;
                        data_queue[i%QUEUE_DEPTH].arch_rs1 <= '0;
                        
                        data_queue[i%QUEUE_DEPTH].pr2_s_ld_st <= '0;
                        data_queue[i%QUEUE_DEPTH].arch_rs2 <= '0;

                        data_queue[i%QUEUE_DEPTH].phys_rd <= '0;
                        data_queue[i%QUEUE_DEPTH].arch_rd <= '0;

                        data_queue[i%QUEUE_DEPTH].rob_index <= '0;
                        data_queue[i%QUEUE_DEPTH].pc <= '0;
                        data_queue[i%QUEUE_DEPTH].imm <= '0;
                        data_queue[i%QUEUE_DEPTH].order <= '0;
                        data_queue[i%QUEUE_DEPTH].inst <= '0;

                        data_out <= '0;
                    end

                //set pointers to 0
                read_ptr <= '0;
                write_ptr <= '0;

                read_resp <= '0;
            end
        else 
            begin
                if(read_enable && ~queue_empty && phys_valid_vector[data_queue[read_ptr].pr1_s_ld_st] && phys_valid_vector[data_queue[read_ptr].pr2_s_ld_st]) // read asserted send out first element and pop it off the queue
                    begin
                        if(rob_head != data_queue[read_ptr].rob_index && data_queue[read_ptr].opcode == op_b_store)
                            begin
                                data_out <= 'x;
                                read_resp <= 1'b0; 
                            end
                        else
                            begin
                                data_out <= data_queue[read_ptr];
                                read_ptr <= read_ptr + 1'b1;
                                read_resp <= 1'b1;
                            end
                    end
                else
                    begin
                        data_out <= 'x;
                        read_resp <= 1'b0;
                    end

                if(write_enable && ~queue_full) // write asserted take the data_in and put it at the back of the queue
                    begin
                        data_queue[write_ptr].opcode <= data_in.opcode; // can and should only have ld or st opcodes
                        data_queue[write_ptr].funct3 <= data_in.funct3; // 8/16/32 tings
                        data_queue[write_ptr].pr1_s_ld_st <= data_in.pr1_s_ld_st;
                        data_queue[write_ptr].arch_rs1 <= data_in.arch_rs1;
                        data_queue[write_ptr].pr2_s_ld_st <= data_in.pr2_s_ld_st;
                        data_queue[write_ptr].arch_rs2 <= data_in.arch_rs2;
                        data_queue[write_ptr].phys_rd <= data_in.phys_rd;
                        data_queue[write_ptr].arch_rd <= data_in.arch_rd;
                        data_queue[write_ptr].rob_index <=  data_in.rob_index;
                        data_queue[write_ptr].pc <= data_in.pc;
                        data_queue[write_ptr].imm <=  data_in.imm;
                        data_queue[write_ptr].order <=  data_in.order;
                        data_queue[write_ptr].inst <= data_in.inst;
                        
                        write_ptr <= write_ptr + 1'b1;
                    end
            end
    end

int ls;
always_comb
    begin
        if(read_ptr == write_ptr) // if queue is empty no more instructions to push raise flag
            begin
                queue_empty = 1'b1;
            end 
        else // if queue is empty we can keep pushing instructions
            begin
                queue_empty = 1'b0;
            end
        
        if(read_ptr == (write_ptr + 1'b1)) // if queue is empty no more instructions to push raise flag
            begin
                queue_full = 1'b1;
            end 
        else // if queue is empty we can keep pushing instructions
            begin
                queue_full = 1'b0;
            end
        
        // updating valids
        for(ls = 0; ls < QUEUE_DEPTH; ls++) // for loop to update valid value, 1 when regs ready, 0 when not
            begin
                data_queue[ls].rs1_ready = phys_valid_vector[data_queue[ls].pr1_s_ld_st];
                data_queue[ls].rs2_ready = phys_valid_vector[data_queue[ls].pr2_s_ld_st];
            end
        
        pr1_s_ld_st = data_queue[read_ptr].pr1_s_ld_st;
        pr2_s_ld_st = data_queue[read_ptr].pr2_s_ld_st;
    end


endmodule