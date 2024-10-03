module address_unit
import rv32i_types::*;
(
    input logic clk,
    input logic rst,

    input instr_t renamed_instruction,
    input [63:0] instruction,
    input logic valid_instruction,
    input logic [$clog2(ROB_SIZE)-1:0] rob_index,

    output logic [$clog2(NUM_REGS)-1:0] pr1_s_ldst,
    input logic [31:0] pr1_val_ldst,

    output logic [$clog2(NUM_REGS)-1:0] pr2_s_ldst,
    input logic [31:0] pr2_val_ldst,
    output data_bus_package_t execute_outputs_ldst,

    input logic [NUM_REGS-1:0] phys_valid_vector,
    input logic [$clog2(ROB_SIZE)-1:0] rob_head,

    output  logic   [31:0]  dmem_addr, // dmem stuff cuz yk load and stores
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp,

    // bookkeeping extras
    input logic [63:0] order,
    output ld_st_queue_t ld_st_queue_data_out_latch,
    
    //flush
    input logic flush,


    output  logic           amo,
    output  logic   [31:0]  address_to_lock,
    output  logic           lock
);

ld_st_queue_t ld_st_queue_data_in;
ld_st_queue_t ld_st_queue_data_out;

// ld_st_queue_t ld_st_queue_data_out_latch;

logic [31:0] pr1_val_ldst_latch;
logic [31:0] pr2_val_ldst_latch;

logic [31:0] dmem_addr_latch, dmem_wdata_latch;
logic [3:0] dmem_rmask_latch, dmem_wmask_latch;

logic mem_ready, mem_ready_ac;
logic ld_st_q_read_resp;
logic ld_st_q_full;
logic ld_st_q_empty;

logic [31:0] dmem_addr_full;
logic latcgh_regs;

logic [31:0] dmem_sum;
logic dmem_cout;

// Atomic VARS

logic amo_mem_read, amo_mem_write, amo_done;
logic [31:0] amo_data_out, dmem_rdata_latch, dmem_st_sig;

assign amo = (ld_st_queue_data_out_latch.amo);

always_ff @(posedge clk) begin

    if(rst) begin
        dmem_rdata_latch <= '0;
    end else begin
        if(dmem_resp && dmem_rmask_latch != '0 && dmem_wmask_latch == '0) begin
            dmem_rdata_latch <= dmem_rdata;
        end
    end

end

