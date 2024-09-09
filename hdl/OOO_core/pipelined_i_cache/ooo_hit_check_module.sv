module hit_check_module 
import rv32i_types::*;
(
    // input logic [31:0] ppc,
    // input logic        br_en,
    // input logic        pc_req,
    input logic [31:0] ufp_addr,
    input logic        input_valid,
    output hit_check_stage_t hit_check,

    input logic [31:0] dfp_raddr,
    input logic [255:0] dfp_rdata,

    input logic [31:0] ufp_raddr,
    input logic [255:0] ufp_rdata
);

    logic [4:0] cur_offset;
    logic [$clog2(SETS)-1:0] cur_set;
    logic [26-$clog2(SETS):0] cur_tag;

    always_comb begin

        hit_check.offset = ufp_addr[4:0];
        hit_check.set = ufp_addr[$clog2(SETS)+4:5];
        hit_check.tag = ufp_addr[31:$clog2(SETS)+5]; 
        hit_check.valid = input_valid;

        // hit_check.ppc = ppc;
        // hit_check.br_en = br_en;
        // hit_check.pc_req = pc_req;
        
        hit_check.fwd = 1'b0;
        hit_check.rdata_fwd = '0;
        if(ufp_addr[31:5] == dfp_raddr[31:5] /*&& input_valid*/) begin
            hit_check.fwd = 1'b1;
            hit_check.rdata_fwd = dfp_rdata;
        end else if(ufp_addr[31:5] == ufp_raddr[31:5] /*&& input_valid*/) begin
            hit_check.fwd = 1'b1;
            hit_check.rdata_fwd = ufp_rdata;
        end
    end

endmodule : hit_check_module