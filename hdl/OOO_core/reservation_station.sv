module reservation_station
import rv32i_types::*;
#(
    parameter STATION_DEPTH = 16,
    parameter ROB_SIZE = 16,
    parameter NUM_BRATS = 16
)
(
    input logic clk,
    input logic rst,
    input instr_t renamed_instruction,
    input logic valid_intruction,
    input logic [$clog2(ROB_SIZE)-1:0] rob_index,
    input logic [4:0] arch_rd,
    input logic [4:0] arch_rs1,
    input logic [4:0] arch_rs2,
    input logic [31:0] pc,
    input logic [31:0] inst,
    input logic branch_pred,
    input logic flush,
    output reservation_station_entry_t reservation_station[STATION_DEPTH],
    output logic ready[STATION_DEPTH],
    //input logic [2:0] valid_src_vec[32],
    input logic [$clog2(STATION_DEPTH)-1:0] finished_idx,
    input logic remove_entry,
    input logic update_valids,
    input logic [63:0] order,
    input logic [NUM_REGS-1:0] phys_valid_vector,
    output logic full,

    input logic [$clog2(NUM_BRATS)-1:0] current_brat,
    input logic brats_full,

    input logic branch_recovery,
    input logic [$clog2(NUM_BRATS)-1:0] branch_resolved_index
);

// reservation_station_entry_t reservation_station[STATION_DEPTH]; // stores reservation station entries
// logic ready[STATION_DEPTH]; // tracks which ones are busy
logic [4:0] rs1_valid_index, rs2_valid_index;

logic [$clog2(STATION_DEPTH)-1:0] next_free_reservation_station_entry; // used to track the next free reservation station

