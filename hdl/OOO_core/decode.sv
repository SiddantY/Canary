/*
NEED TO ADD MORE PORTS TO RAT + ROB
*/
module decode
import rv32i_types::*;
#(
    parameter DEC_STATION_DEPTH = 16,
    parameter DEC_ROB_SIZE = 16,
    parameter NUM_REGS = 64,
    parameter LDST_QUEUE_DEPTH = 16
)
(
    input logic clk,
    input logic rst,
    input logic [63:0] instruction,
    input data_bus_package_t execute_outputs_comb, // this comes from execute and shit need to update rat + prf + rob, with this

    input logic branch_pred,

    output logic [31:0] pr1_val,
    output logic [31:0] pr2_val,
    output reservation_station_entry_t line_to_execute,
    output logic execute_valid_alu,

    output reservation_station_entry_t line_to_execute_mul,
    output logic [31:0] pr1_val_mul,
    output logic [31:0] pr2_val_mul,
    output logic execute_valid_mul,

    input data_bus_package_t execute_outputs_mul,

    output logic request_new_instr,
    input logic read_resp,

    output logic valid_commit,
    output rvfi_commit_packet_t committer,

    //unconditional branch stuff
    output logic jump_en,
    output logic [31:0] jump_pc,
    output logic jalr_en,

    //br stuff
    output logic flush,
    output logic [31:0] missed_pc,

    //dmem signals for address unit
    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp,

    output  logic           amo,
    output  logic   [31:0]  address_to_lock,
    output  logic           lock
);
/*
Bookkeeping
*/
logic [63:0] order;


/*
RENAME VARS
*/
logic [$clog2(NUM_REGS)-1:0] physical_rd, physical_rs1, physical_rs2; // These are the physical reg translations
logic [4:0] arch_rd, arch_rs1, arch_rs2; // These are the arch rega, needed for ROB ?

logic [37:0] renamed_instruction; // output of renaming unit

/* 
FREE LIST VARS 
*/
// logic need_free_reg; // high when a valid instruction is passed through - !!! REPLACED BY READ RESP SIG

logic reg_freed; // high when an instruction is commited and the reg is no longer needed
logic [$clog2(NUM_REGS)-1:0] liberated_reg; // freed register need to be passed to rat to update

logic reg_available; // high when there are no free regs

/*
RAT VARS
*/
// logic update_mapping; // drive high when a free reg is needed and a valid instructions comes through - !!! REPLACED BY READ RESP SIG
//logic [2:0] alu_rs_valid_vector[32];
logic res_station_full, res_station_full_mul;
// logic rs1_valid_rat_output_alu, rs2_valid_rat_output_alu; // These used by reservations station to decide when valid instructions
// logic [4:0] rs1_valid_index_alu, rs2_valid_index_alu; // used to index the rat to check for valid tings


/* 
RESERVATION STATION -- ALU VARS 
*/
reservation_station_entry_t reservation_station_alu[DEC_STATION_DEPTH]; // reserivation station data
logic ready_alu[DEC_STATION_DEPTH]; // ready data
logic [$clog2(DEC_STATION_DEPTH)-1:0] finished_idx, la, finished_idx_comb;
logic remove_entry;


/*
RESERVATION STATION -- MUL VARS
*/
reservation_station_entry_t reservation_station_mul[DEC_STATION_DEPTH]; // reserivation station data
logic ready_mul[DEC_STATION_DEPTH]; // ready data
logic [$clog2(DEC_STATION_DEPTH)-1:0] finished_idx_mul;
logic remove_entry_mul;


logic rs1_valid_rat_output_ldst, rs2_valid_rat_output_ldst; // These used by reservations station to decide when valid instructions
logic [4:0] rs1_valid_index_ldst, rs2_valid_index_ldst; // used to index the rat to check for valid tings

reservation_station_entry_t lte;




/*
ROB VARS
*/
logic rob_empty; // This tells us if the rob is empty, useless ?
logic rob_full; // This tells us if the rob if full, prevent pc from incrementing when this is high
logic [$clog2(DEC_ROB_SIZE)-1:0] instruction_to_rob_index; // This is the outputted rob index for the instruction
rob_entry_t rob_line_to_commit; // This is the line to send to rrf, also some rvfi stuff needs to come from here

