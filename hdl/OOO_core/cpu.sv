module ooo_cpu
import rv32i_types::*;
(
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input   logic               clk,
    input   logic               rst,

    output  logic               flush,
    output  logic               jump_en,
    output  logic               jalr_done,

    output  logic   [31:0]      imem_addr,
    output  logic               input_valid,
    input   logic   [31:0]      imem_rdata,
    input   logic               imem_resp,
    input   logic               imem_stall,
    input   logic   [31:0]      imem_raddr,

    output  logic   [31:0]      dmem_addr,
    output  logic   [3:0]       dmem_rmask,
    output  logic   [3:0]       dmem_wmask,
    input   logic   [31:0]      dmem_rdata,
    output  logic   [31:0]      dmem_wdata,
    input   logic               dmem_resp,

    // Single memory port connection when caches are integrated into design (CP3 and after)
    
    // output logic   [31:0]      bmem_addr,
    // output logic               bmem_read,
    // output logic               bmem_write,
    // output logic   [63:0]      bmem_wdata,
    
    // input logic               bmem_ready,
    // input logic   [31:0]      bmem_raddr,
    // input logic   [63:0]      bmem_rdata,
    // input logic               bmem_rvalid

    output  logic           amo,
    output  logic   [31:0]  address_to_lock,
    output  logic           lock
    
);

    // Making lint happy yeah
    // assign dmem_addr = '0;
    // assign dmem_wmask = '0;
    // assign dmem_rmask = '0;
    // assign dmem_wdata = '0;

    logic [63:0] instr;
    logic [31:0] pc, pc_jump, ppc_out;//, jump_pc_latch;

    logic branch_pred;

    // logic jump_en;//, jump_en_latch;
    logic jalr_en;
    // logic jalr_done;
    logic [31:0] jalr_pc;

    // logic flush;
    logic [31:0] missed_pc;

    logic [31:0] pr1_val, pr2_val, pr1_val_mul, pr2_val_mul;

    reservation_station_entry_t line_to_execute, line_to_execute_mul;
    logic request_new_instr;
    logic read_resp;

    logic execute_valid_alu, execute_valid_mul;

    logic done_mult_unit;

    data_bus_package_t execute_outputs, execute_outputs_mul;

    logic valid_commit;
    rvfi_commit_packet_t committer;


    // logic   [31:0]  imem_addr;
    logic           imem_read;
    // logic   [31:0]  imem_rdata;
    // logic           imem_resp;
    // logic   [31:0]  imem_raddr;
    // logic               input_valid;
    // logic               imem_stall;



    // logic   [31:0]  dmem_addr;
    // logic   [3:0]   dmem_rmask;
    // logic   [3:0]   dmem_wmask;
    // logic   [31:0]  dmem_rdata;
    // logic   [31:0]  dmem_wdata;
    // logic           dmem_resp;

    logic   [31:0]  dmem_raddr; // DOES NOTHING YET

    
    logic [31:0] dinst;
    logic [31:0] dpc_rdata;
    logic [31:0] dpc_wdata;

    logic bren;
    logic pc_req;

    logic [63:0] fc;

    always_ff @(posedge clk)
        begin
            if(rst) fc <= '0;
            else if (flush) fc <= fc + 1'b1;
        end

    fetch fetch(
        .clk(clk),
        .rst(rst),
        .pc_jump(pc_jump),
        .jump_en(jump_en),
        .jalr_en(jalr_en),
        .jalr_done(jalr_done),
        .jalr_pc(jalr_pc),
        .flush(flush),
        .missed_pc(missed_pc),
        .imem_rdata(imem_rdata),
        .imem_resp(imem_resp),
        .imem_addr(imem_addr),
        .imem_read(imem_read),
        .imem_raddr(imem_raddr),
        .imem_stall(imem_stall),
        .input_valid(input_valid),
        .instruction(instr),
        .pc(pc),
        .read_resp(read_resp),
        .request_new_instr(request_new_instr),
        .pc_req(pc_req)
    );

    decode decode(
        .clk(clk),
        .rst(rst),
        .instruction(instr),
        .branch_pred(1'b0),
        .jump_pc(pc_jump),
        .jump_en(jump_en),
        .jalr_en(jalr_en),
        .execute_outputs_comb(execute_outputs),
        .pr1_val(pr1_val),
        .pr2_val(pr2_val),
        .execute_valid_alu(execute_valid_alu),
        .line_to_execute(line_to_execute),
        .line_to_execute_mul(line_to_execute_mul),
        .pr1_val_mul(pr1_val_mul),
        .pr2_val_mul(pr2_val_mul),
        .execute_valid_mul(execute_valid_mul),
        .execute_outputs_mul(execute_outputs_mul),
        .flush(flush),
        .missed_pc(missed_pc),
        .request_new_instr(request_new_instr),
        .read_resp(read_resp),
        .valid_commit(valid_commit),
        .committer(committer),
        .dmem_addr(dmem_addr), // dmem stuff cuz yk load and stores
        .dmem_rmask(dmem_rmask),
        .dmem_wmask(dmem_wmask),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .dmem_resp(dmem_resp),

        .amo(amo),
        .address_to_lock(address_to_lock),
        .lock(lock)
    );

    // arbiter arbiter( // ASSERTS ADDR UNTIL DATA IS RECIEVED, 1 CACHE QUERY AT A TIME
    //     .clk(clk),
    //     .rst(rst),
    //     .flush(flush),
    //     .jump_en(jump_en),
    //     .jalr_en(jalr_done),
    //     // .br_en(bren),

    //     .imem_addr(imem_addr),
    //     .input_valid(input_valid),
    //     .imem_stall(imem_stall),
    //     .imem_rdata(imem_rdata),
    //     .imem_raddr(imem_raddr),
    //     .imem_resp(imem_resp),
    //     // .ppc(ppc),
    //     // .pc_req(pc_req),
    //     // .pc_req_out(pc_req_out),
    //     // .br_en(br_en),

    //     // .ppc_out(ppc_out),
    //     // .br_en_out(br_en_out),

    //     .dmem_addr(dmem_addr),
    //     .dmem_rmask(dmem_rmask),
    //     .dmem_wmask(dmem_wmask),
    //     .dmem_wdata(dmem_wdata),
    //     // .dmem_raddr(dmem_raddr),
    //     .dmem_rdata(dmem_rdata),
    //     .dmem_resp(dmem_resp),


    //     .bmem_addr(bmem_addr),
    //     .bmem_read(bmem_read),
    //     .bmem_write(bmem_write),
    //     .bmem_wdata(bmem_wdata),
    //     .bmem_ready(bmem_ready),

    //     .bmem_raddr(bmem_raddr),
    //     .bmem_rdata(bmem_rdata),
    //     .bmem_rvalid(bmem_rvalid)
    // );

    execute execute_dec(
        // .clk(clk),
        // .rst(rst),
        .line_to_execute(line_to_execute),
        .pr1_val(pr1_val),
        .pr2_val(pr2_val),
        .jalr_done(jalr_done),
        .jalr_pc(jalr_pc),
        //.jump_en(jump_en_latch),
        //.pc_jump(jump_pc_latch),
        .execute_valid_alu(execute_valid_alu),
        .execute_outputs(execute_outputs)
    );

    multiplication_division_unit mult_div_dec_1(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .line_to_execute_mul(line_to_execute_mul),
        .pr1_val_mul(pr1_val_mul),
        .pr2_val_mul(pr2_val_mul),
        .execute_valid_mul(execute_valid_mul),
        .execute_outputs_mul(execute_outputs_mul)
    );


    logic monitor_valid;
    logic [63:0] monitor_order;
    logic [31:0] monitor_inst;
    logic [4:0] monitor_rs1_addr;
    logic [4:0] monitor_rs2_addr;
    logic [31:0] monitor_rs1_rdata;
    logic [31:0] monitor_rs2_rdata;
    logic [4:0] monitor_rd_addr;
    logic [31:0] monitor_rd_wdata;
    logic [31:0] monitor_pc_rdata;
    logic [31:0] monitor_pc_wdata;
    logic [31:0] monitor_mem_addr;
    logic [3:0] monitor_mem_rmask;
    logic [3:0] monitor_mem_wmask;
    logic [31:0] monitor_mem_rdata;
    logic [31:0] monitor_mem_wdata;

// always_ff @(posedge clk)
//     begin
//         if(rst)
//             begin
//                 jump_pc_latch <= '0;
//                 jump_en_latch <= '0;
//             end
//         else
//             if(jump_en)
//                 begin
//                     jump_en_latch <= jump_en;
//                     jump_pc_latch <= pc_jump;
//                 end
//             else
//                 begin
//                     jump_en_latch <= 1'b0;
//                     jump_pc_latch <= '0;
//                 end
//     end

always_comb
    begin
        if(rst)
            begin
                monitor_valid = '0;
                monitor_order = '0;
                monitor_inst = '0;
                monitor_rs1_addr = '0;
                monitor_rs2_addr = '0;
                monitor_rs1_rdata = '0;
                monitor_rs2_rdata = '0;
                monitor_rd_addr = '0;
                monitor_rd_wdata = '0;
                monitor_pc_rdata = '0;
                monitor_pc_wdata = '0;
                monitor_mem_addr = '0;
                monitor_mem_rmask = '0;
                monitor_mem_wmask = '0;
                monitor_mem_rdata = '0;
                monitor_mem_wdata = '0;
            end
        else
            begin
                monitor_valid = valid_commit == 1'b0 ? 1'b0 : 1'b1;
                monitor_order = committer.order;
                monitor_inst = committer.inst;
                monitor_rs1_addr = committer.rs1_addr;
                monitor_rs2_addr = committer.rs2_addr;
                monitor_rs1_rdata = committer.rs1_rdata;
                monitor_rs2_rdata = committer.rs2_rdata;
                monitor_rd_addr = committer.rd_addr;
                monitor_rd_wdata = committer.rd_wdata;
                monitor_pc_rdata = committer.pc_rdata;
                monitor_pc_wdata = committer.pc_wdata;
                monitor_mem_addr = committer.mem_addr;
                monitor_mem_rmask = committer.mem_rmask;
                monitor_mem_wmask = committer.mem_wmask;
                monitor_mem_rdata = committer.mem_rdata;
                monitor_mem_wdata = committer.mem_wdata;
            end
    end



endmodule : ooo_cpu