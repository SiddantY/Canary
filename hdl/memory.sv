module memory(
    input   logic           clk,
    input   logic           rst,

    input   logic           flush,
    input   logic           jump_en,
    input   logic           jalr_en,

    input   logic   [31:0]  ooo_imem_addr,
    input   logic           ooo_input_valid,
    output  logic   [31:0]  ooo_imem_rdata,
    output  logic           ooo_imem_resp,
    output  logic   [31:0]  ooo_imem_raddr,
    output  logic           ooo_imem_stall,

    input   logic   [31:0]  ooo_dmem_addr,
    input   logic   [3:0]   ooo_dmem_rmask,
    input   logic   [3:0]   ooo_dmem_wmask,
    output  logic   [31:0]  ooo_dmem_rdata,
    input   logic   [31:0]  ooo_dmem_wdata,
    output  logic           ooo_dmem_resp,

    input   logic   [31:0]  ppl_imem_addr,
    input   logic   [3:0]   ppl_imem_rmask,
    output  logic   [31:0]  ppl_imem_rdata,
    output  logic           ppl_imem_resp,

    input   logic   [31:0]  ppl_dmem_addr,
    input   logic   [3:0]   ppl_dmem_rmask,
    input   logic   [3:0]   ppl_dmem_wmask,
    output  logic   [31:0]  ppl_dmem_rdata,
    input   logic   [31:0]  ppl_dmem_wdata,
    output  logic           ppl_dmem_resp,

    output logic   [31:0]   bmem_addr,
    output logic            bmem_read,
    output logic            bmem_write,
    output logic   [63:0]   bmem_wdata,
    
    input logic             bmem_ready,
    input logic   [31:0]    bmem_raddr,
    input logic   [63:0]    bmem_rdata,
    input logic             bmem_rvalid
);

// garbage sigs
logic in_writeBack, in_compare, in_idle;

//ufp latching + etc
logic [31:0] ooo_dmem_addr_latch, ooo_dmem_addr_use;
logic [3:0] ooo_dmem_rmask_latch, ooo_dmem_rmask_use;
logic [3:0] ooo_dmem_wmask_latch, ooo_dmem_wmask_use;
logic [31:0] ooo_dmem_wdata_latch, ooo_dmem_wdata_use;

logic [31:0] ooo_dmem_rdata_out;
logic ooo_dmem_resp_out;

always_ff @( posedge clk ) begin : dmem_out_regs

    if(rst) begin
        ooo_dmem_rdata <= '0;
        ooo_dmem_resp <= '0;
    end else begin
        ooo_dmem_rdata <= ooo_dmem_rdata_out;
        ooo_dmem_resp <= ooo_dmem_resp_out;
    end

end