reservation_station_entry_t line_to_execute_mul_comb;
reservation_station_entry_t line_to_execute_comb;

logic stall_preempt;

logic [NUM_REGS-1:0] phys_valid_vector;


/*
RRF VARS
*/
logic [$clog2(NUM_REGS)-1:0] rrf_arch_to_physical[32];

/*
ADDRESS UNIT VARS
*/
logic [$clog2(NUM_REGS)-1:0] pr1_s_ldst, pr2_s_ldst;
logic [31:0] pr1_val_ldst, pr2_val_ldst;

data_bus_package_t execute_outputs_ldst;
ld_st_queue_t ld_st_queue_data_out_latch;

data_bus_package_t execute_outputs;

logic flush_comb;

always_ff @(posedge clk)
    begin
        if(rst || flush || flush_comb)
            begin
                execute_outputs <= '0;
            end
        else
            begin
                execute_outputs <= execute_outputs_comb;
            end
    end


always_comb begin : INSTR_ACCEPT_LOGIC
    if(reg_available && !res_station_full && !(rob_full || stall_preempt) && ~flush) begin // CHECK IF FREE LIST + RES STATION ARE RDY TO ACCEPT NEW INSTR
        request_new_instr = 1'b1;
    end else begin
        request_new_instr = 1'b0;
    end
end