int i;
always_ff @(posedge clk)
    begin
        if(rst || flush) // if reset clear reservation station
            begin
                for(i = 0; i < STATION_DEPTH; i++)
                    begin
                        reservation_station[i].busy <= '0;
                        reservation_station[i].opcode <= '0;
                        reservation_station[i].phys_rd <= '0;
                        reservation_station[i].funct3 <= '0;
                        reservation_station[i].phys_rs1 <= '0;
                        reservation_station[i].phys_rs2 <= '0;
                        reservation_station[i].rob_index <= '0;
                        reservation_station[i].imm <= '0;
                        reservation_station[i].arch_rd <= 'x;
                        reservation_station[i].arch_rs1 <= 'x;
                        reservation_station[i].arch_rs2 <= 'x;
                        reservation_station[i].order <= '0;
                    end
            end
        else
            begin
                // ENTRY REMOVAL LOGIC
                if(remove_entry)
                    begin
                        reservation_station[finished_idx].busy <= 1'b0;
                    end

                if(valid_intruction)
                    begin
                        // This is needed so that we can do things with the translate back when needed
                        reservation_station[next_free_reservation_station_entry].arch_rd <= arch_rd;
                        reservation_station[next_free_reservation_station_entry].arch_rs1 <= arch_rs1;
                        reservation_station[next_free_reservation_station_entry].arch_rs2 <= arch_rs2;
                        reservation_station[next_free_reservation_station_entry].order <= order;
                        reservation_station[next_free_reservation_station_entry].inst <= inst;
                        reservation_station[next_free_reservation_station_entry].branch_pred <= branch_pred;
                        reservation_station[next_free_reservation_station_entry].current_brat <= current_brat;
                        reservation_station[next_free_reservation_station_entry].brats_full <= brats_full;


                        // @TODONE need to add a bunch of conditionals based on opcode
                        unique case(renamed_instruction[6:0]) // based on instruction, used rat to replace arch regs to phys regs
                            op_b_lui: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.j_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= renamed_instruction.j_type.rd;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= '0;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].imm <= {inst[31:12], 12'h000};
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b1; 
                                    reservation_station[next_free_reservation_station_entry].pc <= pc; 
                                end
                            op_b_auipc: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.j_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= renamed_instruction.j_type.rd;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= '0;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b1; 
                                    reservation_station[next_free_reservation_station_entry].imm <= {inst[31:12], 12'h000};
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                end
                            op_b_jal: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.j_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= renamed_instruction.j_type.rd;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= '0;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b1; 
                                    reservation_station[next_free_reservation_station_entry].imm <= 32'h4;
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                end
                            op_b_jalr: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.i_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= renamed_instruction.i_type.rd;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= renamed_instruction.i_type.funct3;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= renamed_instruction.i_type.rs1;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= '0;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b1; 
                                    reservation_station[next_free_reservation_station_entry].imm <= {{21{inst[31]}}, inst[30:20]};
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                end
                            op_b_br: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.b_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= '0;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= renamed_instruction.b_type.funct3;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= renamed_instruction.b_type.rs1;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= renamed_instruction.b_type.rs2;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b0; 
                                    reservation_station[next_free_reservation_station_entry].imm <= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                end
                            op_b_load: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.i_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= renamed_instruction.i_type.rd;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= renamed_instruction.i_type.funct3;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= renamed_instruction.i_type.rs1;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= '0;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].imm <= {{21{inst[31]}}, inst[30:25], inst[11:7]};
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                end
                            op_b_store: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.s_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= '0;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= renamed_instruction.s_type.funct3;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= renamed_instruction.s_type.rs1;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= renamed_instruction.s_type.rs2;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b0;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b1; 
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                    reservation_station[next_free_reservation_station_entry].imm <= {{21{inst[31]}}, inst[30:25], inst[11:7]};
                                end
                            op_b_imm: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.i_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= renamed_instruction.i_type.rd;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= renamed_instruction.i_type.funct3;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= renamed_instruction.i_type.rs1;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= '0;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= (renamed_instruction.i_type.funct3 == slt || renamed_instruction.i_type.funct3 == sltu) ? 1'b0 : 1'b1;
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                    // reservation_station[next_free_reservation_station_entry].imm <= renamed_instruction.i_type.i_imm;
                                    reservation_station[next_free_reservation_station_entry].funct7 <= inst[31:25]; 
                                    reservation_station[next_free_reservation_station_entry].imm <= renamed_instruction.i_type.funct3 == 3'b101 ? {{27{inst[31]}}, inst[24:20]} : {{21{inst[31]}}, inst[30:20]};
                                end
                            op_b_reg: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].opcode <= renamed_instruction.r_type.opcode;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= renamed_instruction.r_type.rd;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= renamed_instruction.r_type.funct3;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= renamed_instruction.r_type.rs1;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= renamed_instruction.r_type.rs2;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= rob_index;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b1;
                                    reservation_station[next_free_reservation_station_entry].aluc <= (renamed_instruction.r_type.funct3 == slt || renamed_instruction.r_type.funct3 == sltu) ? 1'b0 : 1'b1; 
                                    reservation_station[next_free_reservation_station_entry].imm <= '0;
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                    reservation_station[next_free_reservation_station_entry].funct7 <= inst[31:25];
                                end
                            default: 
                                begin
                                    reservation_station[next_free_reservation_station_entry].busy <= '0;
                                    reservation_station[next_free_reservation_station_entry].opcode <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rd <= '0;
                                    reservation_station[next_free_reservation_station_entry].funct3 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs1 <= '0;
                                    reservation_station[next_free_reservation_station_entry].phys_rs2 <= '0;
                                    reservation_station[next_free_reservation_station_entry].rob_index <= '0;
                                    reservation_station[next_free_reservation_station_entry].regf_we <= 1'b0;
                                    reservation_station[next_free_reservation_station_entry].aluc <= 1'b0; 
                                    reservation_station[next_free_reservation_station_entry].pc <= pc;
                                    reservation_station[next_free_reservation_station_entry].imm <= '0;
                                end
                        endcase
                    end
                
                if(branch_recovery)
                    begin
                        for(int aa = 0; aa < STATION_DEPTH; aa++)
                            begin
                                if(reservation_station[aa].current_brat > branch_resolved_index)
                                    begin
                                        reservation_station[aa].busy <= 1'b0;
                                    end
                            end
                    end
            end
    end

