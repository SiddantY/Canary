module cache_unit 
(
    input logic clk, rst, 

    /* cache <---> fetch */
    input logic [31:0]  imem_addr,
    input logic [3:0]   imem_rmask,
    output logic [31:0]  imem_rdata,
    output logic imem_resp,

    input logic [31:0]  dmem_addr,
    input logic [3:0]   dmem_rmask, dmem_wmask,
    output logic [31:0]  dmem_rdata, 
    input logic [31:0] dmem_wdata,
    output logic dmem_resp,

    /* cache <---> bmem */
    output logic   [31:0]     bmem_addr,
    output logic              bmem_read,
    output logic              bmem_write,
    output logic   [63:0]     bmem_wdata,
    input logic               bmem_ready,

    // input logic   [31:0]      bmem_raddr,
    input logic   [63:0]      bmem_rdata,
    input logic               bmem_rvalid
);
    

    logic [31:0] ufp_rdata;
    //assign imem_rdata = ufp_rdata[255:224];
    assign imem_rdata = ufp_rdata;
    /* I-cache -> memory port signals */
    logic [31:0]  dfp_addr_i;
    logic dfp_read_i;
    logic [255:0] dfp_rdata_i;
    logic dfp_resp_i;

    /* D-cache -> memory port signals */
    logic [31:0]  dfp_addr_d;
    logic dfp_read_d, dfp_write_d;
    logic [255:0] dfp_rdata_d, dfp_wdata_d;
    logic dfp_resp_d;

    logic [2:0] bmem_state, bmem_state_next; 
    logic [255:0] dfp_rdata_d_reg, dfp_rdata_d_reg_next;
    logic [255:0] dfp_rdata_i_reg, dfp_rdata_i_reg_next;
   
    logic service_i, service_i_next;
    logic service_d, service_d_next;
    logic shadow_service;
    logic one_cycle_read, one_cycle_read_next; 

    always_ff @(posedge clk)begin
        shadow_service <= (service_d_next || service_i_next);
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            bmem_state <= '0;
            dfp_rdata_d_reg <= '0;
            dfp_rdata_i_reg <= '0;
            // real_bmem_read <= '0;
            service_i <= '0;
            service_d <= '0;
            one_cycle_read <= '0;
        end
        else begin
            dfp_rdata_d_reg <= dfp_rdata_d_reg_next;
            dfp_rdata_i_reg <= dfp_rdata_i_reg_next;
            bmem_state <= bmem_state_next;
            service_i <= service_i_next;
            service_d <= service_d_next;
            one_cycle_read <= one_cycle_read_next;
        end
    end

    always_comb begin
        service_i_next = service_i;
        service_d_next = service_d;
        one_cycle_read_next = '0;
        if(dfp_read_i && !service_d) begin
            service_i_next = 1'b1;
            one_cycle_read_next = 1'b1;
        end
        else if((dfp_read_d || dfp_write_d) && !service_i) begin
            service_d_next = 1'b1;
            one_cycle_read_next = 1'b1;
        end
        if(shadow_service) one_cycle_read_next = 1'b0;
        if(bmem_state == 3'd4) begin
            if(service_i) begin
                service_i_next = 1'b0;
            end
            else if(service_d) begin
                service_d_next = 1'b0;
            end
        end
    end 

    // CACHE TO BMEM ARBITER
    always_comb begin
        bmem_write = '0;
        bmem_addr = '0;
        bmem_wdata = '0;
        bmem_state_next = bmem_state;
        dfp_rdata_d_reg_next = dfp_rdata_d_reg;
        dfp_rdata_i_reg_next = dfp_rdata_i_reg;
        dfp_resp_i = 1'b0;
        dfp_resp_d = 1'b0;
        dfp_rdata_d = '0;
        dfp_rdata_i = '0;
        bmem_read = one_cycle_read;
        if(bmem_ready) begin
            if(service_d) begin
                if(dfp_read_d) begin
                    bmem_addr = dfp_addr_d;
                    bmem_write = 1'b0;
                    bmem_wdata = '0;
                    if(bmem_rvalid) begin
                        bmem_state_next = bmem_state + 1'b1;
                        dfp_rdata_d_reg_next[bmem_state*64+:64] = bmem_rdata;
                    end
                end
                if(dfp_write_d) begin
                    bmem_addr = dfp_addr_d;
                    bmem_write = 1'b1;
                    bmem_read = 1'b0;
                    bmem_wdata = dfp_wdata_d[bmem_state*64+:64];
                    bmem_state_next = bmem_state + 1'b1;
                end
                if(bmem_state == 3'd4) begin
                    dfp_resp_d = 1'b1;
                    dfp_rdata_d = dfp_rdata_d_reg;
                    bmem_state_next = '0;
                    bmem_write = '0;
                end
            end
            if(service_i) begin
                bmem_addr = dfp_addr_i;
                bmem_write = 1'b0;
                // bmem_read = real_bmem_read;
                bmem_wdata = '0;
                if(bmem_rvalid) begin
                    bmem_state_next = bmem_state + 1'b1;
                    dfp_rdata_i_reg_next[bmem_state*64+:64] = bmem_rdata;
                end
                if(bmem_state == 3'd4) begin
                    bmem_state_next = '0;
                    dfp_resp_i = 1'b1;
                    dfp_rdata_i = dfp_rdata_i_reg;
                end
            end
        end
    end

    I_CACHE I_CACHE( 
        .clk        (clk), 
        .rst        (rst),
        .ufp_addr   (imem_addr),
        .ufp_rmask  (imem_rmask),
        .ufp_rdata  (ufp_rdata),
        .ufp_resp   (imem_resp),

        .dfp_addr   (dfp_addr_i),
        .dfp_read   (dfp_read_i),
        .dfp_rdata  (dfp_rdata_i),
        .dfp_resp   (dfp_resp_i)
    );

    D_CACHE D_CACHE( 
        .clk        (clk),
        .rst        (rst),
        .ufp_addr   (dmem_addr),
        .ufp_rmask  (dmem_rmask),
        .ufp_wmask  (dmem_wmask),
        .ufp_rdata  (dmem_rdata),
        .ufp_wdata  (dmem_wdata),
        .ufp_resp   (dmem_resp),

        .dfp_addr   (dfp_addr_d),
        .dfp_read   (dfp_read_d),
        .dfp_write  (dfp_write_d),
        .dfp_rdata  (dfp_rdata_d),
        .dfp_wdata  (dfp_wdata_d),
        .dfp_resp   (dfp_resp_d)
    );

endmodule : cache_unit