

module MESI 
import cache_types ::*;
(
    input   cache_types_t [256:0] s_cacheline_in,//snooping cacheline
    input   cache_types_t [256:0] r_cacheline_in,//requestor cacheline
    input   logic [1:0] snoop_cache_state,
    output  logic [1:0] r_cache_state_next,
    output  logic [1:0] s_cache_state_next,
    input   logic s_cache_valid,//ack bit for sending snoop_cache_state
    input   logic s_cache_match,//ack bit for other cache having valid copy
    input   logic PrRd, 
    input   logic PrWr,
    output  logic BusRd,
    output  logic BusRdX,
    output  logic BusUpgr,
    output  logic Flush,
    input   logic  FlushOpt,//Cache to Cache Transfers
    output  logic  adaptor_en//enable adaptor (also update )  
); 


/*
======
States
======

Modified:   Data has been written to one cores cache and is DIFFERENT from the data in main memory
Exclusive:  Data is only present in the one cores caches and MATCHES main memory 
Shared:     Data is present in multiple cores' caches and MATCHES main memory
Invalid:    Data no valid copy of data


*/
    logic [1:0] state, state_next;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= invalid;
        end else begin
            state <= state_next;
            if(PrRd | PrWr) begin//if any processor issues new request (may need arbitration)
                state <= r_cacheline_in.mesi_state;                
            end
        end
    end

    always_comb begin : FSM_logic
        state_next = invalid;
        BusRd = '0;
        BusRdX = '0;
        BusUpgr = '0;
        Flush = '0;
        FlushOpt = '0;
        adaptor_en = '0;
        r_cache_state_next = invalid;
        unique case(state)
            invalid: begin
                if(PrRd) begin//processor read, de-aserted when ufp_read done
                    BusRd = 1'b1;
                    if(s_cache_valid) begin//check bus results
                        if(s_cache_match && (snoop_cache_state != invalid)) begin//if data match, check snooped data's state
                            unique case(snoop_cache_state)
                                exclusive:begin//forward s_cacheline to r cache, update both cachelines (r and s) to SHARED
                                    FlushOpt = 1'b1;
                                    s_cache_state_next = exclusive;//state_next will be assigned 
                                end
                                shared:begin//forward data, dont update s_cache
                                    FlushOpt = 1'b1;
                                end
                                modified:begin
                                    
                                end
                            endcase
                        end else begin
                            //go to main mem, get cacheline, set cacheline to EXCLUSIVE
                                adaptor_en = 1'b1;
                                r_cache_state_next = exclusive;//assign to allocated cacheline
                            
                        end
                    end else begin//fetch from main mem

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