always_ff @(posedge clk) begin

    if(rst) begin
        dmem_st_sig <= '0;
    end else begin
        if(dmem_resp && dmem_wmask_latch != '0 && amo) begin
            dmem_st_sig <= dmem_rdata;
        end
    end

end

always_ff @(posedge clk)
    begin
        if(rst | flush)
            begin
                if(rst | dmem_resp) begin
                    mem_ready <= 1'b1;
                end else if(ld_st_q_read_resp) begin
                    mem_ready <= 1'b0;
                end
                ld_st_queue_data_out_latch <= '0;
                dmem_wdata_latch <= '0;
                dmem_addr_latch <= '0;
                dmem_wdata_latch <= '0;
                dmem_rmask_latch <= '0;
                dmem_wmask_latch <= '0;
                pr1_val_ldst_latch <= '0;
                pr2_val_ldst_latch <= '0;
            end
        else
            begin
                if(dmem_resp && ld_st_queue_data_out_latch.amo != 1'b1)
                    begin
                        mem_ready <= 1'b1;
                        ld_st_queue_data_out_latch <= 'x;
                    end
                else if(amo_done && ld_st_queue_data_out_latch.amo == 1'b1) begin
                    mem_ready <= 1'b1;
                    ld_st_queue_data_out_latch <= 'x;
                end
                
                if(ld_st_q_read_resp) begin
                        mem_ready <= /*(~mem_ready && dmem_resp) ? 1'b1 :*/ 1'b0;
                        ld_st_queue_data_out_latch <= ld_st_queue_data_out;
                        dmem_addr_latch <= dmem_addr_full;
                        dmem_wdata_latch <= dmem_wdata;
                        dmem_rmask_latch <= ld_st_queue_data_out.opcode == op_b_atom ? '0 : dmem_rmask;
                        dmem_wmask_latch <= ld_st_queue_data_out.opcode == op_b_atom ? '0 : dmem_wmask;
                        pr1_val_ldst_latch <= pr1_val_ldst;
                        pr2_val_ldst_latch <= pr2_val_ldst;
                    end
                    
                else if (amo_mem_read) begin

                    dmem_rmask_latch <= '1;
                    dmem_addr_latch <= pr1_val_ldst_latch;

                end else if (amo_mem_write) begin

                    dmem_wmask_latch <= '1;
                    dmem_addr_latch <= pr1_val_ldst_latch;
                    dmem_wdata_latch <= amo_data_out;

                end
            end
    end



always_comb begin : memReadyStuff
    
    mem_ready_ac = mem_ready;
    if (ld_st_q_read_resp) begin
        mem_ready_ac = '0;
    end
    
end

always_comb
    begin
        /*
            Setting up data in
        */
        ld_st_queue_data_in.opcode = instruction[6:0];
        ld_st_queue_data_in.funct3 = instruction[6:0] == op_b_load ? renamed_instruction.i_type.funct3 : renamed_instruction.s_type.funct3;
        
        ld_st_queue_data_in.pr1_s_ld_st = instruction[19:15] == 5'd0 ? 6'd0 : (renamed_instruction.i_type.opcode == op_b_store) ? renamed_instruction.s_type.rs1 : renamed_instruction.i_type.rs1;
        ld_st_queue_data_in.rs1_ready = phys_valid_vector[ld_st_queue_data_in.pr1_s_ld_st];
        ld_st_queue_data_in.arch_rs1 = instruction[19:15];
        
        ld_st_queue_data_in.pr2_s_ld_st = instruction[6:0] == op_b_load ? 6'b0 : (instruction[6:0] == op_b_atom) ? renamed_instruction.a_type.rs2 : renamed_instruction.s_type.rs2;
        ld_st_queue_data_in.rs2_ready = phys_valid_vector[ld_st_queue_data_in.pr2_s_ld_st];
        ld_st_queue_data_in.arch_rs2 = instruction[6:0] == op_b_load ? 5'b0 : instruction[24:20];
        

        ld_st_queue_data_in.phys_rd = instruction[6:0] == op_b_load ? renamed_instruction.i_type.rd : instruction[6:0] == op_b_atom ? renamed_instruction.a_type.rd : 6'b0;
        ld_st_queue_data_in.arch_rd = instruction[6:0] == op_b_load || instruction[6:0] == op_b_atom ? instruction[11:7] : 5'b0;
        
        ld_st_queue_data_in.rob_index = rob_index;
        ld_st_queue_data_in.pc = instruction[63:32];
        ld_st_queue_data_in.imm = instruction[6:0] == op_b_load ? {{21{instruction[31]}}, instruction[30:20]} : {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
        ld_st_queue_data_in.order = order;
        ld_st_queue_data_in.inst = instruction[31:0];
        
        // amo 
        ld_st_queue_data_in.amo = instruction[6:0] == op_b_atom ? 1'b1 : 1'b0;
        ld_st_queue_data_in.funct7 = renamed_instruction.a_type.funct7;

        dmem_addr = '0;
        dmem_rmask = '0;
        dmem_wmask = '0;
        dmem_wdata = '0;
        // pr1_s_ldst = '0;
        // pr2_s_ldst = '0;
        dmem_addr_full = '0;
        if(ld_st_queue_data_out.opcode == op_b_store)
            begin
                //set pr1_s_ld_st + pr2_s_ld_st
                // pr1_s_ldst = ld_st_queue_data_out.pr1_s_ld_st;
                // pr2_s_ldst = ld_st_queue_data_out.pr2_s_ld_st;

                dmem_addr_full = dmem_sum;
                dmem_addr = {dmem_sum[31:2], 2'b00};
                dmem_rmask = '0;
                
                unique case(ld_st_queue_data_out.funct3)
                    sb: dmem_wmask = 4'b0001 << dmem_addr_full[1:0];
                    sh: dmem_wmask = 4'b0011 << dmem_addr_full[1:0];
                    sw: dmem_wmask = 4'b1111;
                    default: dmem_wmask = '0;
                endcase

                unique case (ld_st_queue_data_out.funct3)
                    sb: dmem_wdata[8 *dmem_addr_full[1:0] +: 8 ] = pr2_val_ldst[7 :0];
                    sh: dmem_wdata[16*dmem_addr_full[1]   +: 16] = pr2_val_ldst[15:0];
                    sw: dmem_wdata = pr2_val_ldst;
                    default: dmem_wdata = '0;
                endcase

            end
        else if(ld_st_queue_data_out.opcode == op_b_load)
            begin
                //set pr1_s_ld_st + pr2_s_ld_st
                // pr1_s_ldst = ld_st_queue_data_out.pr1_s_ld_st;
                // pr2_s_ldst = ld_st_queue_data_out.pr2_s_ld_st;

                dmem_addr_full = dmem_sum;
                dmem_addr = {dmem_sum[31:2], 2'b00};
                unique case(ld_st_queue_data_out.funct3)
                    lb, lbu: dmem_rmask = 4'b0001 << dmem_addr_full[1:0];
                    lh, lhu: dmem_rmask = 4'b0011 << dmem_addr_full[1:0];
                    lw:      dmem_rmask = 4'b1111;
                    default: dmem_rmask = '0;  
                endcase
                
                dmem_wmask = '0;

                dmem_wdata = '0;
            end 
        else if (ld_st_queue_data_out_latch.amo == 1'b1 && amo_mem_read) 
            begin
                dmem_addr = pr1_val_ldst_latch;
                dmem_rmask = 4'hF;
            end
        else if (ld_st_queue_data_out_latch.amo == 1'b1 && amo_mem_write) 
            begin
                dmem_addr = pr1_val_ldst_latch;
                dmem_wmask = 4'hF;
                dmem_wdata = amo_data_out;
            end
        
        
        execute_outputs_ldst.phys_rd = ld_st_queue_data_out_latch.phys_rd; // rd matching
        if(ld_st_queue_data_out_latch.opcode == op_b_load)
            begin
                unique case (ld_st_queue_data_out_latch.funct3)
                    lb : execute_outputs_ldst.phys_rd_val = {{24{dmem_rdata[7 +8 *dmem_addr_latch[1:0]]}}, dmem_rdata[8 *dmem_addr_latch[1:0] +: 8 ]};
                    lbu: execute_outputs_ldst.phys_rd_val = {{24{1'b0}}                          , dmem_rdata[8 *dmem_addr_latch[1:0] +: 8 ]};
                    lh : execute_outputs_ldst.phys_rd_val = {{16{dmem_rdata[15+16*dmem_addr_latch[1]  ]}}, dmem_rdata[16*dmem_addr_latch[1]   +: 16]};
                    lhu: execute_outputs_ldst.phys_rd_val = {{16{1'b0}}                          , dmem_rdata[16*dmem_addr_latch[1]   +: 16]};
                    lw : execute_outputs_ldst.phys_rd_val = dmem_rdata;
                    default: execute_outputs_ldst.phys_rd_val = 'x;
                endcase
            end
        else if(ld_st_queue_data_out_latch.opcode == op_b_atom && ld_st_queue_data_out_latch.funct7[6:2] == 5'b00011)
            begin
                execute_outputs_ldst.phys_rd_val = dmem_st_sig;
            end
        else if(ld_st_queue_data_out_latch.opcode == op_b_atom && ld_st_queue_data_out_latch.funct7[6:2] == 5'b00010) begin
                execute_outputs_ldst.phys_rd_val = dmem_rdata_latch; 
        end else if(ld_st_queue_data_out_latch.opcode == op_b_atom) begin
            execute_outputs_ldst.phys_rd_val = dmem_rdata_latch;
        end
        else
            begin
                execute_outputs_ldst.phys_rd_val = '0;
            end
                
        
        execute_outputs_ldst.rob_index = ld_st_queue_data_out_latch.rob_index;
        execute_outputs_ldst.regf_we = (ld_st_queue_data_out_latch.opcode == op_b_load && dmem_resp || ld_st_queue_data_out_latch.opcode == op_b_atom && amo_done) ? 1'b1 : 1'b0;

        // if a load and store not a valid thing to update the rat, prf, rob. 0 is ld/st, 1 is alu/cmp
        execute_outputs_ldst.alu_or_cmp_op = 1'b0;
        execute_outputs_ldst.execute_valid = (dmem_resp && ld_st_queue_data_out_latch.inst != '0 && ld_st_queue_data_out_latch.amo != 1'b1) || (amo_done && ld_st_queue_data_out_latch.amo == 1'b1);
        execute_outputs_ldst.arch_rd = ld_st_queue_data_out_latch.arch_rd;
        
        // rvfi
        execute_outputs_ldst.rvfi.valid = 1'b0;
        execute_outputs_ldst.rvfi.order = ld_st_queue_data_out_latch.order;
        execute_outputs_ldst.rvfi.inst = ld_st_queue_data_out_latch.inst;
        execute_outputs_ldst.rvfi.rs1_addr = ld_st_queue_data_out_latch.arch_rs1;
        execute_outputs_ldst.rvfi.rs2_addr = ld_st_queue_data_out_latch.arch_rs2;
        execute_outputs_ldst.rvfi.rs1_rdata = pr1_val_ldst_latch;
        execute_outputs_ldst.rvfi.rs2_rdata = pr2_val_ldst_latch;
        execute_outputs_ldst.rvfi.rd_addr = ld_st_queue_data_out_latch.arch_rd;

        execute_outputs_ldst.rvfi.rd_wdata = (ld_st_queue_data_out_latch.opcode == op_b_load || ld_st_queue_data_out_latch.opcode == op_b_atom) ? execute_outputs_ldst.phys_rd_val : '0;
        execute_outputs_ldst.rvfi.pc_rdata = ld_st_queue_data_out_latch.pc;
        execute_outputs_ldst.rvfi.pc_wdata = ld_st_queue_data_out_latch.pc + 32'h4;
        execute_outputs_ldst.rvfi.mem_addr = {dmem_addr_latch[31:2], 2'b00};
        execute_outputs_ldst.rvfi.mem_rmask = dmem_rmask_latch;
        execute_outputs_ldst.rvfi.mem_wmask = dmem_wmask_latch;
        execute_outputs_ldst.rvfi.mem_rdata = (ld_st_queue_data_out_latch.opcode == op_b_atom) ? dmem_rdata_latch : dmem_rdata;
        execute_outputs_ldst.rvfi.mem_wdata = dmem_wdata_latch;
end


load_store_queue 
#(
    .QUEUE_DEPTH(LD_ST_QUEUE_DEPTH)
)
load_store_queue_dec_1
(
    .clk(clk),
    .rst(rst),
    .flush(flush),
    .rob_head(rob_head),
    .data_in(ld_st_queue_data_in),
    .write_enable(valid_instruction && ~flush),
    .read_enable(mem_ready_ac && ~flush),
    .phys_valid_vector(phys_valid_vector),
    .queue_empty(ld_st_q_empty),
    .queue_full(ld_st_q_full),
    .pr1_s_ld_st(pr1_s_ldst),
    .pr2_s_ld_st(pr2_s_ldst),
    .data_out(ld_st_queue_data_out),
    .read_resp(ld_st_q_read_resp)
);

carry_look_ahead_adder jalr_addr(
    .sum(dmem_sum),
    .cout(dmem_cout),
	.a(pr1_val_ldst),
    .b(ld_st_queue_data_out.imm),
    .cin(1'b0)
);

ooo_amo_unit amo_unit_ooo (

    .clk(clk),                 
    .rst(rst),                 
    .amo_valid(ld_st_queue_data_out_latch.amo),
    .mem_data_in(dmem_rdata),                                   // Data read from memory
    .amo_operand(pr2_val_ldst_latch),                                             // Operand for AMO operation -- This is rs2_value
    .amo_funct(ld_st_queue_data_out_latch.funct7),              // AMO function code (e.g., ADD, AND, OR, XOR)

    .mem_resp(dmem_resp),

    .mem_data_out(amo_data_out),                                // Data to write to memory
    .amo_done(amo_done),                                        // Flag indicating AMO completion
    .mem_read(amo_mem_read),                                    // Control signal for memory read
    .mem_write(amo_mem_write),                                  // Control signal for memory write
    .locked_address(address_to_lock),
    .lock(lock),
    .address_to_lock(dmem_addr_latch)
);

endmodule