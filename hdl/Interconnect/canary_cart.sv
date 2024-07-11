module canary_cart
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input l1_to_cc_t ecore_in,
    input l1_to_cc_t pcore_in,
    input cc_to_mem_t cc_to_mem,
    output cc_to_l1_t ecore_out,
    output cc_to_l1_t ecore_out,
    output mem_to_cc_t mem_to_cc
    
)

endmodule : canary_cart