logic [15:0] busy_bits;
// logic [$clog2(STATION_DEPTH)-1:0] j;
int k, l, j;
always_comb 
    begin: BUSY_BITS
        // REVERSE LOOP TO GET RID OF BREAKS
        for(j = 15; j >= 0; j--) // creates bit vector of busy bits
            begin
                if(reservation_station[j].busy == 1'b1) busy_bits[j] = 1'b1;
                else busy_bits[j] = 1'b0;
            end
    end

always_comb 
    begin: FIND_NEXT_FREE_STATION
        full = 1'b0;
        // if((~busy_bits[0] && ~remove_entry) || (~busy_bits[0] && remove_entry && finished_idx != 3'd0)) begin
        //     next_free_reservation_station_entry = 3'd0;
        // end else if((~busy_bits[1] && ~remove_entry) || (~busy_bits[1] && remove_entry && finished_idx != 3'd1)) begin
        //     next_free_reservation_station_entry = 3'd1;
        // end else if((~busy_bits[2] && ~remove_entry) || (~busy_bits[2] && remove_entry && finished_idx != 3'd2)) begin
        //     next_free_reservation_station_entry = 3'd2;
        // end else if((~busy_bits[3] && ~remove_entry) || (~busy_bits[3] && remove_entry && finished_idx != 3'd3)) begin
        //     next_free_reservation_station_entry = 3'd3;
        // end else if((~busy_bits[4] && ~remove_entry) || (~busy_bits[4] && remove_entry && finished_idx != 3'd4)) begin
        //     next_free_reservation_station_entry = 3'd4;
        // end else if((~busy_bits[5] && ~remove_entry) || (~busy_bits[5] && remove_entry && finished_idx != 3'd5)) begin
        //     next_free_reservation_station_entry = 3'd5;
        // end else if((~busy_bits[6] && ~remove_entry) || (~busy_bits[6] && remove_entry && finished_idx != 3'd6)) begin
        //     next_free_reservation_station_entry = 3'd6;
        // end else if((~busy_bits[7] && ~remove_entry) || (~busy_bits[7] && remove_entry && finished_idx != 3'd7)) begin
        //     next_free_reservation_station_entry = 3'd7;
        // end else begin
        //     next_free_reservation_station_entry = 'x;
        //     full = 1'b1;
        // end

        if((~busy_bits[0] && ~remove_entry) || (~busy_bits[0] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd0;
        end else if((~busy_bits[1] && ~remove_entry) || (~busy_bits[1] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd1;
        end else if((~busy_bits[2] && ~remove_entry) || (~busy_bits[2] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd2;
        end else if((~busy_bits[3] && ~remove_entry) || (~busy_bits[3] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd3;
        end else if((~busy_bits[4] && ~remove_entry) || (~busy_bits[4] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd4;
        end else if((~busy_bits[5] && ~remove_entry) || (~busy_bits[5] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd5;
        end else if((~busy_bits[6] && ~remove_entry) || (~busy_bits[6] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd6;
        end else if((~busy_bits[7] && ~remove_entry) || (~busy_bits[7] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd7;
        end else if((~busy_bits[8] && ~remove_entry) || (~busy_bits[8] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd8;
        end else if((~busy_bits[9] && ~remove_entry) || (~busy_bits[9] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd9;
        end else if((~busy_bits[10] && ~remove_entry) || (~busy_bits[10] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd10;
        end else if((~busy_bits[11] && ~remove_entry) || (~busy_bits[11] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd11;
        end else if((~busy_bits[12] && ~remove_entry) || (~busy_bits[12] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd12;
        end else if((~busy_bits[13] && ~remove_entry) || (~busy_bits[13] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd13;
        end else if((~busy_bits[14] && ~remove_entry) || (~busy_bits[14] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd14;
        end else if((~busy_bits[15] && ~remove_entry) || (~busy_bits[15] && remove_entry)) begin
            next_free_reservation_station_entry = 4'd15;
        end else begin
            next_free_reservation_station_entry = 'x;
            full = 1'b1;
        end


    end
        
int m;
always_comb
    begin

        // for(k = 0; k < STATION_DEPTH; k++) // for loop to update valid value, 1 when regs ready, 0 when not
        //     begin
        //         if(reservation_station[k].rs1_valid)
        //         
        //     end
        
        for(l = 0; l < STATION_DEPTH; l++) // use these signals to send the reservation station line out to the prf and the alu
            begin
                ready[l] = ((reservation_station[l].busy == 1'b1) && (reservation_station[l].rs1_valid && reservation_station[l].rs2_valid));
            end
    end

always_comb
//always_ff @(posedge clk)
    begin
        if(update_valids || valid_intruction)
            begin
                for(k = 0; k < STATION_DEPTH; k++) // for loop to update valid value, 1 when regs ready, 0 when not
                    begin
                        reservation_station[k].rs1_valid = phys_valid_vector[reservation_station[k].phys_rs1];
                        reservation_station[k].rs2_valid = phys_valid_vector[reservation_station[k].phys_rs2];
                    end
            end
        else
            begin
                for(k = 0; k < STATION_DEPTH; k++) // for loop to update valid value, 1 when regs ready, 0 when not
                    begin
                        reservation_station[k].rs1_valid = phys_valid_vector[reservation_station[k].phys_rs1];
                        reservation_station[k].rs2_valid = phys_valid_vector[reservation_station[k].phys_rs2];
                    end
            end
    end



endmodule