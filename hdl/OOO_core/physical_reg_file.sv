module physical_regfile
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we, regf_we_mul, regf_we_ldst,
    input   logic   [31:0]  rd_v, rd_v_mul, rd_v_ldst,
    input   logic   [$clog2(NUM_REGS)-1:0]   rs1_s, rs2_s, rd_s, rs1_s_mul, rs2_s_mul, rd_s_mul, rs1_s_ldst, rs2_s_ldst, rd_s_ldst,
    output  logic   [31:0]  rs1_v, rs2_v, rs1_v_mul, rs2_v_mul, rs1_v_ldst, rs2_v_ldst
);

    logic   [31:0]  data [NUM_REGS]; // physical regfile of 128 regs :x_x: 

    always_ff @(posedge clk) begin
        if (rst) begin // at reset set every thing to 0
            for (int i = 0; i < NUM_REGS; i++) begin
                data[i] <= '0;
            end
        end else begin

            if (regf_we && (rd_s != 6'd0)) begin
                data[rd_s] <= rd_v;
            end
            
            if (regf_we_mul && (rd_s_mul != 6'd0)) begin
                data[rd_s_mul] <= rd_v_mul;
            end

            if (regf_we_ldst && (rd_s_ldst != 6'd0)) begin
                data[rd_s_ldst] <= rd_v_ldst;
            end

            rs1_v <= (rs1_s != 6'd0) ? data[rs1_s] : '0;
            rs2_v <= (rs2_s != 6'd0) ? data[rs2_s] : '0;

            rs1_v_mul <= (rs1_s_mul != 6'd0) ? data[rs1_s_mul] : '0;

            rs2_v_mul <= (rs2_s_mul != 6'd0) ? data[rs2_s_mul] : '0;

            rs1_v_ldst <= (rs1_s_ldst != 6'd0) ? data[rs1_s_ldst] : '0;

            rs2_v_ldst <= (rs2_s_ldst != 6'd0) ? data[rs2_s_ldst] : '0;
        end
    end

    // !!!!! TODO Transparent ? 

    always_comb // set based on input vals
        begin
            // if(rd_s == rs1_s)
            //     begin
            //         rs1_v = (rs1_s != 6'd0) ? rd_v : '0;
            //     end
            // else
            //     begin
                    // rs1_v = (rs1_s != 6'd0) ? data[rs1_s] : '0;

                    // rs1_v_mul = (rs1_s_mul != 6'd0) ? data[rs1_s_mul] : '0;

                    // rs1_v_ldst = (rs1_s_ldst != 6'd0) ? data[rs1_s_ldst] : '0;
            //      end
            
            // if(rd_s == rs2_s)
            //     begin
            //         rs2_v = (rs2_s != 6'd0) ? rd_v : '0;
            //     end
            // else
            //     begin
                    // rs2_v = (rs2_s != 6'd0) ? data[rs2_s] : '0;

                    // rs2_v_mul = (rs2_s_mul != 6'd0) ? data[rs2_s_mul] : '0;

                    // rs2_v_ldst = (rs2_s_ldst != 6'd0) ? data[rs2_s_ldst] : '0;
            //     end
           
        end

endmodule : physical_regfile