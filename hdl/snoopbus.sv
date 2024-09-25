module snoopbus
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
// module snoopbus (
//     input   logic           clk,
//     input   logic           rst,

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
//     // output  logic           ooo_d_write_en[4],
//     // output  logic   [31:0]  ooo_d_cache_wmask,
//     // input   logic   [255:0] ooo_d_data_in[4],
//     // output  logic   [255:0] ooo_d_data_out[4],

    input   logic   [31:0]  ooo_d_addr,
    input   logic   [2:0]   ooo_d_command,
    input   logic   [255:0] ooo_d_data,
//     // input   logic   [31:0]  ooo_d_addr,
//     // output  logic   [3:0]   ooo_d_set_index,

//     // output  logic           ooo_d_tag_we[4],
//     // input   logic   [23:0]  ooo_d_tag_in[4],
//     // output  logic   [23:0]  ooo_d_tag_out[4],

    input   logic           ooo_d_bus_query,

    input   logic   [255:0] ooo_d_bus_data,
//     // input   logic   [1:0]   ooo_d_operation,

//     // output  logic           ppl_d_write_en[4],
//     // output  logic   [31:0]  ppl_d_cache_wmask,
//     // input   logic   [255:0] ppl_d_data_in[4],
//     // output  logic   [255:0] ppl_d_data_out[4],

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
//     // input   logic   [31:0]  ppl_d_addr,
//     // output  logic   [3:0]   ppl_d_set_index,

//     // input   logic   [1:0]   ppl_d_operation,

//     // output  logic           ppl_d_tag_we[4],
//     // input   logic   [23:0]  ppl_d_tag_in[4],
//     // output  logic   [23:0]  ppl_d_tag_out[4] 

//     // input   logic           ooo_d_bus_query,
//     // input   logic           ppl_d_bus_query,

    output  logic           bus_ready,
    output  logic   [1:0]   bus_resp  // 0 is no resp, 1 is hit 2 is miss   
);
//     input   logic   [31:0]  ooo_d_address,
//     input   logic   [1:0]   ooo_d_command,
//     input   logic   [255:0] ooo_d_data,

//     input   logic           ooo_d_bus_query,

//     input   logic   [31:0]  ppl_d_address,
//     input   logic   [1:0]   ppl_d_command,
//     input   logic   [255:0] ppl_d_data,

//     input   logic           ppl_d_bus_query,

//     output  logic   [31:0]  bus_command_address,
//     output  logic   [1:0]   bus_command_command,
//     output  logic   [255:0] bus_command_data,

//     input   logic   [31:0]  bus_resp_address,
//     input   logic   [1:0]   bus_resp_command,
//     input   logic   [255:0] bus_resp_data,
//     input   logic           bus_resp_hit,

//     output  logic           bus_ready,
//     output  logic   [1:0]   bus_resp  // 0 is no resp, 1 is hit 2 is miss   
// );

enum int unsigned {
    bus_free,
    bus_serving_ooo_d,
    bus_serving_ooo_d_response,
    bus_serving_ppl_d,
    bus_serving_ppl_d_response
} state, bus_next_state;
// enum int unsigned {
//     bus_free,
//     bus_serving_ooo_d,
//     bus_serving_ooo_d_response,
//     bus_serving_ppl_d
//     bus_serving_ppl_d_respnose
// } bus_state, bus_next_state;

// always_ff @(posedge clk) begin : bus_state_machine
    
    if(rst) begin
        state <= bus_free;
    end else begin
        state <= bus_next_state;
    end
//     if(rst) begin
//         bus_state <= bus_free;
//     end else begin
//         bus_state <= bus_next_state;
//     end

// end

always_comb begin : bus_state_next

    bus_next_state = bus_free;

    case (state)
// always_comb begin : bus_state_next
//     case (state)

//         bus_free : begin

//             if(ooo_d_bus_query) bus_next_state = bus_serving_ooo_d;
//             else if(ppl_d_bus_query) bus_next_state = bus_serving_ppl_d;
//             else bus_next_state = bus_free;

//         end

//         bus_serving_ooo_d : begin
//             bus_next_state = bus_serving_ooo_d_response;
//         end

        bus_serving_ooo_d_response : begin
            bus_next_state = bus_free;
        end
//         bus_serving_ooo_d_response : begin
//             bus_next_state = bus_free;
//         end

//         bus_serving_ppl_d : begin
//             bus_next_state = bus_serving_ppl_d_response;
//         end

        bus_serving_ppl_d_response : begin
            bus_next_state = bus_free;
        end
//         bus_serving_ooo_d_response : begin
//             bus_next_state = bus_free;
//         end

