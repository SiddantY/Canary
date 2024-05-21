module rrf
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   rob_entry_t     rob_instruction_to_commit,
    input   logic           update_mapping,
    output  logic   [$clog2(NUM_REGS)-1:0]   liberated_phys_reg,
    output  logic           reg_freed,
    output  logic   [$clog2(NUM_REGS)-1:0]   rrf_arch_to_physical[32]
);

//logic [6:0] rrf_arch_to_physical[32]; // ISA regs to Physical Reg mappings, 9th bit for valid, rest 8 bits cuz 128 phys regs for now. 32 for 32 arch regs
// logic[4:0] i;
int i;
always_ff @(posedge clk)
    begin
        if (rst) // if reset just make x0 -> pr0, x1 -> pr1, ..., xn -> prn
            begin
                // for (i = 5'd0; i <= 5'd31; i = i + 1'b1) 
                // for(i = 0; i < 32; i++)
                //     begin
                //         rrf_arch_to_physical[i] <= i[6:0]; // set valid and set to account for bit diff
                //     end

                rrf_arch_to_physical[0][$clog2(NUM_REGS)-1:0] <= 6'd00;
                rrf_arch_to_physical[1][$clog2(NUM_REGS)-1:0] <= 6'd01;
                rrf_arch_to_physical[2][$clog2(NUM_REGS)-1:0] <= 6'd02;
                rrf_arch_to_physical[3][$clog2(NUM_REGS)-1:0] <= 6'd03;
                rrf_arch_to_physical[4][$clog2(NUM_REGS)-1:0] <= 6'd04;
                rrf_arch_to_physical[5][$clog2(NUM_REGS)-1:0] <= 6'd05;
                rrf_arch_to_physical[6][$clog2(NUM_REGS)-1:0] <= 6'd06;
                rrf_arch_to_physical[7][$clog2(NUM_REGS)-1:0] <= 6'd07;
                rrf_arch_to_physical[8][$clog2(NUM_REGS)-1:0] <= 6'd08;
                rrf_arch_to_physical[9][$clog2(NUM_REGS)-1:0] <= 6'd09;
                rrf_arch_to_physical[10][$clog2(NUM_REGS)-1:0] <= 6'd10;
                rrf_arch_to_physical[11][$clog2(NUM_REGS)-1:0] <= 6'd11;
                rrf_arch_to_physical[12][$clog2(NUM_REGS)-1:0] <= 6'd12;
                rrf_arch_to_physical[13][$clog2(NUM_REGS)-1:0] <= 6'd13;
                rrf_arch_to_physical[14][$clog2(NUM_REGS)-1:0] <= 6'd14;
                rrf_arch_to_physical[15][$clog2(NUM_REGS)-1:0] <= 6'd15;
                rrf_arch_to_physical[16][$clog2(NUM_REGS)-1:0] <= 6'd16;
                rrf_arch_to_physical[17][$clog2(NUM_REGS)-1:0] <= 6'd17;
                rrf_arch_to_physical[18][$clog2(NUM_REGS)-1:0] <= 6'd18;
                rrf_arch_to_physical[19][$clog2(NUM_REGS)-1:0] <= 6'd19;
                rrf_arch_to_physical[20][$clog2(NUM_REGS)-1:0] <= 6'd20;
                rrf_arch_to_physical[21][$clog2(NUM_REGS)-1:0] <= 6'd21;
                rrf_arch_to_physical[22][$clog2(NUM_REGS)-1:0] <= 6'd22;
                rrf_arch_to_physical[23][$clog2(NUM_REGS)-1:0] <= 6'd23;
                rrf_arch_to_physical[24][$clog2(NUM_REGS)-1:0] <= 6'd24;
                rrf_arch_to_physical[25][$clog2(NUM_REGS)-1:0] <= 6'd25;
                rrf_arch_to_physical[26][$clog2(NUM_REGS)-1:0] <= 6'd26;
                rrf_arch_to_physical[27][$clog2(NUM_REGS)-1:0] <= 6'd27;
                rrf_arch_to_physical[28][$clog2(NUM_REGS)-1:0] <= 6'd28;
                rrf_arch_to_physical[29][$clog2(NUM_REGS)-1:0] <= 6'd29;
                rrf_arch_to_physical[30][$clog2(NUM_REGS)-1:0] <= 6'd30;
                rrf_arch_to_physical[31][$clog2(NUM_REGS)-1:0] <= 6'd31;
            end 
        else
            begin
                if(update_mapping && rob_instruction_to_commit.arch_rd != '0) // only update mapping when update mapping flag is high, x0->p0 since x0 should always be 0
                    begin
                        reg_freed <= 1'b1;
                        liberated_phys_reg <= rrf_arch_to_physical[rob_instruction_to_commit.arch_rd];
                        rrf_arch_to_physical[rob_instruction_to_commit.arch_rd] <= rob_instruction_to_commit.phys_rd; // rob entry update for rrf
                    end
                else
                    begin
                        reg_freed <= 1'b0;
                    end
            end
    end

endmodule