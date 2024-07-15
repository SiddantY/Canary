module rob
import rv32i_types::*;
#(
    parameter ROB_SIZE = 8
)
(
    input logic clk,
    input logic rst,
    input logic [63:0] instruction,
    input logic [$clog2(ROB_SIZE)-1:0] valid_intruction_index,
    input logic [$clog2(ROB_SIZE)-1:0] valid_intruction_index_mul,
    input logic [$clog2(ROB_SIZE)-1:0] valid_intruction_index_ldst,
    input logic update_rob_valid,
    input logic update_rob_valid_mul,
    input logic update_rob_valid_ldst,
    input logic insert_into_rob,
    input logic [$clog2(NUM_REGS)-1:0] phys_rd,
    input logic [4:0] arch_rd,
    input data_bus_package_t execute_outputs,
    input data_bus_package_t execute_outputs_mul,
    input data_bus_package_t execute_outputs_ldst,
    input logic branch_recovery,
    input logic [$clog2(ROB_SIZE)-1:0] br_issue_ptr,

    output logic rob_empty,
    output logic rob_full,
    output logic [$clog2(ROB_SIZE)-1:0] instruction_to_rob_index,
    output rob_entry_t rob_line_to_commit,
    output logic valid_commit,
    output rvfi_commit_packet_t committer,
    output logic stall_preempt,
    output logic flush,
    output logic flush_comb,
    output logic [$clog2(ROB_SIZE)-1:0] commit_ptr,
    output logic [31:0] missed_pc,

    input logic [63:0] order_ind,
    input logic [63:0] order,

    input logic [$clog2(NUM_BRATS)-1:0] branch_resolved_index,
    input logic [$clog2(NUM_BRATS)-1:0] current_brat
);


rob_entry_t rob[ROB_SIZE];
rvfi_commit_packet_t rvfi_rob_mirror[ROB_SIZE];

logic [$clog2(ROB_SIZE)-1:0] issue_ptr;

logic [$clog2(ROB_SIZE)-1:0] ebrl;