always_comb 
    begin : UNCONDITIONAL_JUMPS
        if(instruction[6:0] == op_b_jal && read_resp && ~flush)
            begin
                jump_en = 1'b1;
                jump_pc = instruction[63:32] + {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end
        else
            begin
                jump_en = 1'b0;
                jump_pc = '0;
            end
        
        if(instruction[6:0] == op_b_jalr && read_resp && ~flush)
            begin
                jalr_en = 1'b1;
            end
        else
            begin
                jalr_en = 1'b0;
            end
    end


rename rename_dec(
    .instruction(instruction[31:0]),
    .physical_rd(physical_rd),
    .physical_rs1(physical_rs1),
    .physical_rs2(physical_rs2),
    .arch_rd(arch_rd),
    .arch_rs1(arch_rs1),
    .arch_rs2(arch_rs2),
    .renamed_instruction(renamed_instruction)
);

free_list free_list_dec(
    .clk(clk),
    .rst(rst),
    .flush(flush),
    .need_free_reg(read_resp && (arch_rd != '0)),
    .reg_freed(reg_freed),
    .liberated_reg(liberated_reg), // comes from rrf
    .free_reg(physical_rd),
    .phys_reg_valid(phys_valid_vector),
    .rrf_arch_to_physical(rrf_arch_to_physical),
    .arch_rd(arch_rd),
    .reg_available(reg_available)
);

rat rat_dec(
    .clk(clk),
    .rst(rst),
    .arch_rs1(arch_rs1),
    .arch_rs2(arch_rs2),
    .update_mapping(read_resp),
    .arch_reg_to_update(arch_rd),
    .phys_reg_update(physical_rd),
    .phys_reg_valid_update(execute_outputs.phys_rd),
    .phys_reg_valid_update_mul(execute_outputs_mul.phys_rd),

    // Prolly gonna have to comb since 2 reservation stations but since no ld/st ignore for now !!!!!
    .update_valid(execute_outputs.regf_we),  // either from free list output or cdb,
    .arch_reg_valid_update(execute_outputs.arch_rd), // need the arch reg to say valido this comes from cdb 
    
    .update_valid_mul(execute_outputs_mul.regf_we),  // either from free list output or cdb,
    .arch_reg_valid_update_mul(execute_outputs_mul.arch_rd), // need the arch reg to say valido this comes from cdb 

    .update_valid_ldst(execute_outputs_ldst.regf_we),
    .arch_reg_valid_update_ldst(execute_outputs_ldst.arch_rd),
    .phys_reg_valid_update_ldst(execute_outputs_ldst.phys_rd),
   
    //output  logic   [4:0]   physical_rd, // probablty dont need this keep for now 3/13
    .physical_rs1(physical_rs1),
    .physical_rs2(physical_rs2),

    //.valid_vec(alu_rs_valid_vector),
    .phys_valid_vector(phys_valid_vector),
    .flush(flush),
    .rrf_arch_to_physical(rrf_arch_to_physical)
);

reservation_station #(
    .STATION_DEPTH(DEC_STATION_DEPTH),
    .ROB_SIZE(DEC_ROB_SIZE)
)
reservation_station_alu_dec1
(
    .clk(clk),
    .rst(rst),
    .renamed_instruction(renamed_instruction),
    .valid_intruction(~flush && read_resp && !(instruction[6:0] == op_b_reg && instruction[31:25] == 7'b0000001) && !(instruction[6:0] == op_b_store || instruction[6:0] == op_b_load)), // comes from fetch fifo, set valid insutrctopm if NOT load or store
    .flush(flush),
    .rob_index(instruction_to_rob_index), // LOL ROB !!!!!
    .branch_pred(branch_pred),
    .arch_rd(arch_rd),
    .arch_rs1(arch_rs1),
    .arch_rs2(arch_rs2),
    .reservation_station(reservation_station_alu),
    .ready(ready_alu),
    //.valid_src_vec(alu_rs_valid_vector),
    .finished_idx(finished_idx), // needed to remove items
    .remove_entry(remove_entry),
    .pc(instruction[63:32]),
    .inst(instruction[31:0]),
    .full(res_station_full),
    .update_valids(1'b1),
    .order(order),
    .phys_valid_vector(phys_valid_vector)
);

reservation_station #(
    .STATION_DEPTH(DEC_STATION_DEPTH),
    .ROB_SIZE(DEC_ROB_SIZE)
)
reservation_station_mul_dec1
(
    .clk(clk),
    .rst(rst),
    .renamed_instruction(renamed_instruction),
    .valid_intruction(read_resp && ((instruction[6:0] == op_b_reg && instruction[31:25] == 7'b0000001))), // comes from fetch fifo, set valid insutrctopm if NOT load or store
    .flush(flush),
    .rob_index(instruction_to_rob_index), // LOL ROB !!!!!
    .branch_pred(branch_pred),
    .arch_rd(arch_rd),
    .arch_rs1(arch_rs1),
    .arch_rs2(arch_rs2),
    .reservation_station(reservation_station_mul),
    .ready(ready_mul),
    //.valid_src_vec(alu_rs_valid_vector),
    .finished_idx(finished_idx_mul), // needed to remove items
    .remove_entry(remove_entry_mul),
    .pc(instruction[63:32]),
    .inst(instruction[31:0]),
    .full(res_station_full_mul),
    .update_valids(1'b1),
    .order(order),
    .phys_valid_vector(phys_valid_vector)
);

logic [3:0] commit_ptr;


// TODO ROB goes here
rob #(
    .ROB_SIZE(ROB_SIZE)
)
rob_dec_1
(
    .clk(clk),
    .rst(rst),
    .instruction(instruction),
    .flush(flush),
    .missed_pc(missed_pc),
    .commit_ptr(commit_ptr),
    .flush_comb(flush_comb),

    .valid_intruction_index(execute_outputs.rob_index), // This comes from cbd/execture
    .valid_intruction_index_mul(execute_outputs_mul.rob_index),
    .valid_intruction_index_ldst(execute_outputs_ldst.rob_index),

    // input logic update_rob_valid, // This comes from cdb/execute
    .update_rob_valid(execute_outputs.execute_valid & execute_outputs.regf_we & ~flush), // TODO: FILL OUT FROM EXECUTE
    .update_rob_valid_mul(execute_outputs_mul.execute_valid & execute_outputs_mul.regf_we), // TODO: FILL OUT FROM EXECUTE
    .update_rob_valid_ldst(execute_outputs_ldst.execute_valid& ~flush /*& execute_outputs_ldst.regf_we*/),
    .insert_into_rob(read_resp),

    .phys_rd(physical_rd),
    .arch_rd(arch_rd),
    .execute_outputs(execute_outputs),
    .execute_outputs_mul(execute_outputs_mul),
    .execute_outputs_ldst(execute_outputs_ldst),
    .rob_empty(rob_empty),
    .rob_full(rob_full),
    .instruction_to_rob_index(instruction_to_rob_index),
    .rob_line_to_commit(rob_line_to_commit),
    .valid_commit(valid_commit),
    .committer(committer),
    .stall_preempt(stall_preempt)
);

// // TODO since ROB here RRF goes here
rrf rrf_dec(
    .clk(clk),
    .rst(rst),
    .rob_instruction_to_commit(rob_line_to_commit),
    .update_mapping(valid_commit),// this needs to come from the rob, when an instruction is committed
    .liberated_phys_reg(liberated_reg), // goes to free list
    .reg_freed(reg_freed), // goes to free list
    .rrf_arch_to_physical(rrf_arch_to_physical)
);

physical_regfile physical_regfile_dec
(
    .clk(clk),
    .rst(rst),
    .regf_we(execute_outputs.regf_we), // comes from execute
    .regf_we_mul(execute_outputs_mul.execute_valid), // comes from mul/div unit
    .regf_we_ldst(execute_outputs_ldst.execute_valid), // comes from address unit
    
    .rd_v(execute_outputs.phys_rd_val), // comes from execute, !!! comb this since multiple write busses maybe queue
    .rs1_s(lte.phys_rs1),
    .rs2_s(lte.phys_rs2),
    .rd_s(execute_outputs.phys_rd), // comes from execute, !!! comb this since multiple write busses maybe queue
    .rs1_v(pr1_val),
    .rs2_v(pr2_val),

    .rd_v_mul(execute_outputs_mul.phys_rd_val), // comes from execute, !!! comb this since multiple write busses maybe queue
    .rs1_s_mul(line_to_execute_mul.phys_rs1),
    .rs2_s_mul(line_to_execute_mul.phys_rs2),
    .rd_s_mul(execute_outputs_mul.phys_rd), // comes from execute, !!! comb this since multiple write busses maybe queue
    .rs1_v_mul(pr1_val_mul),
    .rs2_v_mul(pr2_val_mul),

    .rd_v_ldst(execute_outputs_ldst.phys_rd_val), // comes from execute, !!! comb this since multiple write busses maybe queue
    .rs1_s_ldst(pr1_s_ldst),
    .rs2_s_ldst(pr2_s_ldst),
    .rd_s_ldst(execute_outputs_ldst.phys_rd), // comes from execute, !!! comb this since multiple write busses maybe queue
    .rs1_v_ldst(pr1_val_ldst),
    .rs2_v_ldst(pr2_val_ldst)
);

address_unit address_unit_dec1(
    .clk(clk),
    .rst(rst),
    .flush(flush),

    .rob_head(commit_ptr),

    .renamed_instruction(renamed_instruction), // decode
    .instruction(instruction),
    .valid_instruction(read_resp && (instruction[6:0] == op_b_load || instruction[6:0] == op_b_store  || instruction[6:0] == op_b_atom)),
    .rob_index(instruction_to_rob_index), // decode

    .pr1_s_ldst(pr1_s_ldst), // output
    .pr1_val_ldst(pr1_val_ldst), // decode

    .pr2_s_ldst(pr2_s_ldst), // output
    .pr2_val_ldst(pr2_val_ldst), // decode
    .execute_outputs_ldst(execute_outputs_ldst),

    .phys_valid_vector(phys_valid_vector), // decode

    .dmem_addr(dmem_addr), // dmem stuff cuz yk load and stores
    .dmem_rmask(dmem_rmask),
    .dmem_wmask(dmem_wmask),
    .dmem_rdata(dmem_rdata),
    .dmem_wdata(dmem_wdata),
    .dmem_resp(dmem_resp),

    // bookkeeping extras
    .order(order), // decode 
    .ld_st_queue_data_out_latch(ld_st_queue_data_out_latch),

    .amo(amo),
    .address_to_lock(address_to_lock),
    .lock(lock)
);

logic [2:0] index_to_execute;
logic [63:0] min_order;

logic mul_busy;
logic execute_valid_mul_c;

logic execute_valid_alu_comb, evalte;

always_ff @(posedge clk)
    begin
        if(rst || flush)
            begin
                //line_to_execute <= '0;
                //execute_valid_alu <= 1'b0;
                order <= flush == 1'b1 ? committer.order + 1'b1: '0;
                mul_busy <= 1'b0;
                
                line_to_execute <= '0;
                lte <= '0;
                execute_valid_alu <= '0;
                evalte <= '0;

                execute_valid_mul <= 1'b0;
                line_to_execute_mul <= 'x;

            end
        else
            begin
                if(read_resp)
                    begin
                        order <= order + 1'b1;
                    end
                
                execute_valid_mul <= 1'b0;

                if(~mul_busy && execute_valid_mul_c && execute_outputs_mul.execute_valid != 1'b1)
                    begin
                        line_to_execute_mul <= line_to_execute_mul_comb;
                        mul_busy <= 1'b1;
                        execute_valid_mul <= 1'b1;
                    end
                else if(~mul_busy && ~execute_valid_mul_c)
                    begin
                        line_to_execute_mul <= 'x;
                    end
                
                if(mul_busy && execute_outputs_mul.execute_valid)
                    begin
                        mul_busy <= 1'b0;
                    end
                
                line_to_execute <= lte;
                execute_valid_alu <= evalte;

                lte <= line_to_execute_comb;
                evalte <= execute_valid_alu_comb;
            end
    end

// int index_iter_for_alu_execution;
// always_comb
//     begin
//         min_order = 64'h7FFFFFFFFFFFFFFF;
//         index_to_execute = '0;
//         for(index_iter_for_alu_execution = 0; index_iter_for_alu_execution < 8; index_iter_for_alu_execution++)
//             begin
//                 if(ready_alu[index_iter_for_alu_execution] && reservation_station_alu[index_iter_for_alu_execution].order < min_order)
//                     begin
//                         min_order = reservation_station_alu[index_iter_for_alu_execution].order;
//                         index_to_execute = index_iter_for_alu_execution[2:0];
//                     end
//             end
        
//          if(index_to_execute == 3'b0) begin
//             line_to_execute = reservation_station_alu[0];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd0;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd1) begin
//             line_to_execute = reservation_station_alu[1];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd1;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd2) begin
//             line_to_execute = reservation_station_alu[2];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd2;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd3) begin
//             line_to_execute = reservation_station_alu[3];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd3;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd4) begin
//             line_to_execute = reservation_station_alu[4];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd4;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd5) begin
//             line_to_execute = reservation_station_alu[5];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd5;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd6) begin
//             line_to_execute = reservation_station_alu[6];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd6;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd7) begin
//             line_to_execute = reservation_station_alu[7];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd7;
//             remove_entry = 1'b1;
//         end else begin
//             line_to_execute = '0;
//             execute_valid_alu = 1'b0;
//             finished_idx = '0;
//             remove_entry = 1'b0;
//         end
//     end
    
always_comb 
    begin : ALU_TYPE_SHI
        // if(ready_alu[7]) begin
        //     line_to_execute_comb = reservation_station_alu[7];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd7;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[6]) begin
        //     line_to_execute_comb = reservation_station_alu[6];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd6;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[5]) begin
        //     line_to_execute_comb = reservation_station_alu[5];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd5;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[4]) begin
        //     line_to_execute_comb = reservation_station_alu[4];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd4;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[3]) begin
        //     line_to_execute_comb = reservation_station_alu[3];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd3;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[2]) begin
        //     line_to_execute_comb = reservation_station_alu[2];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd2;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[1]) begin
        //     line_to_execute_comb = reservation_station_alu[1];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd1;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[0]) begin
        //     line_to_execute_comb = reservation_station_alu[0];
        //     execute_valid_alu_comb = 1'b1;
        //     finished_idx = 3'd0;
        //     remove_entry = 1'b1;
        // end else begin
        //     line_to_execute_comb = '0;
        //     execute_valid_alu_comb = 1'b0;
        //     finished_idx = '0;
        //     remove_entry = 1'b0;
        // end
        // if(ready_alu[15]) begin
        //     line_to_execute = reservation_station_alu[15];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd15;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[14]) begin
        //     line_to_execute = reservation_station_alu[14];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd14;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[13]) begin
        //     line_to_execute = reservation_station_alu[13];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd13;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[12]) begin
        //     line_to_execute = reservation_station_alu[12];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd12;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[11]) begin
        //     line_to_execute = reservation_station_alu[11];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd11;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[10]) begin
        //     line_to_execute = reservation_station_alu[10];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd10;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[9]) begin
        //     line_to_execute = reservation_station_alu[9];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd9;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[8]) begin
        //     line_to_execute = reservation_station_alu[8];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd8;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[7]) begin
        //     line_to_execute = reservation_station_alu[7];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd7;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[6]) begin
        //     line_to_execute = reservation_station_alu[6];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd6;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[5]) begin
        //     line_to_execute = reservation_station_alu[5];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd5;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[4]) begin
        //     line_to_execute = reservation_station_alu[4];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd4;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[3]) begin
        //     line_to_execute = reservation_station_alu[3];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd3;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[2]) begin
        //     line_to_execute = reservation_station_alu[2];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd2;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[1]) begin
        //     line_to_execute = reservation_station_alu[1];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd1;
        //     remove_entry = 1'b1;
        // end else if(ready_alu[0]) begin
        //     line_to_execute = reservation_station_alu[0];
        //     execute_valid_alu = 1'b1;
        //     finished_idx = 4'd0;
        //     remove_entry = 1'b1;
        // end else begin
        //     line_to_execute = '0;
        //     execute_valid_alu = 1'b0;
        //     finished_idx = '0;
        //     remove_entry = 1'b0;
        // end

        if(ready_alu[15]) begin
            line_to_execute_comb = reservation_station_alu[15];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd15;
            remove_entry = 1'b1;
        end else if(ready_alu[14]) begin
            line_to_execute_comb = reservation_station_alu[14];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd14;
            remove_entry = 1'b1;
        end else if(ready_alu[13]) begin
            line_to_execute_comb = reservation_station_alu[13];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd13;
            remove_entry = 1'b1;
        end else if(ready_alu[12]) begin
            line_to_execute_comb = reservation_station_alu[12];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd12;
            remove_entry = 1'b1;
        end else if(ready_alu[11]) begin
            line_to_execute_comb = reservation_station_alu[11];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd11;
            remove_entry = 1'b1;
        end else if(ready_alu[10]) begin
            line_to_execute_comb = reservation_station_alu[10];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd10;
            remove_entry = 1'b1;
        end else if(ready_alu[9]) begin
            line_to_execute_comb = reservation_station_alu[9];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd9;
            remove_entry = 1'b1;
        end else if(ready_alu[8]) begin
            line_to_execute_comb = reservation_station_alu[8];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd8;
            remove_entry = 1'b1;
        end else if(ready_alu[7]) begin
            line_to_execute_comb = reservation_station_alu[7];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd7;
            remove_entry = 1'b1;
        end else if(ready_alu[6]) begin
            line_to_execute_comb = reservation_station_alu[6];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd6;
            remove_entry = 1'b1;
        end else if(ready_alu[5]) begin
            line_to_execute_comb = reservation_station_alu[5];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd5;
            remove_entry = 1'b1;
        end else if(ready_alu[4]) begin
            line_to_execute_comb = reservation_station_alu[4];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd4;
            remove_entry = 1'b1;
        end else if(ready_alu[3]) begin
            line_to_execute_comb = reservation_station_alu[3];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd3;
            remove_entry = 1'b1;
        end else if(ready_alu[2]) begin
            line_to_execute_comb = reservation_station_alu[2];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd2;
            remove_entry = 1'b1;
        end else if(ready_alu[1]) begin
            line_to_execute_comb = reservation_station_alu[1];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd1;
            remove_entry = 1'b1;
        end else if(ready_alu[0]) begin
            line_to_execute_comb = reservation_station_alu[0];
            execute_valid_alu_comb = 1'b1;
            finished_idx = 4'd0;
            remove_entry = 1'b1;
        end else begin
            line_to_execute_comb = '0;
            execute_valid_alu_comb = 1'b0;
            finished_idx = '0;
            remove_entry = 1'b0;
        end
    end : ALU_TYPE_SHI

always_comb 
    begin : MUL_TYPE_SHI
        if(ready_mul[15]) begin
            line_to_execute_mul_comb = reservation_station_mul[15];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd15;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[14]) begin
            line_to_execute_mul_comb = reservation_station_mul[14];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd14;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[13]) begin
            line_to_execute_mul_comb = reservation_station_mul[13];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd13;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[12]) begin
            line_to_execute_mul_comb = reservation_station_mul[12];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd12;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[11]) begin
            line_to_execute_mul_comb = reservation_station_mul[11];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd11;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[10]) begin
            line_to_execute_mul_comb = reservation_station_mul[10];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd10;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[9]) begin
            line_to_execute_mul_comb = reservation_station_mul[9];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd9;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[8]) begin
            line_to_execute_mul_comb = reservation_station_mul[8];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd8;
            remove_entry_mul = 1'b1;
        end else if(ready_mul[7]) begin
            line_to_execute_mul_comb = reservation_station_mul[7];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd7;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else if(ready_mul[6]) begin
            line_to_execute_mul_comb = reservation_station_mul[6];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd6;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else if(ready_mul[5]) begin
            line_to_execute_mul_comb = reservation_station_mul[5];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd5;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else if(ready_mul[4]) begin
            line_to_execute_mul_comb = reservation_station_mul[4];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd4;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else if(ready_mul[3]) begin
            line_to_execute_mul_comb = reservation_station_mul[3];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd3;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else if(ready_mul[2]) begin
            line_to_execute_mul_comb = reservation_station_mul[2];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd2;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else if(ready_mul[1]) begin
            line_to_execute_mul_comb = reservation_station_mul[1];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd1;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else if(ready_mul[0]) begin
            line_to_execute_mul_comb = reservation_station_mul[0];
            execute_valid_mul_c = 1'b1;
            finished_idx_mul = 4'd0;
            remove_entry_mul = mul_busy ? 1'b0 : 1'b1;
        end else begin
            line_to_execute_mul_comb = '0;
            execute_valid_mul_c = 1'b0;
            finished_idx_mul = '0;
            remove_entry_mul = 1'b0;
        end
    end : MUL_TYPE_SHI

endmodule

//shit was lowkey genius, too bad timing dicks itself
// int index_iter_for_alu_execution;
// always_comb
//     begin
//         min_order = 64'h7FFFFFFFFFFFFFFF;
//         index_to_execute = '0;
//         for(index_iter_for_alu_execution = 0; index_iter_for_alu_execution < 8; index_iter_for_alu_execution++)
//             begin
//                 if(ready_alu[index_iter_for_alu_execution] && reservation_station_alu[index_iter_for_alu_execution].order < min_order)
//                     begin
//                         min_order = reservation_station_alu[index_iter_for_alu_execution].order;
//                         index_to_execute = index_iter_for_alu_execution[2:0];
//                     end
//             end
        
//          if(index_to_execute == 3'b0) begin
//             line_to_execute = reservation_station_alu[0];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd0;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd1) begin
//             line_to_execute = reservation_station_alu[1];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd1;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd2) begin
//             line_to_execute = reservation_station_alu[2];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd2;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd3) begin
//             line_to_execute = reservation_station_alu[3];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd3;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd4) begin
//             line_to_execute = reservation_station_alu[4];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd4;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd5) begin
//             line_to_execute = reservation_station_alu[5];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd5;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd6) begin
//             line_to_execute = reservation_station_alu[6];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd6;
//             remove_entry = 1'b1;
//         end else if(index_to_execute == 3'd7) begin
//             line_to_execute = reservation_station_alu[7];
//             execute_valid_alu = 1'b1;
//             finished_idx = 3'd7;
//             remove_entry = 1'b1;
//         end else begin
//             line_to_execute = '0;
//             execute_valid_alu = 1'b0;
//             finished_idx = '0;
//             remove_entry = 1'b0;
//         end
//     end