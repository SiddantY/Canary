module mem_stage
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    input   ex_mem_reg_t        ex_mem_reg,

    input   logic   [31:0]      dmem_rdata,
    input   logic               dmem_resp,

    output  logic   [3:0]       dmem_rmask,
    output  logic   [3:0]       dmem_wmask,
    output  logic   [31:0]      dmem_addr,
    output  logic   [31:0]      dmem_wdata,

    output  logic               dstall,
    output  mem_wb_reg_t        mem_wb_reg_next
);

logic p2o; // (prevent_twice_occurance) this is used so that magic mem doesn't respond twice 1 address due to keeping the address up
always_ff @(posedge clk)
    begin : d_no_rep

        if(rst)
            begin
                p2o <= 1'b0;
            end
        else
            begin

                if((ex_mem_reg.mem_read | ex_mem_reg.mem_write) && ex_mem_reg.rvfi.monitor_valid) // load instruction stall til response
                    begin
                        p2o <= 1'b1;
                    end
                
                if(dmem_resp) // response set stall to low
                    begin
                        p2o <= 1'b0;
                    end
                
            end
    end : d_no_rep

always_latch
    begin : dstall_logic

        if(rst)
            begin
                dstall = 1'b0;
            end
        else
            begin

                if((ex_mem_reg.mem_read | ex_mem_reg.mem_write) && ex_mem_reg.rvfi.monitor_valid) // load instruction stall til response
                    begin
                        dstall = 1'b1;
                    end
                
                if(dmem_resp) // response set stall to low
                    begin
                        dstall = 1'b0;
                    end
                
            end
    end : dstall_logic

logic [1:0] slide; // used for mask setting, bottom 2 bits of dmem_addr

logic [31:0] dmem_addr_holder;
logic [3:0] dmem_rmask_holder;
logic [3:0] dmem_wmask_holder;
logic [31:0] dmem_wdata_holder;

