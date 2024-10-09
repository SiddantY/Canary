module pc_reg
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic   [31:0]  pc_branch, pc_jump,
    input   logic           br_en, jump_en,
    input   logic   request_new_inst,
    input   logic           jalr_done,
    input   logic   [31:0]  jalr_pc,
    input   logic           flush,
    input   logic   [31:0]  missed_pc,
    input   logic           hardware_scheduler_en,
    output  logic   [31:0]  pc, pc_prev // , pc_tmp
);

logic [31:0] pc_next;
//logic [31:0] pc_tmp;

always_ff @(posedge clk)
    begin
        if(rst) // pc defaults to 0x6000_0000 on reset
            begin
                pc <= 32'h6000_0000;
                pc_prev <= 32'h6000_0000;
            end
        else // pc <- pc_next yk
            begin
                // TODO: add stalling pc on Q full
                if(hardware_scheduler_en) begin
                    pc <= flush | jump_en | jalr_done ? pc_next : pc;
                    pc_prev <= pc_prev;
                end
                else if(request_new_inst == 1'b1)
                    begin
                        pc <= pc_next;
                        pc_prev <= pc;
                    end
                else
                    begin
                        pc <= flush | jump_en | jalr_done ? pc_next : pc;
                        pc_prev <= pc_prev;  
                    end
            end
    end

// always_comb begin : pc_magic
//     if (request_new_inst) pc = pc_next;
//     else if(flush) pc = pc_next;
//     else pc = pc_tmp;
// end

always_comb
    begin

        if(br_en) // if branch pc is the branch pc
            begin
                pc_next = pc_branch;
            end
        else if(flush)
            begin
                pc_next = missed_pc;
            end
        else if(jump_en)
            begin
                pc_next = pc_jump;
            end
        else if(jalr_done)
            begin
                pc_next = jalr_pc;
            end
        else // else pc just pc + 4
            begin
                pc_next = pc + 32'h4;
            end
    end

endmodule