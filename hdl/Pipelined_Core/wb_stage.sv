module wb_stage
import rv32i_types::*;
(
    input   mem_wb_reg_t        mem_wb_reg,
    output  logic   [31:0]      rd_v
);

always_comb
    begin : writeback_mux
        
        unique case(mem_wb_reg.mem_read)
            1'b0: rd_v = mem_wb_reg.rd_v;
            1'b1: rd_v = mem_wb_reg.read_data;
            default rd_v = 'x;
        endcase

    end : writeback_mux


endmodule