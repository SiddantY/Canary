module rat
import rv32i_types::*;
#(
    parameter NUM_BRATS = 16
)
(
    input   logic           clk,
    input   logic           rst,
    input   logic   [4:0]   arch_rs1,
    input   logic   [4:0]   arch_rs2,
    input   logic           update_mapping,
    input   logic   [4:0]   arch_reg_to_update,
    input   logic   [$clog2(NUM_REGS)-1:0]   phys_reg_update,
    input   logic           update_valid,
    input   logic           update_valid_mul,
    input   logic           update_valid_ldst,
    input   logic   [4:0]   arch_reg_valid_update,
    input   logic   [$clog2(NUM_REGS)-1:0]   phys_reg_valid_update,
    input   logic   [4:0]   arch_reg_valid_update_mul,
    input   logic   [$clog2(NUM_REGS)-1:0]   phys_reg_valid_update_mul,
    input   logic   [4:0]   arch_reg_valid_update_ldst,
    input   logic   [$clog2(NUM_REGS)-1:0]   phys_reg_valid_update_ldst,
    input   logic           flush,
    input   logic   [$clog2(NUM_REGS)-1:0]  rrf_arch_to_physical[32],
    output  logic   [$clog2(NUM_REGS)-1:0]   physical_rs1,
    output  logic   [$clog2(NUM_REGS)-1:0]   physical_rs2,
    //output  logic  [2:0]   valid_vec[32],
    input  logic   [NUM_REGS-1:0]          brat_free_lists[NUM_BRATS],
    output  logic [NUM_REGS-1:0] phys_valid_vector,
    
    input   logic branch_recovery,
    input   logic [$clog2(NUM_BRATS)-1:0] branch_resolved_index,
    output  logic [$clog2(NUM_REGS)-1:0] arch_to_physical[32], // ISA regs to Physical Reg mappings, 9th bit for valid, rest 8 bits cuz 128 phys regs for now. 32 for 32 arch regs
    input  logic   [$clog2(NUM_REGS)-1:0]  brats[NUM_BRATS][32]
);

// logic [127:0] phys_valid_vector;

