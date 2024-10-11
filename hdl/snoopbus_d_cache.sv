module snoopbus_d_cache
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           flush,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,                   // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
    input   logic   [3:0]   ufp_rmask,                  // specifies which bytes of ufp_rdata the UFP will use. You may return any byte at a position whose corresponding bit in ufp_rmask is zero. A nonzero ufp_rmask indicates a read request
    input   logic   [3:0]   ufp_wmask,                  // tells the cache which bytes out of the 4 bytes in ufp_wdata are to be written. A nonzero ufp_wmask indicates a write request.
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp,

    // INCOMING BUS REQUESTS FROM OTHER CACHE

    input    logic   [31:0]  bus_incomming_command_address,
    input    logic   [2:0]   bus_incomming_command_command,

    // MAKING BUS OUTGOING SIGNALS

    output  logic   [31:0]  bus_command_address,
    output  logic   [2:0]   bus_command_command,
    output  logic   [255:0] bus_command_data,

    output  logic           snoop_bus_query,

    // BUS RESPONSE TO OUTGOING QUERY

    input   logic   [31:0]  bus_resp_addr,
    input   logic   [2:0]   bus_resp_command,
    input   logic   [255:0] bus_resp_data,

    output  logic   [255:0] bus_data_out,               // RESPONDING TO BUS QUERY

    output  logic           bus_cache_hit,


    input   logic           amo,

    // BUS STATUS SIGNALS
    
    input   logic           bus_ready,
    input   logic   [1:0]   bus_resp,

    output  logic           in_writeBack,
    output  logic           in_compare,
    output  logic           in_idle,


    input   logic           flush_latch,

    input   logic   [31:0]  this_address_locked_by_others,
    input   logic   [31:0]  this_address_locked_by_you,

    output  logic           unlock,

    input   logic           bus_in_cache_dirty,
    output  logic           bus_out_cache_dirty

);


// Data Array Signals
logic         d_write_en [4];
logic [255:0] data_in    [4];
logic [255:0] data_out   [4];
logic [31: 0] cache_wmask;

logic         d_write_en1  [4];
logic [255:0] data_in1     [4];
logic [255:0] data_out1    [4];
logic [31: 0] cache_wmask1;

// Tag Array Signals
logic         t_write_en [4];
logic [25 :0] tag_in     [4];
logic [25: 0] tag_out    [4];

logic         t_write_en1 [4];
logic [25 :0] tag_in1     [4];
logic [25 :0] tag_out1    [4];

// Valid Array Signals
logic         v_write_en [4];
logic         v_write_en1 [4];
logic         valid_in   [4];
logic         valid_out  [4];

logic         valid_out1  [4];


// LRU Signals
logic         load_lru;
logic [2:0]   lru_in, lru_out;
logic [1:0]   PLRU_way;

logic [1:0] way_index;


enum int unsigned {
    idle,
    compare,
    write_back,
    allocate,
    stall,
    acquire_bus_write,
    broadcast_write,
    acquire_bus_read,
    bus_read
} state, next_state;

always_ff @(posedge clk) begin: next_state_assignment
    state <= next_state;
end

logic cache_hit;
logic [3:0] way_hit;

always_comb begin : cache_hit_logic
    way_hit[0] = (tag_out[0][22:0] == ufp_addr[31:9]) && valid_out[0];
    way_hit[1] = (tag_out[1][22:0] == ufp_addr[31:9]) && valid_out[1];
    way_hit[2] = (tag_out[2][22:0] == ufp_addr[31:9]) && valid_out[2];
    way_hit[3] = (tag_out[3][22:0] == ufp_addr[31:9]) && valid_out[3];

    cache_hit = way_hit[0] | way_hit[1] | way_hit[2] | way_hit[3];
end


