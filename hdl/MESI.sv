

module MESI 
import cache_types ::*;
(
    input   cache_types_t   [256:0] cacheline_in,
    output  cache_types_t   [256:0] cacheline_out,
    input   logic           [1:0]   pr_states[1:0],
    input   logic                   PrRd, 
    input   logic                   PrWr,
    output  logic                   BusRd,
    output  logic                   BusRdX,
    output  logic                   BusUpgr,
    output  logic                   Flush,
    output  logic                   FlushOpt
); 

    enum logic [1:0] {
    modified, 
    exclusive, 
    shared, 
    invalid
    } state, state_next;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= invalid;
        end else begin
            state <= state_next;
            if(PrRd | PrWr) begin//if any processor issues new request
                state <= cacheline_in.mesi_state;                
            end
        end
    end

    always_comb begin
        state_next = invalid;
        unique case(state)
            invalid: begin
                
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