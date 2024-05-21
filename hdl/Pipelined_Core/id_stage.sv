module id_stage
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    input   logic   [31:0]      inst, // imem_addr
    input   if_id_reg_t         if_id_reg,

    input   logic               valid_write,

    input   logic               regf_we,
    input   logic   [4:0]       rd_s,
    input   logic   [31:0]      rd_v,

    output id_ex_reg_t          id_ex_reg_next
);

// Instruction Decoder Vars

logic [2:0] funct3;
logic [6:0] funct7;
logic [6:0] opcode;

logic [4:0] rd;
logic [4:0] rs1_s;
logic [4:0] rs2_s;

// Immediate Generator Vars

logic [31:0] s_imm, b_imm, u_imm, j_imm, i_imm;
logic [31:0] imm;

// Control Unit Vars

logic writeback;
logic mem_read;
logic mem_write;
logic branch;
logic jalr;
logic jal;
logic alu_src;
logic calu;
logic [2:0] aluop;

//Regfile Vars

logic [31:0] rs1_v, rs2_v;


always_comb
    begin : instruction_decoder

        funct3 = inst[14:12];
        funct7 = inst[31:25];
        opcode = inst[6:0];
        rd = inst[11:7];

        unique case(opcode) // If register is not used just set to 0;
            op_b_lui: 
                begin
                    rs1_s  = '0;
                    rs2_s  = '0;
                end
            op_b_auipc: 
                begin
                    rs1_s  = '0;
                    rs2_s  = '0;
                end
            op_b_jal:  
                begin
                    rs1_s  = '0;
                    rs2_s  = '0;
                end
            op_b_jalr: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = '0;
                end
            op_b_br: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = inst[24:20];
                end
            op_b_load: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = '0;
                end
            op_b_store: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = inst[24:20];
                end
            op_b_imm: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = '0;
                end
            op_b_reg: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = inst[24:20];
                end
            op_b_csr: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = inst[24:20];
                end
            default: 
                begin
                    rs1_s  = inst[19:15];
                    rs2_s  = inst[24:20];
                end
        endcase

    end : instruction_decoder

