module pipeline_cpu
import rv32i_types::*;
(
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input   logic           clk,
    input   logic           rst,

    // output  logic   [31:0]  imem_addr,
    // output  logic   [3:0]   imem_rmask,
    // input   logic   [31:0]  imem_rdata,
    // input   logic           imem_resp,

    // output  logic   [31:0]  dmem_addr,
    // output  logic   [3:0]   dmem_rmask,
    // output  logic   [3:0]   dmem_wmask,
    // input   logic   [31:0]  dmem_rdata,
    // output  logic   [31:0]  dmem_wdata,
    // input   logic           dmem_resp

    // Single memory port connection when caches are integrated into design (CP3 and after)
    
    output logic   [31:0]      bmem_addr,
    output logic               bmem_read,
    output logic               bmem_write,
    output logic   [63:0]      bmem_wdata,
    input logic               bmem_ready,

    input logic   [31:0]      bmem_raddr,
    input logic   [63:0]      bmem_rdata,
    input logic               bmem_rvalid
    
);

logic [63:0] order;

logic istall;
logic dstall;

logic   [31:0]  imem_addr;
logic   [3:0]   imem_rmask;
logic   [31:0]  imem_rdata;
logic           imem_resp;
logic   [31:0]  dmem_addr;
logic   [3:0]   dmem_rmask;
logic   [3:0]   dmem_wmask;
logic   [31:0]  dmem_rdata;
logic   [31:0]  dmem_wdata;
logic           dmem_resp;
// make dmem_happy_for_now
// assign dmem_addr = '0;
// assign dmem_rmask = '0;
// assign dmem_wmask = '0;
// assign dmem_wdata = '0;

// Pipeline register declarations:
if_id_reg_t if_id_reg_next, if_id_reg;
id_ex_reg_t id_ex_reg_next, id_ex_reg;
ex_mem_reg_t ex_mem_reg_next, ex_mem_reg;
mem_wb_reg_t mem_wb_reg_next, mem_wb_reg;

// rd_v
logic [31:0] rd_v;

logic br_en;
logic [31:0] mispredict_pc;

// rvfi signals
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


logic got_dmem_resp;

always_ff @(posedge clk) begin

    if (rst) got_dmem_resp <= 1'b0;

    else if (dmem_resp) begin
        got_dmem_resp <= 1'b1;
    end

    else if (~dstall && ~istall) got_dmem_resp <= 1'b0;

end 

always_ff @(posedge clk) // reworks according to monitor_valid @TODO
    begin : order_control_block
        
        if(rst)
            begin
                order <= '0;
            end
        else
            begin
                if(mem_wb_reg.rvfi.monitor_valid && ~dstall && ~istall)
                    begin
                        order <= order + 1'b1;
                    end
            end

    end : order_control_block

always_ff @(posedge clk)
    begin : pipeline_register_control
        
        if(rst)
            begin
                if_id_reg <= '0;
                id_ex_reg <= '0;
                ex_mem_reg <= '0;
                mem_wb_reg <= '0;
            end
        else
            begin
                if(istall | dstall) // or dstall
                    begin
                        if_id_reg <= br_en ? '0 : if_id_reg;
                        id_ex_reg <= id_ex_reg;
                        ex_mem_reg <= ex_mem_reg;
                        mem_wb_reg <= mem_wb_reg;
                    end
                else
                    begin
                        if_id_reg <= br_en ? '0 : if_id_reg_next;
                        id_ex_reg <= br_en ? '0 : id_ex_reg_next;
                        ex_mem_reg <= ex_mem_reg_next;
                        mem_wb_reg <= mem_wb_reg_next;
                    end
            end
    
    end : pipeline_register_control

logic [31:0] ld_forward_val;