always_ff @(posedge clk)
    begin
        if (rst) // if reset just make x0 -> pr0, x1 -> pr1, ..., xn -> prn
            begin
                // for (logic[4:0] i = 5'd0; i <= 5'd31; i = i + 1'b1) - !!! THIS DOESNT SIM BRUH

                for(int p = 0; p < NUM_REGS; p++)
                    begin
                        phys_valid_vector[p] <= 1'b1;
                    end

                arch_to_physical[0][$clog2(NUM_REGS)-1:0] <= 6'd00;
                arch_to_physical[1][$clog2(NUM_REGS)-1:0] <= 6'd01;
                arch_to_physical[2][$clog2(NUM_REGS)-1:0] <= 6'd02;
                arch_to_physical[3][$clog2(NUM_REGS)-1:0] <= 6'd03;
                arch_to_physical[4][$clog2(NUM_REGS)-1:0] <= 6'd04;
                arch_to_physical[5][$clog2(NUM_REGS)-1:0] <= 6'd05;
                arch_to_physical[6][$clog2(NUM_REGS)-1:0] <= 6'd06;
                arch_to_physical[7][$clog2(NUM_REGS)-1:0] <= 6'd07;
                arch_to_physical[8][$clog2(NUM_REGS)-1:0] <= 6'd08;
                arch_to_physical[9][$clog2(NUM_REGS)-1:0] <= 6'd09;
                arch_to_physical[10][$clog2(NUM_REGS)-1:0] <= 6'd10;
                arch_to_physical[11][$clog2(NUM_REGS)-1:0] <= 6'd11;
                arch_to_physical[12][$clog2(NUM_REGS)-1:0] <= 6'd12;
                arch_to_physical[13][$clog2(NUM_REGS)-1:0] <= 6'd13;
                arch_to_physical[14][$clog2(NUM_REGS)-1:0] <= 6'd14;
                arch_to_physical[15][$clog2(NUM_REGS)-1:0] <= 6'd15;
                arch_to_physical[16][$clog2(NUM_REGS)-1:0] <= 6'd16;
                arch_to_physical[17][$clog2(NUM_REGS)-1:0] <= 6'd17;
                arch_to_physical[18][$clog2(NUM_REGS)-1:0] <= 6'd18;
                arch_to_physical[19][$clog2(NUM_REGS)-1:0] <= 6'd19;
                arch_to_physical[20][$clog2(NUM_REGS)-1:0] <= 6'd20;
                arch_to_physical[21][$clog2(NUM_REGS)-1:0] <= 6'd21;
                arch_to_physical[22][$clog2(NUM_REGS)-1:0] <= 6'd22;
                arch_to_physical[23][$clog2(NUM_REGS)-1:0] <= 6'd23;
                arch_to_physical[24][$clog2(NUM_REGS)-1:0] <= 6'd24;
                arch_to_physical[25][$clog2(NUM_REGS)-1:0] <= 6'd25;
                arch_to_physical[26][$clog2(NUM_REGS)-1:0] <= 6'd26;
                arch_to_physical[27][$clog2(NUM_REGS)-1:0] <= 6'd27;
                arch_to_physical[28][$clog2(NUM_REGS)-1:0] <= 6'd28;
                arch_to_physical[29][$clog2(NUM_REGS)-1:0] <= 6'd29;
                arch_to_physical[30][$clog2(NUM_REGS)-1:0] <= 6'd30;
                arch_to_physical[31][$clog2(NUM_REGS)-1:0] <= 6'd31;
            end 
        else
            begin
                if(flush)
                    begin
                        //arch_to_physical[] <= rrf_arch_to_physical;
                        for (int i1 = 0; i1 < 32; i1++) 
                            begin
                                arch_to_physical[i1][$clog2(NUM_REGS)-1:0] <= rrf_arch_to_physical[i1];
                            end

                        for(int p1 = 0; p1 < NUM_REGS; p1++)
                            begin
                                phys_valid_vector[p1] <= 1'b1;
                            end

                        // for(int c = 0; c < 32; c++)
                        //     begin
                        //         phys_valid_vector[rrf_arch_to_physical[c]] <= 1'b0;
                        //     end
                    end
                else if(branch_recovery)
                    begin
                        
                        for (int i1 = 0; i1 < 32; i1++) 
                            begin
                                arch_to_physical[i1][$clog2(NUM_REGS)-1:0] <= brats[branch_resolved_index][i1];
                            end
                        
                        for(int p1 = 0; p1 < NUM_REGS; p1++)
                            begin
                                phys_valid_vector[p1] <= 1'b1;
                            end

                        // phys_valid_vector <= brat_free_lists[branch_resolved_index];

                    end
                else
                    begin
                        if(update_mapping && (arch_reg_to_update != 5'd0)) // only update mapping when update mapping flag is high, x0->p0 since x0 should always be 0
                            begin
                                phys_valid_vector[phys_reg_update] <= 1'b0;
                                //arch_to_physical[arch_reg_to_update][9:7] <= arch_to_physical[arch_reg_to_update][9:7] + 1'b1; // reg is no longer valid since we are going to perform operations on it
                                arch_to_physical[arch_reg_to_update][$clog2(NUM_REGS)-1:0] <= phys_reg_update; // physical reg comes from free list
                            end
                        if(update_valid && (arch_reg_valid_update != 5'd0)) // update valid when free list/execute says so
                            begin
                                phys_valid_vector[phys_reg_valid_update] <= 1'b1;
                                //arch_to_physical[arch_reg_valid_update][9:7] <= arch_to_physical[arch_reg_to_update][9:7] - 1'b1; // reg is valid, it can be used by dependent operations now
                            end
                        
                        if(update_valid_mul && (arch_reg_valid_update_mul != 5'd0)) // update valid when free list/execute says so
                            begin
                                phys_valid_vector[phys_reg_valid_update_mul] <= 1'b1;
                                //arch_to_physical[arch_reg_valid_update_mul][9:7] <= arch_to_physical[arch_reg_valid_update_mul][9:7] - 1'b1; // reg is valid, it can be used by dependent operations now
                            end

                        if(update_valid_ldst && (arch_reg_valid_update_ldst != 5'd0)) // update valid when free list/execute says so
                            begin
                                phys_valid_vector[phys_reg_valid_update_ldst] <= 1'b1;
                                //arch_to_physical[arch_reg_valid_update_ldst][9:7] <= arch_to_physical[arch_reg_valid_update_ldst][9:7] - 1'b1; // reg is valid, it can be used by dependent operations now
                            end
                    end
            end
    end

always_comb 
    begin : COVERTED_REGS_EXPORT

        physical_rs1 = arch_rs1 == 5'd0 ? 6'd0 : arch_to_physical[arch_rs1][$clog2(NUM_REGS)-1:0]; // if valid

        physical_rs2 = arch_rs2 == 5'd0 ? 6'd0 : arch_to_physical[arch_rs2][$clog2(NUM_REGS)-1:0];


    end

endmodule