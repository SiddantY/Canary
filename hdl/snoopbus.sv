module snoopbus
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // output  logic           ooo_d_write_en[4],
    // output  logic   [31:0]  ooo_d_cache_wmask,
    // input   logic   [255:0] ooo_d_data_in[4],
    // output  logic   [255:0] ooo_d_data_out[4],

    // input   logic   [31:0]  ooo_d_addr,
    // output  logic   [3:0]   ooo_d_set_index,

    // output  logic           ooo_d_tag_we[4],
    // input   logic   [23:0]  ooo_d_tag_in[4],
    // output  logic   [23:0]  ooo_d_tag_out[4],

    // input   logic   [1:0]   ooo_d_operation,

    // output  logic           ppl_d_write_en[4],
    // output  logic   [31:0]  ppl_d_cache_wmask,
    // input   logic   [255:0] ppl_d_data_in[4],
    // output  logic   [255:0] ppl_d_data_out[4],

    // input   logic   [31:0]  ppl_d_addr,
    // output  logic   [3:0]   ppl_d_set_index,

    // input   logic   [1:0]   ppl_d_operation,

    // output  logic           ppl_d_tag_we[4],
    // input   logic   [23:0]  ppl_d_tag_in[4],
    // output  logic   [23:0]  ppl_d_tag_out[4] 

    // input   logic           ooo_d_bus_query,
    // input   logic           ppl_d_bus_query,

    input   logic   [31:0]  ooo_d_addr,
    input   logic   [2:0]   ooo_d_command,
    input   logic   [255:0] ooo_d_data,

    input   logic           ooo_d_bus_query,

    input   logic   [255:0] ooo_d_bus_data,

    input   logic   [31:0]  ppl_d_addr,
    input   logic   [2:0]   ppl_d_command,
    input   logic   [255:0] ppl_d_data,

    input   logic           ppl_d_bus_query,

    input   logic   [255:0] ppl_d_bus_data,

    output  logic   [31:0]  bus_command_address,
    output  logic   [2:0]   bus_command_command,
    output  logic   [255:0] bus_command_data,

    output  logic   [31:0]  bus_resp_address,
    output  logic   [2:0]   bus_resp_command,
    output  logic   [255:0] bus_resp_data,

    input   logic           ppl_cache_hit,
    input   logic           ooo_cache_hit,

    output  logic           bus_ready,
    output  logic   [1:0]   bus_resp  // 0 is no resp, 1 is hit 2 is miss   
);

enum int unsigned {
    bus_free,
    bus_serving_ooo_d,
    bus_serving_ooo_d_response,
    bus_serving_ppl_d,
    bus_serving_ppl_d_response
} state, bus_next_state;

always_ff @(posedge clk) begin : bus_state_machine
    
    if(rst) begin
        state <= bus_free;
    end else begin
        state <= bus_next_state;
    end

end

always_comb begin : bus_state_next

    bus_next_state = bus_free;

    case (state)

        bus_free : begin

            if(ooo_d_bus_query) bus_next_state = bus_serving_ooo_d;
            else if(ppl_d_bus_query) bus_next_state = bus_serving_ppl_d;
            else bus_next_state = bus_free;

        end

        bus_serving_ooo_d : begin
            bus_next_state = bus_serving_ooo_d_response;
        end

        bus_serving_ooo_d_response : begin
            bus_next_state = bus_free;
        end

        bus_serving_ppl_d : begin
            bus_next_state = bus_serving_ppl_d_response;
        end

        bus_serving_ppl_d_response : begin
            bus_next_state = bus_free;
        end

    endcase
end : bus_state_next

always_comb begin : bus_outgoing_signals

    bus_resp = '0;
    bus_ready = '0;
    bus_command_address = 'x;
    bus_command_command = '0;
    bus_command_data    = '0;

    bus_resp_address    = '0;
    bus_resp_command    = '0;
    bus_resp_data       = '0;

    if(state == bus_free) begin
        bus_ready = 1'b1;
    end

    if(state == bus_serving_ooo_d) begin

        bus_command_address = ooo_d_addr;
        bus_command_command = ooo_d_command;
        bus_command_data = ooo_d_data;

    end

    if(state == bus_serving_ooo_d_response) begin

        bus_command_address = ooo_d_addr;
        bus_command_command = ooo_d_command;
        bus_command_data = ooo_d_data;

        bus_resp_address = ooo_d_addr;
        bus_resp_command = ooo_d_command;
        bus_resp_data = ppl_d_bus_data;

        bus_resp = ppl_cache_hit ? 2'b01 : 2'b10;

    end

    if(state == bus_serving_ppl_d) begin

        bus_command_address = ppl_d_addr;
        bus_command_command = ppl_d_command;
        bus_command_data = ppl_d_data;

    end

    if(state == bus_serving_ppl_d_response) begin

        bus_command_address = ppl_d_addr;
        bus_command_command = ppl_d_command;
        bus_command_data = ppl_d_data;

        // bus_resp_address = tag_out_ppl;
        bus_resp_command = ppl_d_command;
        bus_resp_data = ooo_d_bus_data;
        
        bus_resp = ooo_cache_hit ? 2'b01 : 2'b10;
    end

end

endmodule