always_comb
    begin : ld_to_prev_area_saving_mux

        unique case (ex_mem_reg.funct3)
            lb : ld_forward_val = {{24{dmem_rdata[7 +8 *ex_mem_reg.alu_result[1:0]]}}, dmem_rdata[8 *ex_mem_reg.alu_result[1:0] +: 8 ]};
            lbu: ld_forward_val = {{24{1'b0}}                          , dmem_rdata[8 *ex_mem_reg.alu_result[1:0] +: 8 ]};
            lh : ld_forward_val = {{16{dmem_rdata[15+16*ex_mem_reg.alu_result[1]  ]}}, dmem_rdata[16*ex_mem_reg.alu_result[1]   +: 16]};
            lhu: ld_forward_val = {{16{1'b0}}                          , dmem_rdata[16*ex_mem_reg.alu_result[1]   +: 16]};
            lw : ld_forward_val = dmem_rdata;
            default: ld_forward_val = 'x;
        endcase

    end : ld_to_prev_area_saving_mux

if_stage if_stage_dec_1(
    .clk(clk),
    .rst(rst),

    .imem_addr(imem_addr),
    .imem_rmask(imem_rmask),
    .imem_resp(imem_resp),
    .imem_rdata(imem_rdata),

    .mispredict_br_en(br_en), // ouput from execute stage @TODO
    .mispredict_pc(mispredict_pc),

    .order(order),

    .istall(istall),
    .dstall(dstall),

    .if_id_reg_next(if_id_reg_next)
);

id_stage id_stage_dec_1 // could split fetch into interface with imem and receive resp stages
(
    .clk(clk),
    .rst(rst),

    .inst(if_id_reg.rvfi.monitor_inst), // imem_rdata
    .if_id_reg(if_id_reg),

    .valid_write(monitor_valid),

    .regf_we(mem_wb_reg.regf_we), // All 3 from writeback stage
    .rd_s(mem_wb_reg.rd_s),
    .rd_v(rd_v),

    .id_ex_reg_next(id_ex_reg_next)
);

ex_stage ex_stage_dec_1 // ex stage could be split into 2 where muxes and alu split by a register
(
    .id_ex_reg(id_ex_reg),

    .ex_mem_reg_next(ex_mem_reg_next),

    .dstall(dstall),

    .mem_read_next(ex_mem_reg.mem_read),
    .ld_forward_val(ld_forward_val),

    .rd_v_wb(rd_v), // output of wb_mux
    .rd_s_wb(mem_wb_reg.rd_s),
    .write_back_wb(mem_wb_reg.regf_we & mem_wb_reg.rvfi.monitor_valid), // from writeback

    .rd_v_mem(ex_mem_reg.alu_result), // if load dmem_rdata ? 
    .rd_s_mem(ex_mem_reg.rd_s),
    .write_back_mem(ex_mem_reg.regf_we & ex_mem_reg.rvfi.monitor_valid), // from mem

    .br_en(br_en),
    .mispredict_pc(mispredict_pc)
);

mem_stage mem_stage_dec_1
(
    .clk(clk),
    .rst(rst),

    .ex_mem_reg(ex_mem_reg),

    .dmem_rdata(dmem_rdata), // could bring the mux out to save area
    .dmem_resp(dmem_resp),
    .got_dmem_resp,

    .dmem_rmask(dmem_rmask),
    .dmem_wmask(dmem_wmask),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),

    .dstall(dstall),
    .mem_wb_reg_next(mem_wb_reg_next)
);

wb_stage wb_stage_dec_1
(
    .mem_wb_reg(mem_wb_reg),
    .rd_v(rd_v)
);

cache_unit cache_unit (.*);

always_comb
    begin : rvfi_signals
        
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
                monitor_valid = mem_wb_reg.rvfi.monitor_valid && ~dstall && ~istall;
                monitor_order = order;
                monitor_inst = mem_wb_reg.rvfi.monitor_inst;
                monitor_rs1_addr = mem_wb_reg.rvfi.monitor_rs1_addr;
                monitor_rs2_addr = mem_wb_reg.rvfi.monitor_rs2_addr;
                monitor_rs1_rdata = mem_wb_reg.rvfi.monitor_rs1_rdata;
                monitor_rs2_rdata = mem_wb_reg.rvfi.monitor_rs2_rdata;
                monitor_rd_addr = mem_wb_reg.rvfi.monitor_rd_addr;
                monitor_rd_wdata = mem_wb_reg.rvfi.monitor_rd_wdata;
                monitor_pc_rdata = mem_wb_reg.rvfi.monitor_pc_rdata;
                monitor_pc_wdata = mem_wb_reg.rvfi.monitor_pc_wdata;
                monitor_mem_addr = mem_wb_reg.rvfi.monitor_mem_addr;
                monitor_mem_rmask = mem_wb_reg.rvfi.monitor_mem_rmask;
                monitor_mem_wmask = mem_wb_reg.rvfi.monitor_mem_wmask;
                monitor_mem_rdata = mem_wb_reg.rvfi.monitor_mem_rdata;
                monitor_mem_wdata = mem_wb_reg.rvfi.monitor_mem_wdata;
            end

    end : rvfi_signals
endmodule : pipeline_cpu
