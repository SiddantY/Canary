// Allen helped me write this
module D_CACHE (
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);
    logic           data_we[4];
    logic   [255:0] data_din[4];
    logic   [255:0] data_dout[4];
    logic   [31:0]  ufp_wmask_32bit;
    logic   [255:0] data_wmask;
    logic   [3:0]   tag_match;
    logic   [1:0]   hit_way;

    logic           tag_we[4];
    logic   [23:0]  tag_din[4];
    logic   [23:0]  tag_dout[4];

    logic           valid_we[4];
    logic           valid_in[4];
    logic           valid_out[4];    

    logic   [2:0]   plru_array[16], plru_array_next[16];

    logic   [1:0]   way_select;
    logic   [4:0]   ufp_offset;
    logic   [3:0]   set_index;
    logic   [22:0]  tag_bits;

    logic   [1:0]   plru_idx;

    assign ufp_offset = ufp_addr[4:0];
    assign tag_bits = ufp_addr[31:9];

    assign set_index = ufp_addr[8:5];
    assign ufp_wmask_32bit = {{8{ufp_wmask[3]}}, {8{ufp_wmask[2]}}, {8{ufp_wmask[1]}}, {8{ufp_wmask[0]}}};
    enum logic [1:0] {idle, comp_tag, wb, alloc}   cache_state, cache_next_state;
    generate for (genvar i = 0; i < 4; i++) begin : arrays
        d_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_we[i]),
            .wmask0     ('1), //use offset and ufpwmask to calculate
            .addr0      (set_index),
            .din0       (data_din[i]),
            .dout0      (data_dout[i])
        );
        d_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (tag_we[i]),
            .addr0      (set_index),
            .din0       (tag_din[i]),
            .dout0      (tag_dout[i])
        );
        ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (valid_we[i]),
            .addr0      (set_index),
            .din0       (valid_in[i]),
            .dout0      (valid_out[i])
        );

    end endgenerate

    always_comb begin   // PLRU
        unique case (plru_array[set_index])
            3'b011 : plru_idx = 2'b00;
            3'b111 : plru_idx = 2'b00;
            3'b001 : plru_idx = 2'b01;
            3'b101 : plru_idx = 2'b01;
            3'b100 : plru_idx = 2'b10;
            3'b110 : plru_idx = 2'b10;
            3'b000 : plru_idx = 2'b11;
            3'b010 : plru_idx = 2'b11;
            default : plru_idx = 2'b00;
        endcase
    end

    // NEXT-STATE/STATE LOGIC
    always_comb begin
        cache_next_state = idle;
        ufp_resp = '0;
        dfp_write = '0;
        dfp_read = '0;
        ufp_rdata = '0;
        dfp_wdata = '0;
        dfp_addr = '0;
        hit_way = 2'b00;
        tag_match = '0;

        for (int i = 0; i < 4; i++) begin
            data_din[i] = '0;    
            data_we[i] = '1;   // read data arrays
            tag_din[i] = '0;
            valid_we[i] = '1;  // set valid array
            valid_in[i] = '0;
            tag_we[i] = '1; //read from tag arrays
        end
        for(int i = 0; i < 16; i++) begin
            plru_array_next[i] = plru_array[i];
        end
        if(rst) begin
            for(int i = 0; i < 16; i++) begin
                plru_array_next[i] = '0;
            end
        end
        
        unique case (cache_state) 
            idle: begin
                if (ufp_rmask != '0 || ufp_wmask != '0) cache_next_state = comp_tag;
                else cache_next_state = idle;
            end
            comp_tag: begin
                for (int i = 0; i < 4; i++) begin
                    valid_we[i] = '1;  // set valid array
                    data_we[i] = '1;   // read data arrays
                    tag_din[i] = '0;
                    tag_din[i][22:0] = tag_dout[i][22:0];

                end
                //check for miss and set tag_match               
                if (tag_dout[0][22:0] == tag_bits && valid_out[0]) begin
                    tag_match = 4'b0001;
                    hit_way = 2'b00;
                end
                else if (tag_dout[1][22:0] == tag_bits && valid_out[1]) begin
                    tag_match = 4'b0010;
                    hit_way = 2'b01;
                end
                else if (tag_dout[2][22:0] == tag_bits && valid_out[2]) begin
                    tag_match = 4'b0100;
                    hit_way = 2'b10;
                end
                else if (tag_dout[3][22:0] == tag_bits && valid_out[3]) begin
                    tag_match = 4'b1000;
                    hit_way = 2'b11;
                end
                else tag_match = 4'b0000;
                // if (valid_out[0] == '0 && valid_out[1] == '0 && valid_out[2] == '0 && valid_out[3] == '0) tag_match = 4'b0000;

                if(tag_match != '0) begin //HIT
                    ufp_resp = '1;
                    // SET PLRU depending on the way that is hit
                    unique case (tag_match) 
                        4'b0001 : plru_array_next[set_index][1:0] = 2'b00;
                        4'b0010 : plru_array_next[set_index][1:0] = 2'b10;
                        4'b0100 : begin
                            plru_array_next[set_index][2] = 1'b0;
                            plru_array_next[set_index][0] = 1'b1;
                        end
                        4'b1000 : begin
                            plru_array_next[set_index][2] = 1'b1;
                            plru_array_next[set_index][0] = 1'b1;
                        end
                        default : ;
                    endcase
                    cache_next_state = idle;
                    if(ufp_rmask != '0) begin   //READ
                        data_we[hit_way] = '1;
                        unique case (ufp_offset[4:2])
                            3'b000: begin
                                ufp_rdata = data_dout[hit_way][31:0];
                            end
                            3'b001: begin
                                ufp_rdata = data_dout[hit_way][63:32];
                            end
                            3'b010: begin
                                ufp_rdata = data_dout[hit_way][95:64];
                            end
                            3'b011: begin
                                ufp_rdata = data_dout[hit_way][127:96];
                            end
                            3'b100: begin
                                ufp_rdata = data_dout[hit_way][159:128];
                            end
                            3'b101: begin
                                ufp_rdata = data_dout[hit_way][191:160];
                            end
                            3'b110: begin
                                ufp_rdata = data_dout[hit_way][223:192];
                            end
                            3'b111: begin
                                ufp_rdata = data_dout[hit_way][255:224];
                            end
                        endcase
                    end
                    else if (ufp_wmask != 0) begin    //WRITE
                        data_we[hit_way] = '0;
                        unique case (ufp_offset[4:2])
                            3'b000: begin
                                data_din[hit_way][31:0] = (ufp_wdata & ufp_wmask_32bit )
                                | (~ufp_wmask_32bit & data_dout[hit_way][31:0]);
                                data_din[hit_way][255:32] = data_dout[hit_way][255:32];
                            end
                            3'b001: begin
                                data_din[hit_way][63:32] = ufp_wdata&ufp_wmask_32bit
                                | (~ufp_wmask_32bit & data_dout[hit_way][63:32]);
                                data_din[hit_way][31:0] = data_dout[hit_way][31:0];
                                data_din[hit_way][255:64] = data_dout[hit_way][255:64];
                            end
                            3'b010: begin
                                data_din[hit_way][95:64] = ufp_wdata&ufp_wmask_32bit
                                | (~ufp_wmask_32bit & data_dout[hit_way][95:64]);
                                data_din[hit_way][63:0] = data_dout[hit_way][63:0];
                                data_din[hit_way][255:96] = data_dout[hit_way][255:96];
                            end
                            3'b011: begin
                                data_din[hit_way][127:96] = ufp_wdata&ufp_wmask_32bit
                                | (~ufp_wmask_32bit & data_dout[hit_way][127:96]);
                                data_din[hit_way][95:0] = data_dout[hit_way][95:0];
                                data_din[hit_way][255:128] = data_dout[hit_way][255:128];
                            end
                            3'b100: begin
                                data_din[hit_way][159:128] = ufp_wdata&ufp_wmask_32bit
                                | (~ufp_wmask_32bit & data_dout[hit_way][159:128] );
                                data_din[hit_way][127:0] = data_dout[hit_way][127:0];
                                data_din[hit_way][255:160] = data_dout[hit_way][255:160];
                            end
                            3'b101: begin
                                data_din[hit_way][191:160] = ufp_wdata&ufp_wmask_32bit
                                | (~ufp_wmask_32bit & data_dout[hit_way][191:160]);
                                data_din[hit_way][159:0] = data_dout[hit_way][159:0];
                                data_din[hit_way][255:192] = data_dout[hit_way][255:192];
                            end
                            3'b110: begin
                                data_din[hit_way][223:192] = ufp_wdata&ufp_wmask_32bit
                                | (~ufp_wmask_32bit & data_dout[hit_way][223:192]);
                                data_din[hit_way][191:0] = data_dout[hit_way][191:0];
                                data_din[hit_way][255:224] = data_dout[hit_way][255:224];
                            end
                            3'b111: begin
                                data_din[hit_way][255:224] = ufp_wdata&ufp_wmask_32bit
                                | (~ufp_wmask_32bit & data_dout[hit_way][255:224]);
                                data_din[hit_way][223:0] = data_dout[hit_way][223:0];
                            end
                        endcase
                        tag_we[hit_way] = '0; 
                        tag_din[hit_way][23] = '1;   // set DIRTY bit
                    end

                end
                else begin // MISS
                    if(tag_dout[plru_idx][23] && valid_out[plru_idx]) cache_next_state = wb;
                    else cache_next_state = alloc;
                end
            end
            wb: begin   // write old cacheline to mem
                dfp_write = '1;
                dfp_wdata = data_dout[plru_idx];    // write cacheline to mem
                dfp_addr = {tag_dout[plru_idx][22:0],set_index,5'b00000};
                if(dfp_resp) cache_next_state = alloc;
                else begin
                    cache_next_state = wb;
                    tag_we[plru_idx] = '1;
                end
            end
            alloc: begin
                valid_we[plru_idx] = '0; // set valid to 1
                valid_in[plru_idx] = '1;
                cache_next_state = alloc;
                dfp_read = '1;
                dfp_addr = {ufp_addr[31:5],5'b00000};
                data_din[plru_idx] = dfp_rdata;
                data_we[plru_idx] = '0; // write to data array
                if(dfp_resp) begin
                    tag_we[plru_idx] = '0;
                    tag_din[plru_idx][22:0] = ufp_addr[31:9];
                    tag_din[plru_idx][23] = '0; // clear DIRTY
                    cache_next_state = idle;
                end
            end
            default: begin
                cache_next_state = idle;
                dfp_write = '0;
                dfp_read = '0;
            end
        endcase
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            cache_state <= idle;
            for (int i = 0; i < 16; i++) begin
                plru_array[i] <= '0;
            end    
        end
        cache_state <= cache_next_state;
        plru_array[set_index] <= plru_array_next[set_index];
    end
endmodule : D_CACHE
