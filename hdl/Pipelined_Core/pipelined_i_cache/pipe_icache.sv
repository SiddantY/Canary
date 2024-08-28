module pipe_icache 
import rv32i_types::*;
#(
    parameter SETS =   16
)
(
    input   logic           clk,
    input   logic           rst,
    input   logic           flush,
    // cpu side signals, ufp -> upward facing port
    // input   logic           pc_req,
    input   logic           input_valid,
    // input   logic   [31:0]  ppc,
    // input   logic           br_en,
    input   logic   [31:0]  ufp_addr,                   // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
    output  logic   [31:0]  ufp_rdata,
    output  logic           ufp_resp,
    output  logic   [31:0]  ufp_raddr,
    output  logic           read_stall,

    // BP OUT
    // output  logic   [31:0]  ppc_out,
    // output  logic           br_en_out,
    // output  logic           pc_req_out,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
    output  logic           dfp_read,
    input   logic   [255:0] dfp_rdata,
    input   logic   [31:0]  dfp_raddr,
    input   logic           dfp_resp
);

    // addr -> {X, tag, N set,5 offset}

    // PIPE STAGE VARS
    hit_check_stage_t hit_check, hit_check_new;
    allocate_stage_t allocate, allocate_new;
    // logic read_stall;    
    logic cache_hit;

    // WRITING Signals
    logic write_en;
    logic [$clog2(SETS)-1:0] write_set;

    // Data Array Signals
    logic [255:0] data_in;
    logic [255:0] data_out;
    logic [31: 0] cache_wmask;

    // Tag Array Signals
    logic         t_write_en;
    logic [26-$clog2(SETS):0] tag_in;
    logic [26-$clog2(SETS):0] tag_out;

    // Valid Array Signals
    logic         valid_in;
    logic         valid_out;

    assign ufp_resp = allocate.valid;
    always_ff @( posedge clk ) begin : pipeline
        if(rst | flush) begin
            hit_check <= '0;
            allocate <= '0;
            // ufp_resp <= '0;
        end else begin
            // add not stalling condition
            if(/*input_valid &&*/ !read_stall) begin
                hit_check <= hit_check_new;
                allocate <= allocate_new;
                // if(allocate_new.valid) ufp_resp <= 1'b1;
            end else begin
                // ufp_resp <= 1'b0;
            end

        end        
    end

    hit_check_module hit_check_module(
        // .ppc(ppc),
        // .br_en(br_en),
        // .pc_req(pc_req),
        .ufp_addr(ufp_addr),
        .input_valid(input_valid),
        .hit_check(hit_check_new),
        .dfp_raddr(dfp_raddr),
        .dfp_rdata(dfp_rdata),
        .ufp_raddr(ufp_raddr),
        .ufp_rdata(allocate.rdata)
    );

    always_comb begin : cache_hit_logic
        cache_hit = valid_out ? ((tag_out == hit_check.tag) ? 1'b1 : 1'b0) : 1'b0;
    end

    allocate_module #(
        .SETS(SETS)
    )
    allocate_module(
        // .clk(clk),
        // .rst(rst),
        .cache_hit(cache_hit),
        // .cache_blk({tag_out, hit_check_new.set}), // maybe rest of addr?
        .hit_check(hit_check),
        .cache_data(data_out),
        .allocate(allocate_new),
        .read_stall(read_stall),
    
        // MEMORY PORTS
        .dfp_addr(dfp_addr),                   
        .dfp_read(dfp_read),
        .dfp_rdata(dfp_rdata),
        .dfp_raddr(dfp_raddr),
        .dfp_resp(dfp_resp)
        
    );


    commit #(
        .SETS(SETS)
    )    
    commit_module(
        .allocate(allocate),
        .read_stall(read_stall),
        .data_in(data_in),
        .write_en(write_en),
        .tag_in(tag_in),
        .write_set(write_set)
    );

    assign ufp_rdata = allocate.rdata[32*allocate.offset[4:2] +: 32];
    assign ufp_raddr = {allocate.tag, allocate.set, allocate.offset};
    // assign ppc_out = allocate.ppc;
    // assign br_en_out = allocate.br_en;
    // assign pc_req_out = allocate.pc_req;
    logic csb1;
    assign csb1 = read_stall;
    pipe_cache_data data_array (// Data Block 0 - write, 1 - read
        .clk0       (clk),
        .csb0       (!write_en), 
        .addr0      (write_set),
        .wmask0     (32'hFFFF_FFFF),  // WHOLE THING NEEDS COMMIT Q INTEGRATION
        .din0       (data_in),
        .clk1       (clk),
        .csb1       (csb1), // active low - always active
        .addr1      (hit_check_new.set),
        .dout1      (data_out)
    );
    pipe_cache_tag tag_array (// Tag Array 24 bit (dirty | tag)
        .clk0       (clk),
        .csb0       (!write_en),
        .addr0      (write_set),
        // .wmask0     (24'hFFFF_FF),
        .din0       (tag_in),
        .clk1       (clk), 
        .csb1       (csb1), // active low - always active
        .addr1      (hit_check_new.set),
        .dout1      (tag_out)
    );

    ff_icache #(
        .WIDTH(1),
        .S_INDEX($clog2(SETS))
    ) 
    valid_array (// Valid Array 0 - write, 1 - read
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (csb1),
        .web0       (!write_en), 
        .addr0      (write_set), 
        .addr1      (hit_check_new.set),
        .din0       (1'b1),
        .dout1      (valid_out)
    );





endmodule