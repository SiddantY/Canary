module snoopbus (
    input   logic           clk,
    input   logic           rst,

    output  logic           ooo_d_write_en[4],
    output  logic   [31:0]  ooo_d_cache_wmask,
    input   logic   [255:0] ooo_d_data_in[4],
    output  logic   [255:0] ooo_d_data_out[4],

    input   logic   [31:0]  ooo_d_addr,
    output  logic   [3:0]   ooo_d_set_index,

    output  logic           ooo_d_tag_we[4],
    input   logic   [23:0]  ooo_d_tag_in[4],
    output  logic   [23:0]  ooo_d_tag_out[4],

    input   logic   [1:0]   ooo_d_operation,

    output  logic           ppl_d_write_en[4],
    output  logic   [31:0]  ppl_d_cache_wmask,
    input   logic   [255:0] ppl_d_data_in[4],
    output  logic   [255:0] ppl_d_data_out[4],

    input   logic   [31:0]  ppl_d_addr,
    output  logic   [3:0]   ppl_d_set_index,

    input   logic   [1:0]   ppl_d_operation,

    output  logic           ppl_d_tag_we[4],
    input   logic   [23:0]  ppl_d_tag_in[4],
    output  logic   [23:0]  ppl_d_tag_out[4] 

    input   logic           ooo_d_bus_query,
    input   logic           ppl_d_bus_query,

    output  logic           bus_ready,
    output  logic           bus_resp,  
);

enum int unsigned {
    bus_free,
    bus_serving_ooo_d,
    bus_serving_ppl_d
} bus_state, bus_next_state;

always_ff @(posedge clk) begin : bus_state_machine
    
    if(rst) begin
        bus_state <= bus_free;
    end else begin
        bus_state <= bus_next_state;
    end

end

always_comb begin : bus_state_next
    case (state)

        bus_free : begin

            if(ooo_d_bus_query) bus_next_state = bus_serving_ooo_d;
            else if(ppl_d_bus_query) bus_next_state = bus_serving_ppl_d;
            else bus_next_state = bus_free;

        end

        bus_serving_ooo_d : begin
            if(bus_resp) bus_next_state = bus_free;
            else bus_next_state = bus_serving_ooo_d;
        end

        bus_serving_ppl_d : begin
            if(bus_resp) bus_next_state = bus_free;
            else bus_next_state = bus_serving_ppl_d;
        end

    endcase
end : bus_state_next


endmodule