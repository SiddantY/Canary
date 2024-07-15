module load_store_queue
import rv32i_types::*;
#(
    parameter   QUEUE_DEPTH =   64
)

(
    input   logic                       clk,
    input   logic                       rst,
    input   logic                       flush,
    input   ld_st_queue_t               data_in,
    input   logic                       write_enable,
    input   logic                       read_enable,
    input   logic   [NUM_REGS-1:0]             phys_valid_vector,
    input   logic   [$clog2(ROB_SIZE)-1:0]               rob_head,
    output  logic                       queue_empty,
    output  logic                       queue_full,
    output  logic [$clog2(NUM_REGS)-1:0]    pr1_s_ld_st,
    output  logic [$clog2(NUM_REGS)-1:0]    pr2_s_ld_st, 
    output  ld_st_queue_t               data_out,
    output  logic                       read_resp,

    input   logic                       valid_branch,

    input logic [$clog2(NUM_BRATS)-1:0] current_brat,
    input logic brats_full,

    input logic branch_recovery,
    input logic [$clog2(NUM_BRATS)-1:0] branch_resolved_index,
    input logic correct_bp_early
);

ld_st_queue_t data_queue [QUEUE_DEPTH]; // queue

logic [$clog2(QUEUE_DEPTH)-1:0] read_ptr; // read loc
logic [$clog2(QUEUE_DEPTH)-1:0] write_ptr; // write loc

logic [$clog2(QUEUE_DEPTH)-1:0] read_ptr_brr[NUM_BRATS];
logic [$clog2(QUEUE_DEPTH)-1:0] write_ptr_brr[NUM_BRATS];

// always_ff @(posedge clk)
//     begin
//         if(rst)
//             begin
//                 for(int j = 0; j < NUM_BRATS; j++)
//                     begin
//                         read_ptr_brr[j] <= '0;
//                         write_ptr_brr[j] <= '0;
//                     end
//             end
//         else
//             begin
//                 if(valid_branch)
//                     begin
//                         read_ptr_brr[current_brat] <= read_ptr;
//                         write_ptr_brr[current_brat] <= write_ptr;  
//                     end
//             end
//     end

