module execute
import rv32i_types::*;
(
    input reservation_station_entry_t line_to_execute,
    input logic [31:0] pr1_val,// pc_jump,
    input logic [31:0] pr2_val,
    input logic execute_valid_alu,
    //input logic jump_en,
    output logic jalr_done,
    output logic [31:0] jalr_pc,
    output data_bus_package_t execute_outputs,
    output logic branch_recovery,
    output logic [$clog2(NUM_BRATS)-1:0] branch_resolved_index,
    output logic [31:0] brr_pc,
    output logic [$clog2(ROB_SIZE)-1:0] br_issue_ptr,

    output logic [63:0] order_ind,

    output logic correct_bp_early
);

logic [31:0] a, b; // alu inputs
logic [31:0] f; // alu outputs

logic [2:0] aluop; // alu operand based on opcode + funct3

logic [31:0] jalr_sum;
logic jalr_cout;

logic [31:0] jal_sum;
logic jal_cout;

logic [31:0] br_sum;
logic br_cout;

always_comb
    begin
        // this decides whether to use 0, pc or rs1 val based on opcode
        // unique case(line_to_execute.opcode)
        //     op_b_lui: a = (pr1_val & 32'b0);
        //     op_b_auipc: a = line_to_execute.pc;// need to figure out how to get the pc
        //     op_b_jal: a = line_to_execute.pc;// need to figure out how to get the pc
        //     op_b_jalr: a = line_to_execute.pc;// need to figure out how to get the pc
        //     op_b_br: a = pr1_val;
        //     op_b_load: a = pr1_val;
        //     op_b_store: a = pr1_val;
        //     op_b_imm: a = pr1_val;
        //     op_b_reg: a = pr1_val;
        //     default: a = '0;
        // endcase

        if(line_to_execute.opcode == op_b_reg || line_to_execute.opcode == op_b_imm || line_to_execute.opcode == op_b_store || line_to_execute.opcode == op_b_load || line_to_execute.opcode == op_b_br)
            begin
                a = pr1_val;
            end
        else if(line_to_execute.opcode == op_b_jalr || line_to_execute.opcode == op_b_jal || line_to_execute.opcode == op_b_auipc)
            begin
                a = line_to_execute.pc;
            end
        else if(line_to_execute.opcode == op_b_lui)
            begin
                a = 32'h0;
            end
        else
            begin
                a = 'x;
            end
    
        // this decides whether to use rs2 val or sexted imm
        if(line_to_execute.opcode == op_b_reg || line_to_execute.opcode == op_b_store || line_to_execute.opcode == op_b_br)
            begin
                b = pr2_val;
            end
        else if(line_to_execute.opcode == op_b_jalr)
            begin
                b = 32'h4;
            end
        else
            begin
                b = line_to_execute.imm;
            end
        
        // alu op decider
        unique case(line_to_execute.opcode)
            op_b_lui: begin
                aluop = alu_add;
            end
            op_b_auipc: begin
                aluop = alu_add;
            end
            op_b_jal: begin
                aluop = alu_add;
            end
            op_b_jalr: begin
                aluop = alu_add;
            end
            op_b_br: begin
                aluop = line_to_execute.funct3;
            end
            op_b_load: begin
                aluop = alu_add;
            end
            op_b_store: begin
                aluop = alu_add;
            end
            op_b_imm: begin
                    unique case (line_to_execute.funct3)
                        slt: begin
                            aluop = blt;
                        end
                        sltu: begin
                            aluop = bltu;
                        end
                        sr: begin
                            if (line_to_execute.funct7[5]) begin
                                aluop = alu_sra;
                            end else begin
                                aluop = alu_srl;
                            end
                        end
                        default: begin
                            aluop = line_to_execute.funct3;
                        end
                    endcase
                end
            op_b_reg: begin
                    unique case (line_to_execute.funct3)
                        slt: begin
                            aluop = blt;
                        end
                        sltu: begin
                            aluop = bltu;
                        end
                        sr: begin
                            if (line_to_execute.funct7[5]) begin
                                aluop = alu_sra;
                            end else begin
                                aluop = alu_srl;
                            end
                        end
                        add: begin
                            if (line_to_execute.funct7[5]) begin
                                aluop = alu_sub;
                            end else begin
                                aluop = alu_add;
                            end
                        end
                        default: begin
                            aluop = line_to_execute.funct3;
                        end
                    endcase
                end
            default: begin
                aluop = '0;
            end
        endcase

        execute_outputs.current_brat = line_to_execute.current_brat;
        //Setting up the package to go back to the decode stuff now
        execute_outputs.phys_rd = line_to_execute.phys_rd; // rd matching
        execute_outputs.phys_rd_val = f; // alu out to f. FUCK LOADS AND STORES :(
        execute_outputs.rob_index = line_to_execute.rob_index;
        execute_outputs.regf_we = line_to_execute.regf_we;
        // if a load and store not a valid thing to update the rat, prf, rob. 0 is ld/st, 1 is alu/cmp
        execute_outputs.alu_or_cmp_op = (line_to_execute.opcode == op_b_store || line_to_execute.opcode == op_b_load) ? 1'b0 : 1'b1;
        execute_outputs.execute_valid = execute_valid_alu;
        execute_outputs.arch_rd = line_to_execute.arch_rd;
        execute_outputs.branch_mismatch = (line_to_execute.opcode == op_b_br && line_to_execute.branch_pred != f[0] && line_to_execute.brats_full) ? 1'b1 : 1'b0;
        // rvfi
        execute_outputs.rvfi.valid = 1'b0;
        execute_outputs.rvfi.order = line_to_execute.order;
        execute_outputs.rvfi.inst = line_to_execute.inst;
        execute_outputs.rvfi.rs1_addr = line_to_execute.arch_rs1;
        execute_outputs.rvfi.rs2_addr = line_to_execute.arch_rs2;
        execute_outputs.rvfi.rs1_rdata = pr1_val;
        execute_outputs.rvfi.rs2_rdata = pr2_val;
        execute_outputs.rvfi.rd_addr = line_to_execute.arch_rd;
        execute_outputs.rvfi.rd_wdata = f;
        execute_outputs.rvfi.pc_rdata = line_to_execute.pc;
        
        jalr_pc = '0;
        jalr_done = '0;
        branch_recovery = '0;
        brr_pc = '0;
        branch_resolved_index = '0;
        br_issue_ptr = '0;
        correct_bp_early = 1'b0;
        if(line_to_execute.inst[6:0] == op_b_jalr)
            begin
                execute_outputs.rvfi.pc_wdata = (jalr_sum & 32'hFFFFFFFE);
                jalr_pc = (jalr_sum & 32'hFFFFFFFE);
                jalr_done = 1'b1 & execute_valid_alu;
            end
        else if(line_to_execute.inst[6:0] == op_b_jal)
            begin
                execute_outputs.rvfi.pc_wdata = jal_sum;
            end
        else if(line_to_execute.inst[6:0] == op_b_br && f[0])
            begin
                execute_outputs.rvfi.pc_wdata = br_sum;
                branch_recovery = line_to_execute.brats_full ? 1'b0 : 1'b1;
                branch_resolved_index = line_to_execute.current_brat;
                brr_pc = br_sum;
                br_issue_ptr = line_to_execute.rob_index;
            end
        else if(line_to_execute.inst[6:0] == op_b_br && ~f[0])
            begin
                execute_outputs.rvfi.pc_wdata = line_to_execute.pc + 32'h4;
                branch_resolved_index = line_to_execute.current_brat;
                correct_bp_early = 1'b1;
            end
        else
            begin
                execute_outputs.rvfi.pc_wdata = line_to_execute.pc + 32'h4;
            end
        execute_outputs.rvfi.mem_addr = '0;
        execute_outputs.rvfi.mem_rmask = '0;
        execute_outputs.rvfi.mem_wmask = '0;
        execute_outputs.rvfi.mem_rdata = '0;
        execute_outputs.rvfi.mem_wdata = '0;

        order_ind = execute_outputs.rvfi.order;

    end


alu alu_dec_1
(
    .aluc(line_to_execute.aluc),
    .aluop(aluop), // do some comb shit to pull this in
    .a(a), // mux decides a
    .b(b), // mux decides b
    .f(f) // output f
);

carry_look_ahead_adder jalr_addr(
    .sum(jalr_sum),
    .cout(jalr_cout),
	.a(pr1_val),
    .b(line_to_execute.imm),
    .cin(1'b0)
);

carry_look_ahead_adder jal_adder(
    .sum(jal_sum),
    .cout(jal_cout),
	.a({{12{line_to_execute.inst[31]}}, line_to_execute.inst[19:12], line_to_execute.inst[20], line_to_execute.inst[30:21], 1'b0}),
    .b(line_to_execute.pc),
    .cin(1'b0)
);

carry_look_ahead_adder br_addr(
    .sum(br_sum),
    .cout(br_cout),
	.a(line_to_execute.pc),
    .b(line_to_execute.imm),
    .cin(1'b0)
);

endmodule