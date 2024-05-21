module ex_stage
import rv32i_types::*;
(
    input   id_ex_reg_t     id_ex_reg,

    output  ex_mem_reg_t    ex_mem_reg_next,

    input   logic           dstall,

    input   logic           mem_read_next,
    input   logic   [31:0]  ld_forward_val,

    input   logic   [31:0]  rd_v_wb,
    input   logic   [4:0]   rd_s_wb,
    input   logic           write_back_wb,

    input   logic   [31:0]  rd_v_mem,
    input   logic   [4:0]   rd_s_mem,
    input   logic           write_back_mem,

    output  logic           br_en,
    output  logic   [31:0]  mispredict_pc
);

// Forwarding Unit Vars
logic [1:0] r1_mux_select, r2_mux_select;

// ALU Vars
logic [31:0] a, b, f;

//ALU select logic vals
logic [31:0] r1_val, r2_val;

// PC Adder Vars
// logic [31:0] mispredict_pc;

always_comb
    begin : alu_operands_select
        
        unique case(r1_mux_select) // first r1 mux
            2'b00: r1_val = id_ex_reg.rs1_v;
            2'b01: 
                begin
                    r1_val = rd_v_wb;
                end
            2'b10:
                begin
                    if(mem_read_next) r1_val = ld_forward_val;
                    else r1_val = rd_v_mem;
                end
            default: r1_val = id_ex_reg.rs1_v;
        endcase

        unique case(r2_mux_select) // first r2 mux
            2'b00: r2_val = id_ex_reg.rs2_v;
            2'b01: 
                begin
                    r2_val = rd_v_wb;
                end
            2'b10:
                begin
                    if(mem_read_next) r2_val = ld_forward_val;
                    else r2_val = rd_v_mem;
                end
            default: r2_val = id_ex_reg.rs2_v;
        endcase

        // a = r1_val; // r1 mux2 lol 
        unique case(id_ex_reg.opcode)
            op_b_lui: a = (32'h0000_0000);
            op_b_auipc: a = id_ex_reg.pc;
            op_b_jal: a = id_ex_reg.pc;
            op_b_jalr: a = id_ex_reg.pc;
            op_b_br: a = r1_val;
            op_b_load: a = r1_val;
            op_b_store: a = r1_val;
            op_b_imm: a = r1_val;
            op_b_reg: a = r1_val;
            default: a = '0;
        endcase

        unique case(id_ex_reg.alu_src) // r2 mux2
            1'b0: b = r2_val;
            1'b1: b = id_ex_reg.imm;
            default: b = 'x;
        endcase

    end : alu_operands_select

always_comb
    begin : pc_adder

        // br_en = (id_ex_reg.branch) & id_ex_reg.rvfi.monitor_valid;
        br_en = '0;

        if(id_ex_reg.jalr & ~dstall)
            begin
                mispredict_pc = (r1_val + id_ex_reg.jalr_imm) & 32'hFFFFFFFE;
                br_en = id_ex_reg.rvfi.monitor_valid;
            end
        else if(id_ex_reg.jal & ~dstall)
            begin
                mispredict_pc = id_ex_reg.pc + id_ex_reg.jal_imm;
                br_en = id_ex_reg.rvfi.monitor_valid;
            end
        else if(id_ex_reg.branch & ~dstall)
            begin
                mispredict_pc = id_ex_reg.pc + id_ex_reg.imm;
                br_en = (f[0]) & id_ex_reg.rvfi.monitor_valid;
            end
        else
            begin
                mispredict_pc = 32'h0000_0000;
                br_en = 1'b0;
            end
    end : pc_adder

always_comb
    begin : fill_out_reg_next
        ex_mem_reg_next.regf_we = id_ex_reg.regf_we;
        ex_mem_reg_next.mem_read = id_ex_reg.mem_read;
        ex_mem_reg_next.mem_write = id_ex_reg.mem_write;

        ex_mem_reg_next.alu_result = f;
        ex_mem_reg_next.rs2_v = r2_val;
        ex_mem_reg_next.rd_s = id_ex_reg.rd_s;
        ex_mem_reg_next.funct3 = id_ex_reg.funct3;

        // rvfi signals
        ex_mem_reg_next.rvfi.monitor_valid = id_ex_reg.rvfi.monitor_valid;
        ex_mem_reg_next.rvfi.monitor_order = id_ex_reg.rvfi.monitor_order; 
        ex_mem_reg_next.rvfi.monitor_inst = id_ex_reg.rvfi.monitor_inst;
        ex_mem_reg_next.rvfi.monitor_rs1_addr = id_ex_reg.rvfi.monitor_rs1_addr; 
        ex_mem_reg_next.rvfi.monitor_rs2_addr = id_ex_reg.rvfi.monitor_rs2_addr;
        ex_mem_reg_next.rvfi.monitor_rs1_rdata = r1_val; 
        ex_mem_reg_next.rvfi.monitor_rs2_rdata = r2_val; 
        ex_mem_reg_next.rvfi.monitor_regf_we = id_ex_reg.rvfi.monitor_regf_we;
        ex_mem_reg_next.rvfi.monitor_rd_addr = id_ex_reg.rvfi.monitor_rd_addr;
        ex_mem_reg_next.rvfi.monitor_rd_wdata = f; 
        ex_mem_reg_next.rvfi.monitor_pc_rdata = id_ex_reg.rvfi.monitor_pc_rdata; 
        ex_mem_reg_next.rvfi.monitor_pc_wdata = ((id_ex_reg.branch & f[0])| id_ex_reg.jal | id_ex_reg.jalr) ? mispredict_pc : id_ex_reg.rvfi.monitor_pc_wdata; 

    end : fill_out_reg_next


forwarding_unit forwarding_unit_dec_1
(
    .rs1_s(id_ex_reg.rs1_s), 
    .rs2_s(id_ex_reg.rs2_s), 
    .ex_mem_writeback(write_back_mem), 
    .mem_wb_writeback(write_back_wb), 
    .ex_mem_reg_rd(rd_s_mem), 
    .mem_wb_reg_rd(rd_s_wb),
    .r1_mux_select(r1_mux_select), 
    .r2_mux_select(r2_mux_select)
);

pipeline_alu alu_dec_1(
    .aluc(id_ex_reg.alu_or_cmp),
    .aluop(id_ex_reg.alu_op),
    .a(a), 
    .b(b),
    .f(f)
);

endmodule