//     endcase
// end : bus_state_next

// always_comb begin : bus_outgoing_signals

    bus_resp = '0;
    bus_ready = '0;
    bus_command_address = '0;
    bus_command_command = '0;
    bus_command_data    = '0;
//     bus_resp = '0;
//     bus_ready = '0;

    bus_resp_address    = '0;
    bus_resp_command    = '0;
    bus_resp_data       = '0;
//     if(state == bus_free) bus_ready = 1'b1;

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
//     if(state == bus_serving_ooo_d) begin
//         bus_command_address = ooo_d_addr;
//         bus_command_command = ooo_d_command;
//     end

//     if(state == bus_serving_ooo_d_response) begin
//         bus_command_address = ooo_d_addr;
//         bus_command_command = ooo_d_command;
//         bus_command_data = bus_resp_hit ? bus_resp_data : '0;
//         bus_resp = bus_resp_hit ? 2'b01 : 2'b10;
//     end

//     if(state == bus_serving_ppl_d) begin
//         bus_command_address = ppl_d_addr;
//         bus_command_command = ppl_d_command;
//     end

//     if(state == bus_serving_ppl_d_response) begin
//         bus_command_address = ppl_d_addr;
//         bus_command_command = ppl_d_command;
//         bus_command_data = bus_resp_hit ? bus_resp_data : '0;
//         bus_resp = bus_resp_hit ? 2'b01 : 2'b10;
//     end

//     // if(state == bus_serving_ooo_d_response) begin
//     //     // Hit Logic
        
//     //     // Operations
//     //     case(ooo_d_operation)
//     //         2'b00: begin // Pr Read
//     //             if(ppl_d_cache_hit) begin
//     //                 bus_resp = 2'b01; // hit
//     //                 case (ppl_d_data_in[ppl_d_way_index][25:24])
//     //                     2'b00: bus_resp = 2'b10;    // I :  Bus Resp is 'Miss'
//     //                     2'b01: begin                // S :  Pull Data
//     //                         ooo_d_data_in[@way_index] = ppl_d_data_out[ppl_d_way_index];
//     //                         ooo_d_write_en[@way_index] = 1'b1;

//     //                         ooo_d_tag_in[@way_index][25:24] = 2'b01;
//     //                         ooo_d_tag_we[@way_index];
//     //                     end
//     //                     2'b10: begin            
                                
//     //                     end                    
//     //                     2'b11: // M
//     //                 endcase
//     //             end else begin
//     //                 bus_resp = 2'b10; // miss
//     //             end
//     //         end
//     //         2'b01: begin
//     //         end // Pr Wr
//     //         2'b10: begin
//     //         end // Bus Read
//     //         2'b11 begin
//     //         end // Bus ReadX
//     //     endcase
//     // end

// end

// logic ppl_d_cache_hit;
// logic [3:0] ppl_d_way_hit;
// logic [1:0] ppl_d_way_index;

// always_comb begin : cache_hit_logic

//     ppl_d_way_hit[0] = (ppl_d_tag_in[0][22:0] == ooo_d_addr[31:9]) && ppl_d_data_in[0][25:24] > 2'b00;
//     ppl_d_way_hit[1] = (ppl_d_tag_in[1][22:0] == ooo_d_addr[31:9]) && ppl_d_data_in[1][25:24] > 2'b00;
//     ppl_d_way_hit[2] = (ppl_d_tag_in[2][22:0] == ooo_d_addr[31:9]) && ppl_d_data_in[2][25:24] > 2'b00;
//     ppl_d_way_hit[3] = (ppl_d_tag_in[3][22:0] == ooo_d_addr[31:9]) && ppl_d_data_in[3][25:24] > 2'b00;
    
//     ppl_d_cache_hit = ppl_d_way_hit[0] | ppl_d_way_hit[1] | ppl_d_way_hit[2] | ppl_d_way_hit[3];

//     if (ppl_d_way_hit[0] == 1'b1)      ppl_d_way_index = 2'b00;
//     else if (ppl_d_way_hit[2] == 1'b1) ppl_d_way_index = 2'b10;
//     else if (ppl_d_way_hit[1] == 1'b1) ppl_d_way_index = 2'b01;
//     else if (ppl_d_way_hit[3] == 1'b1) ppl_d_way_index = 2'b11;

// end




// // ff_array #(.WIDTH(3)) lru_array (
// //         .clk0       (clk),
// //         .rst0       (rst),
// //         .csb0       (1'b0),
// //         .web0       (!load_lru),
// //         .addr0      (set_index),
// //         .din0       (lru_in),
// //         .dout0      (lru_out)
// //     );


// endmodule
