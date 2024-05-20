module forwarding_unit
import rv32i_types::*;
(
    input logic     [4:0]   rs1_s, rs2_s,
    input logic             ex_mem_writeback, mem_wb_writeback,
    input logic     [4:0]   ex_mem_reg_rd, mem_wb_reg_rd,
    output logic    [1:0]   r1_mux_select, r2_mux_select
);

always_comb
    begin
        r1_mux_select = 2'b00;
        r2_mux_select = 2'b00;

        if(ex_mem_writeback
        && (ex_mem_reg_rd == rs1_s)
        && (ex_mem_reg_rd != 0))
            begin
                r1_mux_select = 2'b10;
            end
        
        if(mem_wb_writeback 
        && (mem_wb_reg_rd != 0) 
        && !(ex_mem_writeback && (ex_mem_reg_rd != 0)
            && (ex_mem_reg_rd == rs1_s))
        && (mem_wb_reg_rd == rs1_s))
            begin
                r1_mux_select = 2'b01;
            end
        
        if(ex_mem_writeback
        && (ex_mem_reg_rd == rs2_s)
        && (ex_mem_reg_rd != 0))
            begin
                r2_mux_select = 2'b10;
            end
        
        if(mem_wb_writeback 
        && (mem_wb_reg_rd != 0) 
        && !(ex_mem_writeback && (ex_mem_reg_rd != 0)
            && (ex_mem_reg_rd == rs2_s))
        && (mem_wb_reg_rd == rs2_s))
            begin
                r2_mux_select = 2'b01;
            end
    end

endmodule