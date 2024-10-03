module rename
import rv32i_types::*;
(
    input   logic   [31:0]  instruction,
    input   logic   [$clog2(NUM_REGS)-1:0]   physical_rd,
    input   logic   [$clog2(NUM_REGS)-1:0]   physical_rs1,
    input   logic   [$clog2(NUM_REGS)-1:0]   physical_rs2,
    output  logic   [4:0]   arch_rd,
    output  logic   [4:0]   arch_rs1,
    output  logic   [4:0]   arch_rs2,
    output  instr_t  renamed_instruction
);

/*
Here whats happening is just instruction segments just being extended to a 38 bit val to account for the difference in physical registers
[4:0] reg size -> [6:0] reg size

!!! Refer to this file when doing instruction decodings in the reg file for immediate sexting and their relative positions
*/

/* 
notes:

3/23 - looks good, but needs testing - stanley 
*/
logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;



assign opcode = instruction[6:0];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];



always_comb
    begin // INSTR TRANSLATION
        unique case(instruction[6:0]) // based on instruction, used rat to replace arch regs to phys regs
            op_b_imm, op_b_jalr, op_b_load: // i types
                begin
                    renamed_instruction.i_type.opcode = opcode;
                    renamed_instruction.i_type.rd = physical_rd;
                    renamed_instruction.i_type.funct3 = funct3;
                    renamed_instruction.i_type.rs1 = physical_rs1;
                    renamed_instruction.i_type.i_imm = instruction[31:20];
                    renamed_instruction.i_type.extra = '0;
                end
            op_b_reg: // r types
                begin
                    renamed_instruction.r_type.opcode = opcode;
                    renamed_instruction.r_type.rd = physical_rd;
                    renamed_instruction.r_type.funct3 = funct3;
                    renamed_instruction.r_type.rs1 = physical_rs1;
                    renamed_instruction.r_type.rs2 = physical_rs2;
                    renamed_instruction.r_type.funct7 = funct7;
                end
            op_b_store: // s type
                begin
                    renamed_instruction.s_type.opcode = opcode;
                    renamed_instruction.s_type.imm_s_bot = instruction[11:7];
                    renamed_instruction.s_type.funct3 = funct3;
                    renamed_instruction.s_type.rs1 = physical_rs1;
                    renamed_instruction.s_type.rs2 = physical_rs2;
                    renamed_instruction.s_type.imm_s_top = instruction[31:25];
                    renamed_instruction.s_type.extra = '0;
                end
            op_b_br: // b type
                begin
                    renamed_instruction.b_type.opcode = opcode;
                    renamed_instruction.b_type.imm_b_bot = instruction[11:7];
                    renamed_instruction.b_type.funct3 = funct3;
                    renamed_instruction.b_type.rs1 = physical_rs1;
                    renamed_instruction.b_type.rs2 = physical_rs2;
                    renamed_instruction.b_type.imm_b_top = instruction[31:25];
                    renamed_instruction.b_type.extra = '0;
                end
            op_b_lui, op_b_auipc, op_b_jal: // j type
                begin
                    renamed_instruction.j_type.opcode = opcode;
                    renamed_instruction.j_type.rd = physical_rd;
                    renamed_instruction.j_type.imm = instruction[31:12];
                    renamed_instruction.j_type.extra = '0;
                end
            op_b_atom: begin
                    renamed_instruction.a_type.opcode = opcode;
                    renamed_instruction.a_type.rd = physical_rd;
                    renamed_instruction.a_type.funct3 = instruction[14:12];
                    renamed_instruction.a_type.rs1 = physical_rs1;
                    renamed_instruction.a_type.rs2 = physical_rs2;
                    renamed_instruction.a_type.funct7 = instruction[31:25];
            end
            default: renamed_instruction = 'x;
        endcase

        // ARCH REG BOOK KEEPING
        unique case(instruction[6:0]) // Forgot I had this, you can merge the 2 cases together if desired im lazy
            op_b_lui: 
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = '0;
                    arch_rs2  = '0;
                end
            op_b_auipc: 
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = '0;
                    arch_rs2  = '0;
                end
            op_b_jal:  
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = '0;
                    arch_rs2  = '0;
                end
            op_b_jalr: 
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = instruction[19:15];
                    arch_rs2  = '0;
                end
            op_b_br: 
                begin
                    arch_rd   = '0;
                    arch_rs1  = instruction[19:15];
                    arch_rs2  = instruction[24:20];
                end
            op_b_load: 
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = instruction[19:15];
                    arch_rs2  = '0;
                end
            op_b_store: 
                begin
                    arch_rd   = '0;
                    arch_rs1  = instruction[19:15];
                    arch_rs2  = instruction[24:20];
                end
            op_b_imm: 
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = instruction[19:15];
                    arch_rs2  = '0;
                end
            op_b_reg, op_b_atom: 
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = instruction[19:15];
                    arch_rs2  = instruction[24:20];
                end
            default: 
                begin
                    arch_rd   = instruction[11:7];
                    arch_rs1  = instruction[19:15];
                    arch_rs2  = instruction[24:20];
                end
        endcase
    end


endmodule