module pipeline_regfile
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we,
    input   logic   [31:0]  rd_v,
    input   logic   [4:0]   rs1_s, rs2_s, rd_s,
    output  logic   [31:0]  rs1_v, rs2_v,
    output  logic   [31:0]  data[32],

    input   logic           hardware_scheduler_swap_pc,
    input   logic   [31:0]  ooo_data[NUM_REGS],
    input logic [$clog2(NUM_REGS)-1:0] rrf_arch_to_physical[32]
);

    // logic   [31:0]  data [32];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                data[i] <= '0;
            end
        end else if (hardware_scheduler_swap_pc) begin
            for(int i = 0; i < 32; i++) begin
                data[i] <= ooo_data[rrf_arch_to_physical[i]];
            end
        end else if (regf_we && (rd_s != 5'd0)) begin
            data[rd_s] <= rd_v;
        end
    end

    always_comb
        begin
            rs1_v = (rs1_s != 5'd0) ? data[rs1_s] : '0;
            rs2_v = (rs2_s != 5'd0) ? data[rs2_s] : '0;
        end

endmodule : pipeline_regfile