always_ff @(posedge clk)
    begin
        if(rst)
            begin
                for(int i = 0; i < ROB_SIZE; i++) // reset the rob to all zeroes
                    begin
                        rob[i] <= '0;
                    end

                // queue pointers go to zero for reset
                issue_ptr <= '0;
                commit_ptr <= '0;
                valid_commit <= '0;
                flush <= 1'b0;
                missed_pc <= '0;
            end
        else 
            begin
                if(~rob_full && insert_into_rob && ~flush) // insert into rob its not full and the enable signal is high
                    begin
                        //rob[issue_ptr].done <= 1'b0;
                        rob[issue_ptr].pc <= instruction[63:32];
                        rob[issue_ptr].instruction <= instruction[31:0];
                        rob[issue_ptr].phys_rd <= phys_rd;
                        rob[issue_ptr].arch_rd <= arch_rd;

                        rvfi_rob_mirror[issue_ptr].order <= order;

                        issue_ptr <= issue_ptr + 1'b1;
                    end
                
                if(update_rob_valid_ldst && rob[valid_intruction_index_ldst].instruction != '0) // if an instruction is done committing mark it as done
                    begin
                        rob[valid_intruction_index_ldst].done <= 1'b1;
                        rob[valid_intruction_index_ldst].branch_mismatch <= 1'b0;
                        rob[valid_intruction_index_ldst].current_brat <= execute_outputs_ldst.current_brat;
                        rvfi_rob_mirror[valid_intruction_index_ldst] <= execute_outputs_ldst.rvfi;
                        rvfi_rob_mirror[valid_intruction_index_ldst].valid <= 1'b1;

                        // rob[valid_intruction_index].rvfi <= execute_outputs.rvfi;
                    end
                
                if(update_rob_valid && rob[valid_intruction_index].instruction != '0) // if an instruction is done committing mark it as done
                    begin
                        
                        rob[valid_intruction_index].done <= 1'b1;
                        rob[valid_intruction_index].branch_mismatch <= execute_outputs.branch_mismatch;
                        rob[valid_intruction_index].current_brat <= execute_outputs.current_brat;
                        rvfi_rob_mirror[valid_intruction_index] <= execute_outputs.rvfi;
                        rvfi_rob_mirror[valid_intruction_index].valid <= 1'b1;

                        // rob[valid_intruction_index].rvfi <= execute_outputs.rvfi;
                    end
                
                if(update_rob_valid_mul && rob[valid_intruction_index_mul].instruction != '0) // if an instruction is done committing mark it as done
                    begin
                        rob[valid_intruction_index_mul].done <= 1'b1;
                        rob[valid_intruction_index_mul].branch_mismatch <= 1'b0;
                        rob[valid_intruction_index_mul].current_brat <= execute_outputs_mul.current_brat;
                        rvfi_rob_mirror[valid_intruction_index_mul] <= execute_outputs_mul.rvfi;
                        rvfi_rob_mirror[valid_intruction_index_mul].valid <= 1'b1;

                        // rob[valid_intruction_index].rvfi <= execute_outputs.rvfi;
                    end
            
                
                if(branch_recovery)
                    begin
                        issue_ptr <= br_issue_ptr + 1'b1;

                        for(int af = 0; af < ROB_SIZE; af++)
                            begin
                                if(rob[af].current_brat > branch_resolved_index
                                && rvfi_rob_mirror[af].order >= order_ind)
                                    begin
                                        rob[af].done <= 1'b0;
                                    end
                            end
                        
                        // if(br_issue_ptr + 1'b1 < commit_ptr)
                        //     begin
                        //         for(ebrl = br_issue_ptr + 1'b1; ebrl < commit_ptr; ebrl++)
                        //             begin
                        //                 if(rob[ebrl].current_brat > branch_resolved_index)
                        //                     //&& rvfi_rob_mirror[af].order >= order_ind)
                        //                     begin
                        //                         rob[ebrl].done <= 1'b0;
                        //                     end
                        //             end
                        //     end
                        // else
                        //     begin
                        //         for(ebrl = br_issue_ptr + 1'b1; ebrl < ROB_SIZE; ebrl++)
                        //             begin
                        //                 if(rob[ebrl].current_brat > branch_resolved_index)
                        //                     //&& rvfi_rob_mirror[af].order >= order_ind)
                        //                     begin
                        //                         rob[ebrl].done <= 1'b0;
                        //                     end
                        //             end

                        //         for(ebrl = 0; ebrl < commit_ptr; ebrl++)
                        //             begin
                        //                 if(rob[ebrl].current_brat > branch_resolved_index)
                        //                     //&& rvfi_rob_mirror[af].order >= order_ind)
                        //                     begin
                        //                         rob[ebrl].done <= 1'b0;
                        //                     end
                        //             end
                        //     end
                        
                        
                        rob[br_issue_ptr + 1'b1].done <= 1'b0;
                    end
                
                if(rob[commit_ptr].done) // if the top of the queue is done, do valid things
                    begin
                        if(branch_recovery && rob[commit_ptr].current_brat > branch_resolved_index)
                            begin
                                valid_commit <= 1'b0;
                                flush <= 1'b0;
                                missed_pc <= '0;
                            end
                        else
                            begin
                                rob[commit_ptr].done <= 1'b0;
                                rob_line_to_commit <= rob[commit_ptr];
                                valid_commit <= 1'b1;
                                committer <= rvfi_rob_mirror[commit_ptr];
                                if(rob[commit_ptr].branch_mismatch)
                                    begin
                                        flush <= 1'b1;
                                        missed_pc <= rvfi_rob_mirror[commit_ptr].pc_wdata;
                                        commit_ptr <= '0;
                                        issue_ptr <= '0;
                                        for(int i = 0; i < ROB_SIZE; i++) // reset the rob to all zeroes
                                            begin
                                                rob[i] <= '0;
                                            end
                                        // queue pointers go to zero for reset
                                        issue_ptr <= '0;
                                        commit_ptr <= '0;
                                        //valid_commit <= '0;
                                        //flush <= 1'b0;
                                        //missed_pc <= '0;
                                    end
                                else
                                    begin
                                        commit_ptr <= commit_ptr + 1'b1;
                                        flush <= 1'b0;
                                        missed_pc <= '0;
                                    end
                            end
                    end
                else
                    begin
                        valid_commit <= 1'b0;
                        flush <= 1'b0;
                        missed_pc <= '0;
                    end
                
            end
    end

always_comb
    begin
        rob_full = 1'b0;
        rob_empty = 1'b0;
        if(commit_ptr == (issue_ptr + 1'b1)) // if issue pointer is behind the write pointer then full
            begin
                rob_full = 1'b1;
            end
        
        stall_preempt = 1'b0;
        if(commit_ptr == (issue_ptr + 2'b10)) // if issue pointer is behind the write pointer then full
            begin
                stall_preempt = 1'b1;
            end
        

        if(commit_ptr == issue_ptr)
            begin
                rob_empty = 1'b1;
            end
        
        if(rob[commit_ptr].branch_mismatch)
            begin
                flush_comb = 1'b1;
            end
        else
            begin
                flush_comb = 1'b0;
            end
        instruction_to_rob_index = issue_ptr;
    end


endmodule