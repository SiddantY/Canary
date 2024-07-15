module allocate_module 
import rv32i_types::*;
#(
    parameter SETS = 16
)
(
    
    // input logic clk,
    // input logic rst,
    input logic cache_hit,
    input logic [255:0] cache_data,
    input hit_check_stage_t hit_check,
    // input logic [26:0] cache_blk,

    output allocate_stage_t allocate,
    output logic read_stall,
    
    // MEMORY PORTS
    output  logic   [31:0]  dfp_addr,                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
    output  logic           dfp_read,
    input   logic   [255:0] dfp_rdata,
    input   logic   [31:0]  dfp_raddr,
    input   logic           dfp_resp
 
);


// always_ff @(posedge clk) begin
    
//     if(rst) begin
        
//         dfp_addr <= '0;
//         dfp_read <= '0;
        
//     end else if begin

//         if(!cache_hit) begin
//             dfp_addr <= {hit_check.offset, hit_check.set, hit_check.tag};
//             dfp_read <= 1'b1;
//         end else if (dfp_read) begin

//             dfp_addr <= '0;
//             dfp_read <= '0;

//         end
//     end
// end
    logic matching_addr;
    assign matching_addr = dfp_resp ? dfp_raddr[31:5] == {hit_check.tag, hit_check.set} : 1'b0;
    always_comb begin
        
        // dfp_addr = '0;
        dfp_addr = {hit_check.tag, hit_check.set, 5'b0};
        dfp_read = '0;
    
        if(!cache_hit && hit_check.valid && 
            !matching_addr && 
            !hit_check.fwd)
        begin
            
            dfp_read = 1'b1;
        end 

        if(!hit_check.valid) begin
            read_stall = 1'b0;
        end else if((cache_hit /*&& cache_blk == {hit_check.tag, hit_check.set}*/)|| hit_check.fwd) begin
            read_stall = 1'b0;
        end else begin
            if(dfp_resp /*|| matching_addr*/) begin
                read_stall = 1'b0;
            end else begin
                read_stall = 1'b1;
            end
        end

        // pass regs values
        // allocate.ppc = hit_check.ppc;
        // allocate.br_en = hit_check.br_en;
        // allocate.pc_req = hit_check.pc_req;

        allocate.valid = hit_check.valid;
        allocate.rdata = cache_hit ? cache_data : (hit_check.fwd ? hit_check.rdata_fwd : dfp_rdata);
        // allocate.raddr = dfp_raddr;
        allocate.cache_hit = cache_hit;
        allocate.offset = hit_check.offset;
        allocate.set = hit_check.set;
        allocate.tag = hit_check.tag;
    end



endmodule : allocate_module