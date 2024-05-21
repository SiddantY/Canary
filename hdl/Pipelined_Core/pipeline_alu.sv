module pipeline_alu
import rv32i_types::*;
(
    input   logic           aluc,
    input   logic   [2:0]   aluop,
    input   logic   [31:0]  a, b,
    output  logic   [31:0]  f
);

    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu;

    assign as =   signed'(a);
    assign bs =   signed'(b);
    assign au = unsigned'(a);
    assign bu = unsigned'(b);

    always_comb begin
        unique case (aluc)
            1'b1: begin
                unique case (aluop)
                    alu_add: f = au +   bu;
                    alu_sll: f = au <<  bu[4:0];
                    alu_sra: f = unsigned'(as >>> bu[4:0]);
                    alu_sub: f = au -   bu;
                    alu_xor: f = au ^   bu;
                    alu_srl: f = au >>  bu[4:0];
                    alu_or:  f = au |   bu;
                    alu_and: f = au &   bu;
                    default: f = 'x;
                endcase
            end
            1'b0: begin
                unique case (aluop)
                    beq:  f = (au == bu) ? 32'b1 : 32'b0;
                    bne:  f = (au != bu) ? 32'b1 : 32'b0;
                    blt:  f = (as <  bs) ? 32'b1 : 32'b0;
                    bge:  f = (as >=  bs) ? 32'b1 : 32'b0;
                    bltu: f = (au <  bu) ? 32'b1 : 32'b0;
                    bgeu: f = (au >=  bu) ? 32'b1 : 32'b0;
                    default: f = 'x;
                endcase
            end
            default: f = 'x;
        endcase
    end

endmodule : pipeline_alu
