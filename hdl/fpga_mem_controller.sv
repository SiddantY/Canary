module fpga_mem_controller(
    input   logic clk,
    input   logic rst,

    input logic   [31:0]      bmem_addr,
    input logic               bmem_read,
    input logic               bmem_write,
    input logic   [63:0]      bmem_wdata,
    
    output logic               bmem_ready,
    output logic   [31:0]      bmem_raddr,
    output logic   [63:0]      bmem_rdata,
    output logic               bmem_rvalid
);


    



endmodule