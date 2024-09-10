

module MESI 
import cache_types ::*;
(
    input   cache_types_t [256:0] r_cacheline_in,//requestor cacheline
    output  cache_types_t [256:0] r_cacheline_out,
    input   cache_types_t [256:0] s_cacheline_in,//snooping cacheline
    output  logic [1:0] r_cache_state,//?
    input   logic s_cache_valid,//ack bit for sending snoop_cache_state
    input   logic PrRd, 
    input   logic PrWr,
    output  logic BusRd,
    output  logic BusRdX,
    output  logic BusUpgr,
    output  logic Flush,
    input   logic  FlushOpt//Cache to Cache Transfers
    inpur 
); 

    logic [1:0] state, state_next;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= invalid;
        end else begin
            state <= state_next;
            if(PrRd | PrWr) begin//if any processor issues new request
                state <= r_cacheline_in.mesi_state;                
            end
        end
    end

    always_comb begin : FSM_logic
        state_next = invalid;
        r_cache_state = r_cacheline_in.mesi_state;
        BusRd = '0;
        BusRdX = '0;
        BusUpgr = '0;
        Flush = '0;
        FlushOpt = '0;
        unique case(state)
            invalid: begin
                if(PrRd) begin
                    BusRd = 1'b1;
                    if(s_cache_valid) begin
                        if()
                    end
                end else if(PrWr) begin

                end
            end
            exclusive: begin
            
            end
            shared: begin
            
            end
            modified: begin
                
            end
        endcase 
    end
endmodule