always_comb
    begin : address_unit
        // addr holder
        dmem_addr_holder = {ex_mem_reg.alu_result[31:2], 2'b00};
        slide = ex_mem_reg.alu_result[1:0];

        //mem_read_mask mux
        if(ex_mem_reg.mem_read)
            begin
                unique case(ex_mem_reg.funct3)
                    lb, lbu: dmem_rmask_holder = 4'b0001 << slide;
                    lh, lhu: dmem_rmask_holder = 4'b0011 << slide;
                    lw:      dmem_rmask_holder = 4'b1111;
                    default: dmem_rmask_holder = '0;  
                endcase
            end
        else
            begin
                dmem_rmask_holder = '0;
            end

        
        dmem_wdata_holder = '0;
        if(ex_mem_reg.mem_write)
            begin
                //mem_write_mask mux
                unique case(ex_mem_reg.funct3)
                    sb: dmem_wmask_holder = 4'b0001 << slide;
                    sh: dmem_wmask_holder = 4'b0011 << slide;
                    sw: dmem_wmask_holder = 4'b1111;
                    default: dmem_wmask_holder = '0;
                endcase

                //mem_wdata mux
                unique case (ex_mem_reg.funct3)
                    sb: dmem_wdata_holder[8 *ex_mem_reg.alu_result[1:0] +: 8 ] = ex_mem_reg.rs2_v[7 :0];
                    sh: dmem_wdata_holder[16*ex_mem_reg.alu_result[1]   +: 16] = ex_mem_reg.rs2_v[15:0];
                    sw: dmem_wdata_holder = ex_mem_reg.rs2_v;
                    default: dmem_wdata_holder = '0;
                endcase
            end
        else
            begin
                dmem_wmask_holder = '0;
            end

        dmem_addr = '0;
        dmem_rmask = '0;
        dmem_wmask = '0;
        dmem_wdata = '0;

        if(ex_mem_reg.mem_read /*&& ~p2o */&& ex_mem_reg.rvfi.monitor_valid) // load
            begin
                dmem_addr = dmem_addr_holder;
                dmem_rmask = dmem_rmask_holder;

                // dmem_wmask and dmem_wdata stays '0 since load

            end
        
        if(ex_mem_reg.mem_write /*&& ~p2o*/ && ex_mem_reg.rvfi.monitor_valid) // store
            begin
                
                dmem_addr = dmem_addr_holder;

                // dmem_rmask stays '0 since store

                dmem_wmask = dmem_wmask_holder;
                dmem_wdata = dmem_wdata_holder;

            end
        
    end : address_unit

always_comb
    begin : dmem_rdata_capture

        unique case (ex_mem_reg.funct3)
            lb : mem_wb_reg_next.read_data = {{24{dmem_rdata[7 +8 *ex_mem_reg.alu_result[1:0]]}}, dmem_rdata[8 *ex_mem_reg.alu_result[1:0] +: 8 ]};
            lbu: mem_wb_reg_next.read_data = {{24{1'b0}}                          , dmem_rdata[8 *ex_mem_reg.alu_result[1:0] +: 8 ]};
            lh : mem_wb_reg_next.read_data = {{16{dmem_rdata[15+16*ex_mem_reg.alu_result[1]  ]}}, dmem_rdata[16*ex_mem_reg.alu_result[1]   +: 16]};
            lhu: mem_wb_reg_next.read_data = {{16{1'b0}}                          , dmem_rdata[16*ex_mem_reg.alu_result[1]   +: 16]};
            lw : mem_wb_reg_next.read_data = dmem_rdata;
            default: mem_wb_reg_next.read_data = 'x;
        endcase

    end : dmem_rdata_capture

always_comb
    begin : next_reg_setting

        mem_wb_reg_next.rd_v = ex_mem_reg.alu_result;
        mem_wb_reg_next.rd_s = ex_mem_reg.rd_s;
        mem_wb_reg_next.regf_we = ex_mem_reg.regf_we;
        mem_wb_reg_next.mem_read = ex_mem_reg.mem_read;

        // rvfi signals
        mem_wb_reg_next.rvfi.monitor_valid = ex_mem_reg.rvfi.monitor_valid && !dstall;
        mem_wb_reg_next.rvfi.monitor_order = ex_mem_reg.rvfi.monitor_order; 
        mem_wb_reg_next.rvfi.monitor_inst = ex_mem_reg.rvfi.monitor_inst;
        mem_wb_reg_next.rvfi.monitor_rs1_addr = ex_mem_reg.rvfi.monitor_rs1_addr; 
        mem_wb_reg_next.rvfi.monitor_rs2_addr = ex_mem_reg.rvfi.monitor_rs2_addr;
        mem_wb_reg_next.rvfi.monitor_rs1_rdata = ex_mem_reg.rvfi.monitor_rs1_rdata; 
        mem_wb_reg_next.rvfi.monitor_rs2_rdata = ex_mem_reg.rvfi.monitor_rs2_rdata; 
        mem_wb_reg_next.rvfi.monitor_regf_we = ex_mem_reg.rvfi.monitor_regf_we;
        mem_wb_reg_next.rvfi.monitor_rd_addr = ex_mem_reg.rvfi.monitor_rd_addr;
        mem_wb_reg_next.rvfi.monitor_rd_wdata = ex_mem_reg.mem_read ? mem_wb_reg_next.read_data : ex_mem_reg.rvfi.monitor_rd_wdata; 
        mem_wb_reg_next.rvfi.monitor_pc_rdata = ex_mem_reg.rvfi.monitor_pc_rdata; 
        mem_wb_reg_next.rvfi.monitor_pc_wdata = ex_mem_reg.rvfi.monitor_pc_wdata; 
        mem_wb_reg_next.rvfi.monitor_mem_addr = ((ex_mem_reg.mem_read | ex_mem_reg.mem_write) && ex_mem_reg.rvfi.monitor_valid) ? dmem_addr_holder : '0;
        mem_wb_reg_next.rvfi.monitor_mem_rmask = (ex_mem_reg.mem_read  && ex_mem_reg.rvfi.monitor_valid) ? dmem_rmask_holder : '0;
        mem_wb_reg_next.rvfi.monitor_mem_wmask = (ex_mem_reg.mem_write  && ex_mem_reg.rvfi.monitor_valid) ? dmem_wmask_holder : '0;
        mem_wb_reg_next.rvfi.monitor_mem_rdata = dmem_rdata;
        mem_wb_reg_next.rvfi.monitor_mem_wdata = (ex_mem_reg.mem_write  && ex_mem_reg.rvfi.monitor_valid) ? dmem_wdata_holder : '0;
        
    end : next_reg_setting


endmodule