always_comb begin : next_state_logic

    if (rst | flush) next_state = idle;

    else begin

        case (state)

            idle : begin                                           // Wait for valid read or write request from processor
                if (ufp_rmask != 4'b0 || ufp_wmask != 4'b0) next_state = compare;
                else next_state = idle;
            end

            compare : begin
                if (flush_latch) next_state = idle;
                else begin
                    if (cache_hit && ufp_wmask != 0 && tag_out[way_index][25:24] != 2'b11) next_state = acquire_bus_write;
                    else if(cache_hit) next_state = idle;
                    else if (tag_out[PLRU_way][23]) next_state = write_back;
                    else if(tag_out[PLRU_way][25:24] == 2'b00) next_state = acquire_bus_read;                 
                    else next_state = acquire_bus_read;
                end
            end

            acquire_bus_write : begin
                if(bus_ready) next_state = broadcast_write;
                else next_state = acquire_bus_write;
            end

            broadcast_write : begin                                         // Sending out Invalidates
                if(bus_resp > 2'b00) next_state = compare;
                else next_state = broadcast_write;                                                                                                                                                                           
            end

            write_back : begin
                if (dfp_resp) begin
                    if (flush_latch) next_state = idle;
                    else next_state = acquire_bus_read;
                end

                else next_state = write_back;
                // next_state = allocate;
            end

            acquire_bus_read : begin
                if(bus_ready) next_state = bus_read;
                else next_state = acquire_bus_read;
            end

            bus_read : begin
                if(bus_resp == 2'b01) next_state = stall;                   // Bus Hit
                else if(bus_resp == 2'b10) next_state = allocate;           // Bus Miss
                else next_state = bus_read; 
            end

            allocate : begin
                if (dfp_resp) next_state = stall;
                else next_state = allocate;
            end

            stall : next_state = compare;

            default: next_state = idle;

        endcase

    end    
end

logic [1:0] lol0;
logic [1:0] lol1;
logic [1:0] lol2;
logic [1:0] lol3;

assign lol0 = tag_out[0][25:24];
assign lol1 = tag_out[1][25:24];
assign lol2 = tag_out[2][25:24];
assign lol3 = tag_out[3][25:24];


logic [31:9] tag;
logic [8:5]  set_index;
logic [4:0]  offset;

logic [31:0] w_maskEXT, r_maskEXT;

logic mask_ufp_resp;

always_comb begin : LRU_Set

    case (way_index)
        2'b00 : lru_in = {1'b1, 1'b1, lru_out[0]};      // A
        2'b01 : lru_in = {1'b1, 1'b0, lru_out[0]};      // B
        2'b10 : lru_in = {1'b0, lru_out[1], 1'b1};      // C
        2'b11 : lru_in = {1'b0, lru_out[1], 1'b0};      // D
    endcase
    
end

always_comb begin : LRU_Decode

    if (lru_out[2] == 1'b0) begin
        PLRU_way = lru_out[1] ? 2'b01 : 2'b00;
    end
    else begin
        PLRU_way = lru_out[0] ? 2'b11 : 2'b10;
    end

end

always_comb begin : state_signals
    bus_command_data = '0;

    // Set Defaults:
    t_write_en [0] = 1'b0; 
    tag_in     [0] = tag_out[0];    
    v_write_en [0] = 1'b0;

    t_write_en [1] = 1'b0;
    tag_in     [1] = tag_out[1];
    v_write_en [1] = 1'b0;

    t_write_en [2] = 1'b0; 
    tag_in     [2] = tag_out[2];
    v_write_en [2] = 1'b0;

    t_write_en [3] = 1'b0;
    tag_in     [3] = tag_out[3];
    v_write_en [3] = 1'b0;

    tag       = ufp_addr[31:9];
    set_index = ufp_addr[8:5];
    offset    = ufp_addr[4:0];

    dfp_read  = 1'b0;
    dfp_write = 1'b0;
    dfp_addr  = 'x;
    dfp_wdata = 'x;

    ufp_resp  = 1'b0;
    ufp_rdata = 'x;

    w_maskEXT = {{8{ufp_wmask[3]}}, {8{ufp_wmask[2]}}, {8{ufp_wmask[1]}}, {8{ufp_wmask[0]}}};
    r_maskEXT = {{8{ufp_rmask[3]}}, {8{ufp_rmask[2]}}, {8{ufp_rmask[1]}}, {8{ufp_rmask[0]}}};
    cache_wmask = 32'b0;

    load_lru = 1'b0;

    data_in[0] = 256'b0;
    data_in[1] = 256'b0;
    data_in[2] = 256'b0;
    data_in[3] = 256'b0;

    d_write_en[0] = 1'b0;
    d_write_en[1] = 1'b0;
    d_write_en[2] = 1'b0;
    d_write_en[3] = 1'b0;

    if (way_hit[0] == 1'b1)      way_index = 2'b00;
    else if (way_hit[2] == 1'b1) way_index = 2'b10;
    else if (way_hit[1] == 1'b1) way_index = 2'b01;
    else if (way_hit[3] == 1'b1) way_index = 2'b11;
    else way_index = 'x;

    in_writeBack = 1'b0;
    in_compare = 1'b0;
    in_idle = 1'b0;

    // snoopers stuff
    mask_ufp_resp = 1'b0;

    snoop_bus_query = 1'b0;

    bus_command_address = '0;
    bus_command_command = '0;

    // atomics

    unlock = 1'b0;

    case (state)

        idle: in_idle = 1'b1; 

        compare : begin
            
            if(ufp_addr == this_address_locked_by_others) begin
                
                ufp_resp = 1'b1;
                ufp_rdata = 32'hFFFF_FFFF;

            end else if (cache_hit && tag_out[way_index][25:24] != 2'b00) begin

                if (ufp_rmask != 4'b0) begin

                    ufp_rdata = data_out[way_index][32*offset[4:2]+:32] & r_maskEXT;

                end

                else if (ufp_wmask != 4'b0) begin

                    data_in[way_index] = {8{ufp_wdata & w_maskEXT}} ;         
                    d_write_en[way_index] = 1'b1;
                    cache_wmask = {28'b0,ufp_wmask} << (4*offset[4:2]);
                    // cache_wmask[4*offset[4:2]+:4] = ufp_wmask;

                    case(tag_out[way_index][25:24])
                        mesi_i : tag_in[way_index] = {2'b00, 1'b1, tag}; // shouldn't ever be true, go directly to allocate ? 
                        mesi_s : begin
                            // t_write_en[way_index] = 1'b1; 
                            tag_in[way_index] = {mesi_m, 1'b1, tag};
                            mask_ufp_resp = 1'b1;
                        end
                        mesi_e : begin 
                            tag_in[way_index] = {mesi_m, 1'b1, tag};
                            mask_ufp_resp = 1'b1;
                        end
                        mesi_m : tag_in[way_index] = {mesi_m, 1'b1, tag};
                    endcase
                    
                    t_write_en[way_index] = 1'b1;

                    if(ufp_addr == this_address_locked_by_you && amo) unlock = 1'b1;

                    if(amo) ufp_rdata = 32'h0000_0000;

                end

                ufp_resp = mask_ufp_resp ? 1'b0 : 1'b1;
                load_lru = 1'b1;
            end

            in_compare = 1'b1;

        end

        acquire_bus_write : begin
            snoop_bus_query = 1'b1;
        end

        broadcast_write : begin
            bus_command_address = ufp_addr;
            bus_command_command = pr_wr;
            // bus_command_data = data_out[way_hit];                                                                                                                                                                         
        end 

        allocate : begin

            dfp_read = 1'b1;
            dfp_addr = {ufp_addr[31:5], 5'b0};

            if (dfp_resp) begin
                
                cache_wmask = '1;
                data_in[PLRU_way] = dfp_rdata;
                d_write_en[PLRU_way] = 1'b1;
                tag_in[PLRU_way] = {mesi_e, 1'b0, tag};
                t_write_en[PLRU_way] = 1'b1;

                v_write_en[PLRU_way] = 1'b1;

            end
        end

        acquire_bus_read : begin
            snoop_bus_query = 1'b1;
        end

        bus_read : begin
            bus_command_address = ufp_addr;
            bus_command_command = bus_rd;
            // bus_command_data = 'x;                                                                                                                                                                         
        end

        stall : ;

        write_back : begin

            dfp_write = 1'b1;
            dfp_addr  = {tag_out[PLRU_way][22:0], set_index, 5'b0};
            dfp_wdata = data_out[PLRU_way];
            in_writeBack = 1'b1;

        end
    endcase

    if(rst) begin
        tag_in[0] = '0;
        tag_in[1] = '0;
        tag_in[2] = '0;
        tag_in[3] = '0;

        t_write_en[0] = 1'b1;
        t_write_en[1] = 1'b1;
        t_write_en[2] = 1'b1;
        t_write_en[3] = 1'b1;

    end

end

// logic bus_cache_hit;
logic [3:0] bus_way_hit;
logic [1:0] bus_way_index;

always_comb begin : cache_hit_logic_bus_port

    bus_out_cache_dirty = 1'b0;

    tag_in1[0] = '0;
    tag_in1[1] = '0;
    tag_in1[2] = '0;
    tag_in1[3] = '0;

    t_write_en1[0] = 1'b0;
    t_write_en1[1] = 1'b0;
    t_write_en1[2] = 1'b0;
    t_write_en1[3] = 1'b0;

    bus_data_out = '0;
    
    data_in1[0] = '0; 
    data_in1[1] = '0;
    data_in1[2] = '0;
    data_in1[3] = '0;

    d_write_en1[0] = 1'b0;
    d_write_en1[1] = 1'b0;
    d_write_en1[2] = 1'b0;
    d_write_en1[3] = 1'b0;

    v_write_en1[0] = 1'b0;
    v_write_en1[1] = 1'b0;
    v_write_en1[2] = 1'b0;
    v_write_en1[3] = 1'b0;

    bus_way_hit[0] = (tag_out1[0][22:0] == bus_incomming_command_address[31:9]) && valid_out1[0] && tag_out1[0][25:24] != 2'b00;
    bus_way_hit[1] = (tag_out1[1][22:0] == bus_incomming_command_address[31:9]) && valid_out1[1] && tag_out1[1][25:24] != 2'b00;
    bus_way_hit[2] = (tag_out1[2][22:0] == bus_incomming_command_address[31:9]) && valid_out1[2] && tag_out1[2][25:24] != 2'b00;
    bus_way_hit[3] = (tag_out1[3][22:0] == bus_incomming_command_address[31:9]) && valid_out1[3] && tag_out1[3][25:24] != 2'b00;

    bus_cache_hit = bus_incomming_command_address != '0 ? bus_way_hit[0] | bus_way_hit[1] | bus_way_hit[2] | bus_way_hit[3] : 1'b0;

    if (bus_way_hit[0] == 1'b1)      bus_way_index = 2'b00;
    else if (bus_way_hit[2] == 1'b1) bus_way_index = 2'b10;
    else if (bus_way_hit[1] == 1'b1) bus_way_index = 2'b01;
    else if (bus_way_hit[3] == 1'b1) bus_way_index = 2'b11;
    else bus_way_index = 'x;


    if (state != broadcast_write && state != bus_read) begin
        
        if (bus_cache_hit) begin

            if (bus_incomming_command_command == 3'b010) begin

                t_write_en1[bus_way_index] = 1'b1;
                tag_in1[bus_way_index][25:24] = mesi_i;

            end

            else if (bus_incomming_command_command == bus_rd) begin

                t_write_en1[bus_way_index] = 1'b1;
                tag_in1[bus_way_index] = tag_out1[bus_way_index][23] == 1'b1 ? {mesi_i, tag_out1[bus_way_index][23], bus_resp_addr[31:9]} : {mesi_s, tag_out1[bus_way_index][23], bus_resp_addr[31:9]};
                bus_data_out = data_out1[bus_way_index];
                bus_out_cache_dirty = tag_out1[bus_way_index][23];


            end
        end
    end else if (state == bus_read && bus_incomming_command_command == bus_rd && bus_resp == 2'b01) begin
        data_in1[PLRU_way] = bus_resp_data;
        d_write_en1[PLRU_way] = 1'b1;
        t_write_en1[PLRU_way] = 1'b1;
        tag_in1[PLRU_way] = {mesi_s, bus_in_cache_dirty, ufp_addr[31:9]};
        v_write_en1[PLRU_way] = 1'b1;
    end
end

generate for (genvar i = 0; i < 4; i++) begin : arrays
    mp_cache_data_array data_array (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (!d_write_en[i]),
        .wmask0     (cache_wmask),
        .addr0      (set_index),
        .din0       (data_in[i]),
        .dout0      (data_out[i]),
        
        .clk1       (clk),
        .csb1       (1'b0),
        .web1       (!d_write_en1[i]),
        .wmask1     ('1),
        .addr1      (bus_incomming_command_address[8:5]),
        .din1       (data_in1[i]),
        .dout1      (data_out1[i])
    );
    mp_cache_tag_array tag_array (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (!t_write_en[i]),
        .addr0      (set_index),
        .din0       (tag_in[i]),
        .dout0      (tag_out[i]),

        .clk1       (clk),
        .csb1       (1'b0),
        .web1       (!t_write_en1[i]),
        .addr1      (bus_incomming_command_address[8:5]),
        .din1       (tag_in1[i]),
        .dout1      (tag_out1[i])
    );
    ff_array1 #(.WIDTH(1)) valid_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (!v_write_en[i]),
        .addr0      (set_index),
        .din0       (1'b1),
        .dout0      (valid_out[i]),
        .web1       (!v_write_en1[i]),
        .addr1      (bus_incomming_command_address[8:5]),
        .din1       (1'b1),
        .dout1      (valid_out1[i])
    );
end endgenerate

ff_array #(.WIDTH(3)) lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (!load_lru),
        .addr0      (set_index),
        .din0       (lru_in),
        .dout0      (lru_out)
    );


endmodule