module brat
import rv32i_types::*;
#(
    parameter NUM_REGS = 64,
    parameter NUM_BRATS = 16
)
(
    input   logic                           clk,
    input   logic                           rst,

    input   logic                           flush,

    output  logic                           brats_full,

    input   logic                           valid_branch,

    input   logic   [63:0]                  phys_valid_vector,
    input   logic   [$clog2(NUM_REGS)-1:0]  arch_to_physical[32],

    input   logic                           branch_recovery,
    input   logic   [$clog2(NUM_BRATS)-1:0] branch_resolved_index,

    output  logic   [$clog2(NUM_BRATS)-1:0] current_brat,
    output  logic   [NUM_REGS-1:0]          brat_free_lists[NUM_BRATS],
    output  logic   [$clog2(NUM_REGS)-1:0]  brats[NUM_BRATS][32]
);

always_ff @(posedge clk)
    begin
        if(rst | flush)
            begin
                current_brat <= '0;

                for(int i = 0; i < NUM_BRATS; i++)
                    begin
                        for(int j = 0; j < 32; j++)
                            begin
                                brats[i][j] <= '0;
                            end
                    end
            end
        else
            begin
                if(valid_branch & ~brats_full)
                    begin
                        
                        for(int i = 0; i < 32; i++)
                            begin
                                brats[current_brat][i] <= arch_to_physical[i];
                            end
                        
                        brat_free_lists[current_brat] <= phys_valid_vector;
                        current_brat <= current_brat + 1'b1;

                    end
                
                if(branch_recovery && current_brat >= branch_resolved_index)
                    begin
                        current_brat <= (branch_resolved_index == 4'd0) ? '0 : branch_resolved_index - 1'b1;
                    end
            end
    end

always_comb 
    begin
        brats_full = (current_brat == 4'b1111) ? 1'b1 : 1'b0;
    end

endmodule