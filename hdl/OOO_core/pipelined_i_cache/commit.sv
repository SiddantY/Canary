module commit
import rv32i_types::*;
#(
    parameter SETS = 16
)
(
    input allocate_stage_t allocate,
    input logic read_stall,

    output logic [255:0] data_in,
    output logic write_en,
    output logic [26-$clog2(SETS):0] tag_in,
    output logic [$clog2(SETS)-1:0] write_set
    

);

    always_comb begin
        // update cache
        data_in = allocate.rdata;
        tag_in = allocate.tag;
        write_set = allocate.set;
        write_en = 1'b0;
        if(!allocate.cache_hit && !read_stall && allocate.valid) begin
            write_en = 1'b1;
        end
    end




endmodule : commit