int i;
always_ff @(posedge clk) begin
    if (rst || flush) begin
        // Initialize the data_queue and pointers
        for (i = 0; i < QUEUE_DEPTH; i++) begin
            data_queue[i%QUEUE_DEPTH].opcode <= '0; // can and should only have ld or st opcodes
            data_queue[i%QUEUE_DEPTH].funct3 <= '0; // 8/16/32 tings
            // bit [31:0] dmem_addr_or_rdwdata; // if ld dmem_addr, if st rd_wdata
            data_queue[i%QUEUE_DEPTH].pr1_s_ld_st <= '0;
            data_queue[i%QUEUE_DEPTH].arch_rs1 <= '0;
            
            data_queue[i%QUEUE_DEPTH].pr2_s_ld_st <= '0;
            data_queue[i%QUEUE_DEPTH].arch_rs2 <= '0;

            data_queue[i%QUEUE_DEPTH].phys_rd <= '0;
            data_queue[i%QUEUE_DEPTH].arch_rd <= '0;

            data_queue[i%QUEUE_DEPTH].rob_index <= '0;
            data_queue[i%QUEUE_DEPTH].pc <= '0;
            data_queue[i%QUEUE_DEPTH].imm <= '0;
            data_queue[i%QUEUE_DEPTH].order <= '0;
            data_queue[i%QUEUE_DEPTH].inst <= '0;
            data_queue[i%QUEUE_DEPTH].brats_full <= '0;
            data_queue[i%QUEUE_DEPTH].current_brat <= '0;
        end
        for (int j = 0; j < NUM_BRATS; j++) begin
            read_ptr_brr[j] <= '0;
            write_ptr_brr[j] <= '0;
        end
        read_ptr <= '0;
        write_ptr <= '0;
        read_resp <= '0;
    end
    else begin
        // Logic for correct branch prediction checkpointing
        if (valid_branch && branch_resolved_index < NUM_BRATS) begin
            read_ptr_brr[current_brat] <= read_ptr;
            write_ptr_brr[current_brat] <= write_ptr;
        end
        
        // Logic for branch recovery
        if (branch_recovery) begin
            for (int aa = 0; aa < QUEUE_DEPTH; aa++) begin
                if (data_queue[aa].current_brat > branch_resolved_index) begin
                    data_queue[aa].opcode <= '0; // can and should only have ld or st opcodes
                    data_queue[aa].funct3 <= '0; // 8/16/32 tings
                    // bit [31:0] dmem_addr_or_rdwdata; // if ld dmem_addr, if st rd_wdata
                    data_queue[aa].pr1_s_ld_st <= '0;
                    data_queue[aa].arch_rs1 <= '0;
                    
                    data_queue[aa].pr2_s_ld_st <= '0;
                    data_queue[aa].arch_rs2 <= '0;

                    data_queue[aa].phys_rd <= '0;
                    data_queue[aa].arch_rd <= '0;

                    data_queue[aa].rob_index <= '0;
                    data_queue[aa].pc <= '0;
                    data_queue[aa].imm <= '0;
                    data_queue[aa].order <= '0;
                    data_queue[aa].inst <= '0;
                    data_queue[aa].brats_full <= '0;
                    data_queue[aa].current_brat <= '0;
                end
            end
            if (branch_resolved_index > 0) begin
                read_ptr <= read_ptr_brr[branch_resolved_index];
                write_ptr <= write_ptr_brr[branch_resolved_index];
            end
        end

        // Read operations
        if (read_enable && !queue_empty && phys_valid_vector[data_queue[read_ptr].pr1_s_ld_st] && phys_valid_vector[data_queue[read_ptr].pr2_s_ld_st]) begin
            if (rob_head != data_queue[read_ptr].rob_index && data_queue[read_ptr].opcode == op_b_store) begin
                data_out <= 'x;
                read_resp <= 1'b0;
            end else begin
                data_out <= data_queue[read_ptr];
                read_ptr <= (read_ptr + 1) % QUEUE_DEPTH;  // Ensure wrapping around
                read_resp <= 1'b1;
                read_ptr_brr[current_brat] <= (read_ptr + 1) % QUEUE_DEPTH;
            end
        end else begin
            data_out <= 'x;
            read_resp <= 1'b0;
        end

        // Write operations
        if (write_enable && !queue_full) begin
            data_queue[write_ptr].opcode <= data_in.opcode; // can and should only have ld or st opcodes
            data_queue[write_ptr].funct3 <= data_in.funct3; // 8/16/32 tings
            data_queue[write_ptr].pr1_s_ld_st <= data_in.pr1_s_ld_st;
            data_queue[write_ptr].arch_rs1 <= data_in.arch_rs1;
            data_queue[write_ptr].pr2_s_ld_st <= data_in.pr2_s_ld_st;
            data_queue[write_ptr].arch_rs2 <= data_in.arch_rs2;
            data_queue[write_ptr].phys_rd <= data_in.phys_rd;
            data_queue[write_ptr].arch_rd <= data_in.arch_rd;
            data_queue[write_ptr].rob_index <=  data_in.rob_index;
            data_queue[write_ptr].pc <= data_in.pc;
            data_queue[write_ptr].imm <=  data_in.imm;
            data_queue[write_ptr].order <=  data_in.order;
            data_queue[write_ptr].inst <= data_in.inst;
            data_queue[write_ptr].brats_full <= brats_full;
            data_queue[write_ptr].current_brat <= current_brat;
            write_ptr <= (write_ptr + 1) % QUEUE_DEPTH;  // Ensure wrapping around
            write_ptr_brr[current_brat] <= (write_ptr + 1) % QUEUE_DEPTH;
        end
    end
end

int ls;
always_comb begin
    queue_empty = (read_ptr == write_ptr);
    queue_full = (read_ptr == (write_ptr + 1) % QUEUE_DEPTH);

    // Update valid flags
    for (ls = 0; ls < QUEUE_DEPTH; ls++) begin
        data_queue[ls].rs1_ready = phys_valid_vector[data_queue[ls].pr1_s_ld_st];
        data_queue[ls].rs2_ready = phys_valid_vector[data_queue[ls].pr2_s_ld_st];
    end

    pr1_s_ld_st = data_queue[read_ptr].pr1_s_ld_st;
    pr2_s_ld_st = data_queue[read_ptr].pr2_s_ld_st;
end



endmodule