always_comb
    begin : immediate_generator

        s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
        b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        u_imm  = {inst[31:12], 12'h000};
        j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

        if((opcode == op_b_imm) && (funct3 == 3'b101)) // Accounts for edgecase where shamt has a 1
            begin
                i_imm  = {{27{inst[31]}}, inst[24:20]};
            end
        else
            begin
                i_imm  = {{21{inst[31]}}, inst[30:20]};
            end
        
        // immediate selector mux
        unique case(opcode)
            op_b_lui: imm = u_imm;
            op_b_auipc: imm = u_imm;
            op_b_jal: imm = 32'h4;
            op_b_jalr: imm = 32'h4;
            op_b_br: imm = b_imm;
            op_b_load: imm = i_imm;
            op_b_store: imm = s_imm;
            op_b_imm: imm = i_imm;
            op_b_reg: imm = 0;
            op_b_csr: imm = i_imm;
            default: imm = '0;
        endcase

    end : immediate_generator

always_comb
    begin : control_unit
        
        unique case(opcode) // writeback / regf_we
            op_b_lui, op_b_auipc, op_b_jal, op_b_jalr, op_b_load, op_b_imm, op_b_reg: writeback = 1'b1;
            op_b_store, op_b_br: writeback = 1'b0;
            default: writeback = 'x;
        endcase

        unique case(opcode) // load
            op_b_lui, op_b_auipc, op_b_jal, op_b_jalr, op_b_store, op_b_imm, op_b_reg, op_b_br: mem_read = 1'b0;
            op_b_load: mem_read = 1'b1;
            default: mem_read = 'x;
        endcase

        unique case(opcode) // store
            op_b_lui, op_b_auipc, op_b_jal, op_b_jalr, op_b_load, op_b_imm, op_b_reg, op_b_br: mem_write = 1'b0;
            op_b_store: mem_write = 1'b1;
            default: mem_write = 'x;
        endcase

        unique case(opcode) // reg = 0, imm = 1
            op_b_store, op_b_lui, op_b_auipc, op_b_jal, op_b_jalr, op_b_load, op_b_imm: alu_src = 1'b1;
            op_b_br, op_b_reg: alu_src = 1'b0;
            default: alu_src = 'x;
        endcase

        // unique case(opcode) // reg = 0, imm = 1
        //     op_b_lui, op_b_auipc, op_b_store, op_b_reg, op_b_load, op_b_imm: branch = 1'b0;
        //     op_b_jal, op_b_br, op_b_jalr: branch = 1'b1;
        //     default: branch = 'x;
        // endcase

        unique case(opcode) // reg = 0, imm = 1
            op_b_jal, op_b_jalr, op_b_lui, op_b_auipc, op_b_store, op_b_reg, op_b_load, op_b_imm: branch = 1'b0;
            op_b_br: branch = 1'b1;
            default: branch = 'x;
        endcase

        unique case(opcode) // reg = 0, imm = 1
            op_b_lui, op_b_auipc, op_b_store, op_b_reg, op_b_load, op_b_imm, op_b_jal, op_b_br: jalr = 1'b0;
            op_b_jalr: jalr = 1'b1;
            default: jalr = 'x;
        endcase

        unique case(opcode) // reg = 0, imm = 1
            op_b_lui, op_b_auipc, op_b_store, op_b_reg, op_b_load, op_b_imm, op_b_jalr, op_b_br: jal = 1'b0;
            op_b_jal: jal = 1'b1;
            default: jal = 'x;
        endcase

        unique case(opcode)
            op_b_lui: begin
                calu = 1'b1;
                aluop = alu_add;
            end
            op_b_auipc: begin
                calu = 1'b1;
                aluop = alu_add;
            end
            op_b_jal: begin
                calu = 1'b1;
                aluop = alu_add;
            end
            op_b_jalr: begin
                calu = 1'b1;
                aluop = alu_add;
            end
            op_b_br: begin
                calu = 1'b0;
                aluop = funct3;
            end
            op_b_load: begin
                calu = 1'b1;
                aluop = alu_add;
            end
            op_b_store: begin
                calu = 1'b1;
                aluop = alu_add;
            end
            op_b_imm: begin
                    unique case (funct3)
                        slt: begin
                            calu = 1'b0;
                            aluop = blt;
                        end
                        sltu: begin
                            calu = 1'b0;
                            aluop = bltu;
                        end
                        sr: begin
                            if (funct7[5]) begin
                                aluop = alu_sra;
                            end else begin
                                aluop = alu_srl;
                            end
                            calu = 1'b1;
                        end
                        default: begin
                            aluop = funct3;
                            calu = 1'b1;
                        end
                    endcase
                end
            op_b_reg: begin
                    unique case (funct3)
                        slt: begin
                            calu = 1'b0;
                            aluop = blt;
                        end
                        sltu: begin
                            aluop = bltu;
                            calu = 1'b0;
                        end
                        sr: begin
                            if (funct7[5]) begin
                                aluop = alu_sra;
                            end else begin
                                aluop = alu_srl;
                            end
                            calu = 1'b1;
                        end
                        add: begin
                            if (funct7[5]) begin
                                aluop = alu_sub;
                            end else begin
                                aluop = alu_add;
                            end
                            calu = 1'b1;
                        end
                        default: begin
                            aluop = funct3;
                            calu = 1'b1;
                        end
                    endcase
                end
            default: begin
                aluop = '0;
                calu = '1;
            end
        endcase

    end : control_unit

logic [4:0] rdd;
logic [31:0] rdvv;
always_comb
    begin
        if(valid_write) rdd = rd_s;
        else rdd = '0;

        if(valid_write) rdvv = rd_v;
        else rdvv = '0;
    end

always_comb
    begin : setting_if_id_reg_next

        id_ex_reg_next.pc = if_id_reg.pc;
        id_ex_reg_next.branch_pred = if_id_reg.branch_pred;
        id_ex_reg_next.predicted_pc = if_id_reg.predicted_pc;

        id_ex_reg_next.regf_we = writeback;

        id_ex_reg_next.mem_read = mem_read;
        id_ex_reg_next.mem_write = mem_write;
        id_ex_reg_next.branch = branch;
        id_ex_reg_next.jalr = jalr;
        id_ex_reg_next.jal = jal;
        
        id_ex_reg_next.alu_src = alu_src;
        id_ex_reg_next.alu_or_cmp = calu; // 0 for cmp 1 for alu
        id_ex_reg_next.alu_op = aluop;

        id_ex_reg_next.opcode = inst[6:0];

        id_ex_reg_next.rs1_v = (rdd == rs1_s && rdd != '0) ? rd_v : rs1_v;
        id_ex_reg_next.rs2_v = (rdd == rs2_s && rdd != '0) ? rd_v : rs2_v;
        id_ex_reg_next.imm = imm;
        id_ex_reg_next.jalr_imm = i_imm;
        id_ex_reg_next.jal_imm = j_imm;

        id_ex_reg_next.rd_s = (opcode == op_b_store || opcode == op_b_br) ? '0 : rd;
        id_ex_reg_next.rs1_s = rs1_s;
        id_ex_reg_next.rs2_s = rs2_s;

        id_ex_reg_next.funct7_bit = inst[30];
        id_ex_reg_next.funct3 = inst[14:12];

        id_ex_reg_next.rvfi.monitor_valid = if_id_reg.rvfi.monitor_valid;
        id_ex_reg_next.rvfi.monitor_order = if_id_reg.rvfi.monitor_order;
        id_ex_reg_next.rvfi.monitor_inst = inst;

        id_ex_reg_next.rvfi.monitor_rs1_addr = rs1_s;
        id_ex_reg_next.rvfi.monitor_rs2_addr = rs2_s;
        id_ex_reg_next.rvfi.monitor_regf_we = writeback;
        id_ex_reg_next.rvfi.monitor_rs1_rdata = (rdd == rs1_s && rdd != '0) ? rd_v : rs1_v;
        id_ex_reg_next.rvfi.monitor_rs2_rdata = (rdd == rs2_s && rdd != '0) ? rd_v : rs2_v;

        id_ex_reg_next.rvfi.monitor_rd_addr = (opcode == op_b_store || opcode == op_b_br) ? '0 : rd;
        id_ex_reg_next.rvfi.monitor_rd_wdata = rd_v;

        id_ex_reg_next.rvfi.monitor_pc_rdata = if_id_reg.rvfi.monitor_pc_rdata;
        id_ex_reg_next.rvfi.monitor_pc_wdata = if_id_reg.rvfi.monitor_pc_wdata;

    end : setting_if_id_reg_next

pipeline_regfile rf_dec_1
(
    .clk(clk),
    .rst(rst),
    .regf_we(regf_we & valid_write),
    .rd_v(rdvv),
    .rs1_s(rs1_s),
    .rs2_s(rs2_s),
    .rd_s(rdd),
    .rs1_v(rs1_v),
    .rs2_v(rs2_v)
);

endmodule