always_ff @( posedge clk ) begin : dmem_latching
    if(rst) begin
        ooo_dmem_addr_latch <= '0;
        ooo_dmem_rmask_latch <= '0;
        ooo_dmem_wmask_latch <= '0;
        ooo_dmem_wdata_latch <= '0;
        // cache_in_use <= 1'b0;
    end else begin

        if(((ooo_dmem_rmask | ooo_dmem_wmask) != '0)) begin
            ooo_dmem_addr_latch <= ooo_dmem_addr;
            ooo_dmem_rmask_latch <= ooo_dmem_rmask;
            ooo_dmem_wmask_latch <= ooo_dmem_wmask;
            ooo_dmem_wdata_latch <= ooo_dmem_wdata;
        end

        else if(ooo_dmem_resp_out) begin
            ooo_dmem_addr_latch <= '0;
            ooo_dmem_rmask_latch <= '0;
            ooo_dmem_wmask_latch <= '0;
            ooo_dmem_wdata_latch <= '0;

        end
    end
end

always_comb begin : dmem_sigs
    if((ooo_dmem_rmask | ooo_dmem_wmask) != '0 && !flush) begin
        ooo_dmem_addr_use = ooo_dmem_addr;
        ooo_dmem_rmask_use = ooo_dmem_rmask;
        ooo_dmem_wmask_use = ooo_dmem_wmask;
        ooo_dmem_wdata_use = ooo_dmem_wdata;
    end else begin
        ooo_dmem_addr_use = ooo_dmem_addr_latch;
        ooo_dmem_rmask_use = ooo_dmem_rmask_latch;
        ooo_dmem_wmask_use = ooo_dmem_wmask_latch;
        ooo_dmem_wdata_use = ooo_dmem_wdata_latch;
    end
end

// Cache dfp signals
logic [31:0] ooo_i_dfp_addr, ooo_d_dfp_addr, ppl_i_dfp_addr, ppl_d_dfp_addr;

logic ooo_i_dfp_read, ooo_d_dfp_read, ppl_i_dfp_read, ppl_d_dfp_read;
logic ooo_d_dfp_write, ppl_d_dfp_write;

logic [255:0] ooo_i_dfp_rdata, ooo_d_dfp_rdata, ppl_i_dfp_rdata, ppl_d_dfp_rdata;

logic [31:0]  ooo_i_dfp_raddr;

logic [255:0] ooo_d_dfp_wdata, ppl_d_dfp_wdata;

logic ooo_i_dfp_resp, ooo_d_dfp_resp, ppl_i_dfp_resp, ppl_d_dfp_resp;

// Write Counter
logic w_done;
logic [1:0] write_counter;

//Receiving Data Signals
logic [1:0] receive_counter;
logic done;
logic [63:0] chunk0, chunk1, chunk2, chunk3;

enum int unsigned {
    service_ooo_i_cache,
    service_ooo_d_cache,
    service_ppl_i_cache,
    service_ppl_d_cache,
    servicing
} state, next_state, prev_state;


always_ff @(posedge clk) begin : round_robin_scheduling_for_main_memory_access
    
    if(rst) begin

        state <= service_ooo_i_cache;
        prev_state <= service_ppl_i_cache;

    end else begin

        state <= next_state;

        if(next_state == servicing && state != servicing) prev_state <= state;

    end

end : round_robin_scheduling_for_main_memory_access

always_comb begin : next_state_for_round_robin_scheduler

    case (state)
        service_ooo_i_cache : begin
            if(ooo_i_dfp_read) next_state = servicing;
            else next_state = service_ooo_d_cache;
        end
        service_ooo_d_cache : begin
            if(ooo_d_dfp_read || ooo_d_dfp_write) next_state = servicing;
            else next_state = service_ppl_i_cache;
        end
        service_ppl_i_cache : begin
            if(ppl_i_dfp_read) next_state = servicing;
            else next_state = service_ppl_d_cache;
        end
        service_ppl_d_cache : begin
            if(ppl_d_dfp_read || ppl_d_dfp_write) next_state = servicing;
            else next_state = service_ooo_i_cache;
        end
        servicing : begin
            if(ooo_i_dfp_resp || ooo_d_dfp_resp || ppl_i_dfp_resp || ppl_d_dfp_resp) begin
                case (prev_state)
                    service_ooo_i_cache: next_state = service_ooo_d_cache;
                    service_ooo_d_cache: next_state = service_ppl_i_cache;
                    service_ppl_i_cache: next_state = service_ppl_d_cache;
                    service_ppl_d_cache: next_state = service_ooo_i_cache;
                endcase
            end else begin
                next_state = servicing;
            end
        end
    endcase

end

logic servicing_bmem_read;

always_comb
    begin : setting_signals_for_bmem
        
        bmem_addr = '0;
        bmem_read = '0;
        bmem_write = '0;

        if(state == servicing && prev_state == service_ooo_i_cache && !servicing_bmem_read) begin

            bmem_addr = ooo_i_dfp_addr;
            bmem_read = 1'b1;
            bmem_write = 1'b0;
            
        end else if(state == servicing && prev_state == service_ooo_d_cache && !servicing_bmem_read) begin

            bmem_addr  = ooo_d_dfp_addr ;
            bmem_read  = ooo_d_dfp_read ;
            bmem_write = ooo_d_dfp_write;
            
        end else if(state == servicing && prev_state == service_ppl_i_cache && !servicing_bmem_read) begin

            bmem_addr = ooo_i_dfp_addr;
            bmem_read = 1'b1;
            bmem_write = 1'b0;

        end else if(state == servicing && prev_state == service_ppl_i_cache && !servicing_bmem_read) begin

            bmem_addr  = ppl_i_dfp_addr ;
            bmem_read  = ooo_d_dfp_read ;
            bmem_write = ooo_d_dfp_write;

        end  

    end : setting_signals_for_bmem

always_ff @(posedge clk) begin : make_sure_reads_only_high_one_cycle


    if (rst) begin
        
        servicing_bmem_read <= 1'b0;
        
    end else begin
        
        if(state == servicing && prev_state == service_ooo_i_cache) begin
        
            servicing_bmem_read <= 1'b1;
    
        end else if (state == servicing && prev_state == service_ooo_d_cache) begin
        
            if(ooo_d_dfp_read) servicing_bmem_read <= 1'b1;
        
        end else if (state == servicing && prev_state == service_ppl_i_cache) begin
        
            servicing_bmem_read <= 1'b1;

        end else if(state == servicing && prev_state == service_ppl_i_cache) begin
        
            if(ppl_d_dfp_read) servicing_bmem_read <= 1'b1;

        end

        if(ooo_i_dfp_resp || ooo_d_dfp_resp || ppl_i_dfp_resp || ppl_d_dfp_resp) servicing_bmem_read <= 1'b0;

    end
end

always_ff @( posedge clk ) begin : receiving_data
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
                end
            end else begin
                done <= 1'b0;
            end
        end
    end

always_comb begin : combining_data_and_sending_out_resps
        // Receiving a request
        ooo_i_dfp_resp = '0;
        ooo_i_dfp_rdata = '0;
        ooo_i_dfp_raddr = '0;

        ooo_d_dfp_resp = '0;
        ooo_d_dfp_rdata = '0;

        ppl_i_dfp_resp = '0;
        ppl_i_dfp_rdata = '0;

        ppl_d_dfp_resp = '0;
        ppl_d_dfp_rdata = '0;

        if(/*bmem_raddr[31:5] == ooo_i_dfp_addr[31:5] &&*/ done && prev_state == service_ooo_i_cache) begin
            ooo_i_dfp_rdata = {bmem_rdata, chunk2, chunk1, chunk0};
            ooo_i_dfp_resp = 1'b1;
            ooo_i_dfp_raddr = bmem_raddr;
        end 

        if(bmem_raddr[31:5] == ooo_d_dfp_addr[31:5] && done && prev_state == service_ooo_d_cache) begin
            ooo_d_dfp_rdata = {bmem_rdata, chunk2, chunk1, chunk0};
            ooo_d_dfp_resp = 1'b1;
        end

        if(bmem_raddr[31:5] == ppl_i_dfp_addr[31:5] && done && prev_state == service_ppl_i_cache) begin
            ppl_i_dfp_rdata = {bmem_rdata, chunk2, chunk1, chunk0};
            ppl_i_dfp_resp = 1'b1;
        end

        if(bmem_raddr[31:5] == ppl_d_dfp_addr[31:5] && done && prev_state == service_ppl_d_cache) begin
            ppl_d_dfp_rdata = {bmem_rdata, chunk2, chunk1, chunk0};
            ppl_d_dfp_resp = 1'b1;
        end


        if (w_done && prev_state == service_ooo_d_cache) ooo_d_dfp_resp = 1'b1;
        if (w_done && prev_state == service_ppl_d_cache) ppl_d_dfp_resp = 1'b1;

    end

always_ff @(posedge clk) begin : write_counter_logic


    if (rst) begin 
        write_counter = '0;
        w_done = 1'b0;
    end

    else begin

        w_done <= 1'b0;
        bmem_wdata <= '0;
        
        if ((next_state == servicing && state == service_ooo_d_cache && ooo_d_dfp_write == 1'b1)
            || (next_state == servicing && state == service_ppl_d_cache && ppl_d_dfp_write == 1'b1)) begin
                bmem_wdata <= state == service_ooo_d_cache ? ooo_d_dfp_wdata[63:0] : ppl_d_dfp_wdata[63:0]; 
                write_counter <= 2'd1; 
        end
        
        if(write_counter == 2'd1) begin bmem_wdata <= prev_state == service_ooo_d_cache ? ooo_d_dfp_wdata[127:64] : ppl_d_dfp_wdata[127:64]; write_counter <= write_counter + 2'd1; end
        
        if(write_counter == 2'd2) begin bmem_wdata <= prev_state == service_ooo_d_cache ? ooo_d_dfp_wdata[191:128] : ppl_d_dfp_wdata[191:128]; write_counter <= write_counter + 2'd1; end
        
        if(write_counter == 2'd3) begin 
            bmem_wdata <= prev_state == service_ooo_d_cache ? ooo_d_dfp_wdata[255:192] : ppl_d_dfp_wdata[255:192];
            write_counter <= 2'd0; 
            w_done <= 1'b1;
        end
    end

end

// Cache Instantions Below

// OOO I-Cache
pipe_icache #(
        .SETS(16)
    )
    pipe_icache
    (
        .clk(clk),
        .rst(rst),
        .flush(flush | jump_en | jalr_en),
    // cpu side signals, ufp -> upward facing port
        .input_valid(ooo_input_valid),
  
        .ufp_addr(ooo_imem_addr),                   // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
        .ufp_rdata(ooo_imem_rdata),
        .ufp_resp(ooo_imem_resp),
        .ufp_raddr(ooo_imem_raddr),
        .read_stall(ooo_imem_stall),
        
    // memory side signals, dfp -> downward facing port
        .dfp_addr(ooo_i_dfp_addr),                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
        .dfp_read(ooo_i_dfp_read),
        .dfp_rdata(ooo_i_dfp_rdata),
        .dfp_raddr(ooo_i_dfp_raddr),
        .dfp_resp(ooo_i_dfp_resp && bmem_raddr[31:5] == ooo_i_dfp_addr[31:5])
    );

// ooo_dcache
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
    .ufp_addr(ooo_dmem_addr_use), // SLICE LAST 2 BITS AMAAN????                  // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
    .ufp_rmask(ooo_dmem_rmask_use),                  // specifies which bytes of ufp_rdata the UFP will use. You may return any byte at a position whose corresponding bit in ufp_rmask is zero. A nonzero ufp_rmask indicates a read request
    .ufp_wmask(ooo_dmem_wmask_use),                  // tells the cache which bytes out of the 4 bytes in ufp_wdata are to be written. A nonzero ufp_wmask indicates a write request.
    .ufp_rdata(ooo_dmem_rdata_out),
    // .ufp_rdata(dmem_rdata),
    .ufp_wdata(ooo_dmem_wdata_use),
    .ufp_resp(ooo_dmem_resp_out),
    // .ufp_resp(dmem_resp),

    // memory side signals, dfp -> downward facing port
    .dfp_addr(ooo_d_dfp_addr),                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
    .dfp_read(ooo_d_dfp_read),
    .dfp_write(ooo_d_dfp_write),
    .dfp_rdata(ooo_d_dfp_rdata),
    .dfp_wdata(ooo_d_dfp_wdata),
    .dfp_resp(ooo_d_dfp_resp)
);

// Pipline_icache

I_CACHE I_CACHE( 
    .clk        (clk), 
    .rst        (rst),
    .ufp_addr   (ppl_imem_addr),
    .ufp_rmask  (ppl_imem_rmask),
    .ufp_rdata  (ppl_imem_rdata),
    .ufp_resp   (ppl_imem_resp),

    .dfp_addr   (ppl_i_dfp_addr),
    .dfp_read   (ppl_i_dfp_read),
    .dfp_rdata  (ppl_i_dfp_rdata),
    .dfp_resp   (ppl_i_dfp_resp)
);

// Pipeline_dcache

D_CACHE D_CACHE( 
    .clk        (clk),
    .rst        (rst),
    .ufp_addr   (ppl_dmem_addr),
    .ufp_rmask  (ppl_dmem_rmask),
    .ufp_wmask  (ppl_dmem_wmask),
    .ufp_rdata  (ppl_dmem_rdata),
    .ufp_wdata  (ppl_dmem_wdata),
    .ufp_resp   (ppl_dmem_resp),

    .dfp_addr   (ppl_d_dfp_addr),
    .dfp_read   (ppl_d_dfp_read),
    .dfp_write  (ppl_d_dfp_write),
    .dfp_rdata  (ppl_d_dfp_rdata),
    .dfp_wdata  (ppl_d_dfp_wdata),
    .dfp_resp   (ppl_d_dfp_resp)
);

endmodule