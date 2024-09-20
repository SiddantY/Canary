module fpga_mem_controller(
    input   logic clk,
    input   logic rst,

    // Caches -> Controller
    // input logic   [31:0]      bmem_addr,
    // input logic               bmem_read,
    // input logic               bmem_write,
    // input logic   [63:0]      bmem_wdata,
    
    // // Controller -> Caches
    // output logic               bmem_ready,
    // output logic   [31:0]      bmem_raddr,
    // output logic   [63:0]      bmem_rdata,
    // output logic               bmem_rvalid,

    // Memory -> Controller
    input logic [63:0] address_data_bus_m_to_c,
    input logic resp_m_to_c,

    // Controller -> Memory
    output logic [63:0] address_data_bus_c_to_m,
    output logic address_on_c_to_m,
    output logic data_on_c_to_m,
    output logic read_en_c_to_m,
    output logic write_en_c_to_m
);


    always_ff @(posedge clk) begin
        if(rst) begin
           address_data_bus_c_to_m <= 64'hECEBCAFEDEADBEEF;
           address_on_c_to_m <= 1'b0;
           data_on_c_to_m <= 1'b0;
           read_en_c_to_m <= 1'b0;
           write_en_c_to_m <= 1'b0;
        end
    end

    



endmodule