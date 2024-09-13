module arbiter(
    input   logic               clk,
    input   logic               rst,
    input   logic               flush,
    input   logic               jalr_en,
    input   logic               jump_en,
    // input   logic               br_en,

    input   logic   [31:0]      imem_addr,
    input   logic               input_valid,
    output  logic   [31:0]      imem_rdata,
    output  logic               imem_resp,
    output  logic               imem_stall,
    output  logic   [31:0]      imem_raddr,


    input   logic   [31:0]      dmem_addr,
    input   logic   [3:0]       dmem_rmask, 
    input   logic   [3:0]       dmem_wmask,
    input   logic   [31:0]      dmem_wdata,
    // output  logic   [31:0]      dmem_raddr,
    output  logic   [31:0]      dmem_rdata,
    output  logic               dmem_resp,


    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid
);
    logic [1:0] receive_counter, write_counter;
    logic [63:0] chunk0, chunk1, chunk2, chunk3, wd0, wd1, wd2, wd3;
    logic done, w_done;    
    logic bmem_fake;
    assign bmem_fake = bmem_ready;
    
    // logic i_cache_resp, d_cache_resp;
    logic [31:0] i_dfp_addr, d_dfp_addr, i_dfp_raddr, d_dfp_addr_l2, d_ufp_addr_l2;
    logic i_dfp_read, d_dfp_read, d_dfp_read_l2, d_ufp_read_l2;
    logic i_dfp_write, d_dfp_write, d_dfp_write_l2, d_ufp_write_l2;
    logic [255:0] i_dfp_rdata, d_dfp_rdata, d_dfp_rdata_l2, d_ufp_rdata_l2;
    logic [255:0] i_dfp_wdata, d_dfp_wdata, d_dfp_wdata_l2, d_ufp_wdata_l2;
    logic i_dfp_resp, d_dfp_resp, d_dfp_resp_l2, d_ufp_resp_l2;

    logic i_submit, d_submit;
    logic in_writeBack, in_compare, in_idle;
    logic flush_latch; 

    logic   [31:0]      dmem_addr_latch, dmem_addr_use;
    logic   [3:0]       dmem_rmask_latch, dmem_rmask_use;
    logic   [3:0]       dmem_wmask_latch, dmem_wmask_use;
    logic   [31:0]      dmem_wdata_latch, dmem_wdata_use;
    logic cache_in_use;
    logic invalid_i, invalid_d;

    logic imem_resp_cache;


    always_ff @( posedge clk ) begin : flu

        if (rst) flush_latch <= 1'b0;

        else begin
            if (flush && in_writeBack) flush_latch <= 1'b1;
            else if (!in_writeBack) flush_latch <= 1'b0;
        end
        
    end

    logic [31:0] dmem_rdata_out;
    logic dmem_resp_out;
    always_ff @( posedge clk ) begin : dmem_out_regs
        if(rst) begin
            dmem_rdata <= '0;
            dmem_resp <= '0;
        end else begin
            dmem_rdata <= dmem_rdata_out;
            dmem_resp <= dmem_resp_out;
        end
    end

    always_ff @( posedge clk ) begin : dmem_latching
        if(rst) begin
            dmem_addr_latch <= '0;
            dmem_rmask_latch <= '0;
            dmem_wmask_latch <= '0;
            dmem_wdata_latch <= '0;
            // cache_in_use <= 1'b0;
        end else begin

            // if (in_idle && flush) begin
            //     dmem_addr_latch <= '0;
            //     dmem_rmask_latch <= '0;
            //     dmem_wmask_latch <= '0;
            //     dmem_wdata_latch <= '0;
            // end

            // else 
            if(((dmem_rmask | dmem_wmask) != '0)) begin
                dmem_addr_latch <= dmem_addr;
                dmem_rmask_latch <= dmem_rmask;
                dmem_wmask_latch <= dmem_wmask;
                dmem_wdata_latch <= dmem_wdata;
            end

            // else if (w_done && flush_latch) begin
            //     dmem_addr_latch <= '0;
            //     dmem_rmask_latch <= '0;
            //     dmem_wmask_latch <= '0;
            //     dmem_wdata_latch <= '0;
            // end

            // else if (in_compare && flush) begin
            //     dmem_addr_latch <= '0;
            //     dmem_rmask_latch <= '0;
            //     dmem_wmask_latch <= '0;
            //     dmem_wdata_latch <= '0;
            // end

            else if(dmem_resp_out) begin
                dmem_addr_latch <= '0;
                dmem_rmask_latch <= '0;
                dmem_wmask_latch <= '0;
                dmem_wdata_latch <= '0;

            end
        end
    end

    always_comb begin : dmem_sigs
        if((dmem_rmask | dmem_wmask) != '0 && !flush) begin
            dmem_addr_use = dmem_addr;
            dmem_rmask_use = dmem_rmask;
            dmem_wmask_use = dmem_wmask;
            dmem_wdata_use = dmem_wdata;
        end else begin
            dmem_addr_use = dmem_addr_latch;
            dmem_rmask_use = dmem_rmask_latch;
            dmem_wmask_use = dmem_wmask_latch;
            dmem_wdata_use = dmem_wdata_latch;
        end
    end

   
    logic l2_cache_ready;

    always_ff @( posedge clk ) begin : making_request
        if(rst) begin
            write_counter <= '0;
            w_done <= '0;
            i_submit <= '0;
            d_submit <= '0;
            l2_cache_ready <= 1'b1;
            d_ufp_read_l2 <= 1'b0;
            d_ufp_write_l2 <= 1'b0;
        end else begin
            if(l2_cache_ready) begin
                // FIRST IMEM REQESTS
                if(i_dfp_read && !i_submit) begin

                    d_ufp_addr_l2 <= i_dfp_addr;
                    d_ufp_read_l2 <= 1'b1;
                    d_ufp_write_l2 <= 1'b0;
                    w_done <= 1'b0;
                    i_submit <= 1'b1;

                    l2_cache_ready <= 1'b0;

                end else if(d_dfp_read && !d_submit && !i_submit) begin // DMEM READ
                   
                    d_ufp_addr_l2 <= d_dfp_addr; //@TODO
                    d_ufp_read_l2 <= 1'b1;
                    d_ufp_write_l2 <= 1'b0;
                    w_done <= 1'b0;
                    d_submit <= 1'b1;

                    l2_cache_ready <= 1'b0;

                end else if(d_dfp_write && !d_submit && !i_submit) begin // DMEM WRITE
                    
                    d_ufp_addr_l2 <= d_dfp_addr; //@TODO
                    d_ufp_read_l2 <= 1'b0;
                    d_ufp_write_l2 <= 1'b1;
                    d_ufp_wdata_l2 <= d_dfp_wdata;
                    d_submit <= 1'b1; 
                    w_done <= 1'b0;

                    l2_cache_ready <= 1'b0;

                end else begin

                    d_ufp_addr_l2 <= '0;
                    d_ufp_read_l2 <= 1'b0;
                    d_ufp_write_l2 <= 1'b0;
                    d_ufp_wdata_l2 <= '0;
                    w_done <= 1'b0;

                    l2_cache_ready <= 1'b1;

                end
            end 
            // else begin
            //     if(d_ufp_read_l2 && i_submit && (jalr_en)) begin
            //         d_ufp_addr_l2 <= imem_addr;
            //     end
            
            // end

            if(d_ufp_resp_l2 /*(d_ufp_resp_l2 | (flush | jump_en | jalr_en))*/ && i_submit) begin
                i_submit <= 1'b0;
                l2_cache_ready <= 1'b1;
                if(d_ufp_read_l2) d_ufp_read_l2 <= 1'b0;
            end

            if(d_ufp_resp_l2 && d_submit/*| (flush)*/) begin
                d_submit <= 1'b0;
                l2_cache_ready <= 1'b1;
                if(d_ufp_read_l2) d_ufp_read_l2 <= 1'b0;
                if(d_ufp_write_l2) d_ufp_write_l2 <= 1'b0;
                w_done <= 1'b1;
            end
        end
    end

    logic bmem_read_submit;
    logic [1:0] write_counter_bmem;
    logic w_done_bmem;

    always_ff @(posedge clk) begin
        if(rst) begin
            bmem_read_submit <= 1'b0;
            write_counter_bmem <= 2'b00;
            bmem_addr <= '0;
            bmem_read <= 1'b0;
            bmem_write <= 1'b0;
            bmem_wdata <= '0;
        end else begin
            if(bmem_ready) begin
                if(d_dfp_read_l2 && !bmem_read_submit) begin
                    bmem_addr <= d_dfp_addr_l2;
                    bmem_read <= 1'b1;
                    bmem_write <= 1'b0;
                    bmem_wdata <= '0;
                    bmem_read_submit <= 1'b1;
                    w_done_bmem <= 1'b0;    
                end else if((d_dfp_write_l2 || write_counter_bmem != '0) && !w_done_bmem && !d_dfp_read_l2) begin

                    bmem_addr <= d_dfp_addr_l2;
                    bmem_read <= 1'b0;
                    bmem_write <= 1'b1;

                    w_done_bmem <= 1'b0;

                    if(write_counter_bmem == 2'd0) begin 
                        bmem_wdata <= d_dfp_wdata_l2[63:0]; 
                        write_counter_bmem <= write_counter_bmem + 2'd1; end
                    if(write_counter_bmem == 2'd1) begin 
                        bmem_wdata <= d_dfp_wdata_l2[127:64]; 
                        write_counter_bmem <= write_counter_bmem + 2'd1; end
                    if(write_counter_bmem == 2'd2) begin 
                        bmem_wdata <= d_dfp_wdata_l2[191:128]; 
                        write_counter_bmem <= write_counter_bmem + 2'd1; end
                    if(write_counter_bmem == 2'd3) begin 
                        bmem_wdata <= d_dfp_wdata_l2[255:192]; 
                        write_counter_bmem <= 2'd0; 
                        w_done_bmem <= 1'b1;
                    end
                end else begin
                    w_done_bmem <= 1'b0;
                    bmem_addr <= '0;
                    bmem_read <= 1'b0;
                    bmem_write <= 1'b0;
                    bmem_wdata <= '0;
                    w_done_bmem <= 1'b0;
                end
            end
        end

        if(rst) begin
            receive_counter <= '0;
            done <= '0;
            chunk0 <= '0;
            chunk1 <= '0;
            chunk2 <= '0;
            chunk3 <= '0;
        end else begin
            if(bmem_rvalid) begin
                if(receive_counter == 2'd0) begin chunk0 <= bmem_rdata; receive_counter <= receive_counter + 2'd1; end
                if(receive_counter == 2'd1) begin chunk1 <= bmem_rdata; receive_counter <= receive_counter + 2'd1; end
                if(receive_counter == 2'd2) begin chunk2 <= bmem_rdata; receive_counter <= receive_counter + 2'd1; done <= 1'b1; end
                if(receive_counter == 2'd3) begin 
                    chunk3 <= bmem_rdata; 
                    receive_counter <= 2'd0; 
                    done <= 1'b0;
                    bmem_read_submit <= 1'b0;
                end
            end else begin
                done <= 1'b0;
            end
        end
    end

    always_comb begin 
        // Receiving a request
        i_dfp_rdata = '0;
        i_dfp_resp = 1'b0;
        d_dfp_rdata = '0;
        d_dfp_resp = 1'b0;
        d_dfp_resp_l2 = 1'b0;

        // for l2 cache
        if(/*bmem_raddr[31:5] == dmem_addr_use[31:5] &&*/ done) begin
            d_dfp_rdata_l2 = {bmem_rdata, chunk2, chunk1, chunk0};
            d_dfp_resp_l2 = 1'b1;
        end

        if (w_done_bmem) d_dfp_resp_l2 = 1'b1;

    end

    logic [31:0] pc_prev;
    always_ff @( posedge clk ) begin : valid_icache_input
        if(rst | (flush | jump_en | jalr_en)) begin
            pc_prev <= '0;
        end else begin 
            pc_prev <= imem_addr;
        end
    end
    logic in_valid;
    assign in_valid = (pc_prev == imem_addr) ? 1'b0 : 1'b1;
    // CACHES

    pipe_icache #(
        .SETS(16)
    )
    pipe_icache
    (
        .clk(clk),
        .rst(rst),
        .flush(flush | jump_en | jalr_en),
    // cpu side signals, ufp -> upward facing port
        .input_valid(input_valid),
  
        .ufp_addr(imem_addr),                   // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
        .ufp_rdata(imem_rdata),
        .ufp_resp(imem_resp),
        .ufp_raddr(imem_raddr),
        .read_stall(imem_stall),
    // memory side signals, dfp -> downward facing port
        .dfp_addr(i_dfp_addr),                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
        .dfp_read(i_dfp_read),
        .dfp_rdata(d_ufp_rdata_l2),
        .dfp_raddr(i_dfp_raddr),
        .dfp_resp(d_ufp_resp_l2 & i_submit)
    );

    // L2 to l1 signals
    logic l1_dirty;
    logic [31:0] ufp_check_line_addr;
    logic [255:0] ufp_dirty_data;

    // No need for L1 to L2 signals from i cache since read only !!!

    cache d_cache (
        .clk(clk),
        .rst(rst),
        .flush(1'b0),
        .in_writeBack(in_writeBack),
        .in_compare(in_compare),
        // .flush_latch(flush_latch | flush | benny),
        .flush_latch('0),
        .in_idle(in_idle),

        // cpu side signals, ufp -> upward facing port
        .ufp_addr(dmem_addr_use), // SLICE LAST 2 BITS AMAAN????                  // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
        .ufp_rmask(dmem_rmask_use),                  // specifies which bytes of ufp_rdata the UFP will use. You may return any byte at a position whose corresponding bit in ufp_rmask is zero. A nonzero ufp_rmask indicates a read request
        .ufp_wmask(dmem_wmask_use),                  // tells the cache which bytes out of the 4 bytes in ufp_wdata are to be written. A nonzero ufp_wmask indicates a write request.
        .ufp_rdata(dmem_rdata_out),
        // .ufp_rdata(dmem_rdata),
        .ufp_wdata(dmem_wdata_use),
        .ufp_resp(dmem_resp_out),
        // .ufp_resp(dmem_resp),

        // memory side signals, dfp -> downward facing port
        .dfp_addr(d_dfp_addr),                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
        .dfp_read(d_dfp_read),
        .dfp_write(d_dfp_write),
        .dfp_rdata(d_ufp_rdata_l2),
        .dfp_wdata(d_dfp_wdata),
        .dfp_resp(d_ufp_resp_l2 & d_submit),

        // L2 cache signals
        .l1_dirty(l1_dirty),
        .ufp_dirty_data(ufp_dirty_data),
        .ufp_check_line_addr(ufp_check_line_addr)
    );

    l2cache l2 (
        .clk(clk),
        .rst(rst),
        .flush(1'b0),

        // cpu side signals, ufp -> upward facing port
        .ufp_addr(d_ufp_addr_l2),                   // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
        .ufp_rmask(d_ufp_read_l2 & (i_submit | d_submit)),                  // specifies which bytes of ufp_rdata the UFP will use. You may return any byte at a position whose corresponding bit in ufp_rmask is zero. A nonzero ufp_rmask indicates a read request
        .ufp_wmask(d_ufp_write_l2),                  // tells the cache which bytes out of the 4 bytes in ufp_wdata are to be written. A nonzero ufp_wmask indicates a write request.
        .ufp_rdata(d_ufp_rdata_l2),
        .ufp_wdata(d_ufp_wdata_l2),
        .ufp_resp(d_ufp_resp_l2),

        // memory side signals, dfp -> downward facing port
        .dfp_addr(d_dfp_addr_l2),                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
        .dfp_read(d_dfp_read_l2),
        .dfp_write(d_dfp_write_l2),
        .dfp_rdata(d_dfp_rdata_l2),
        .dfp_wdata(d_dfp_wdata_l2),
        .dfp_resp(d_dfp_resp_l2),

        .in_writeBack(),
        .in_compare(),
        .in_idle(),
        .flush_latch('0),

        // new l1 outwards
        .l1_dirty(l1_dirty),
        .ufp_dirty_data(ufp_dirty_data),
        .ufp_check_line_addr(ufp_check_line_addr),

        .imem_raddr(i_dfp_raddr),

        .icache_request(1'b0) // need the signal from arbiter that signifies a i cache request to skip the pulling stages
);

    // MESI mesi_fsm(

    // );
endmodule : arbiter