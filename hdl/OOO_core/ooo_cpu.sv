module ooo_cpu
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [63:0]  imem_rdata,
    input   logic           imem_resp,

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [63:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp
    
    // output logic   [31:0]      bmem_addr,
    // output logic               bmem_read,
    // output logic               bmem_write,
    // output logic   [63:0]      bmem_wdata,
    // input logic               bmem_ready,

    // input logic   [31:0]      bmem_raddr,
    // input logic   [63:0]      bmem_rdata,
    // input logic               bmem_rvalid
    
);


endmodule : ooo_cpu
