module wallace_multiplier
import rv32i_types::*;
#(
    parameter int OPERAND_WIDTH = 32
)
(
    input logic clk,
    input logic rst,
    // Start must be reset after the done flag is set before another multiplication can execute
    input logic start,

    // Use this input to select what type of multiplication you are performing
    // 0 = Multiply two unsigned numbers
    // 1 = Multiply two signed numbers
    // 2 = Multiply a signed number and unsigned number
    //      a = signed
    //      b = unsigned
    input logic [1:0] mul_type,

    input logic[OPERAND_WIDTH-1:0] a,
    input logic[OPERAND_WIDTH-1:0] b,
    output logic[2*OPERAND_WIDTH-1:0] p,
    output logic done
);

    // Constants for multiplication case readability
    `define UNSIGNED_UNSIGNED_MUL 2'b00
    `define SIGNED_SIGNED_MUL     2'b01
    `define SIGNED_UNSIGNED_MUL   2'b10

    enum int unsigned {IDLE, MUL, MUL1, DONE} curr_state, next_state;
    localparam int OP_WIDTH_LOG = $clog2(OPERAND_WIDTH);
    logic [OP_WIDTH_LOG-1:0] counter;
    logic [OPERAND_WIDTH-1:0] b_reg, a_reg;
    logic [2*OPERAND_WIDTH-1:0] accumulator, mul_out; // a_reg needs to be 2 times wide since it is shifted left
    logic neg_result;

    always_comb
        begin : state_transition
            next_state = curr_state;
            unique case (curr_state)
                IDLE:    next_state = start ? MUL : IDLE;
                MUL:     next_state = MUL1;
                MUL1:    next_state = DONE;
                DONE:    next_state = start ? DONE : IDLE;
                default: next_state = curr_state;
            endcase
        end : state_transition

    always_comb
        begin : state_outputs
            done = '0;
            p = '0;
            unique case (curr_state)
                DONE:
                    begin
                        done = 1'b1;
                        unique case (mul_type)
                            `UNSIGNED_UNSIGNED_MUL: p = accumulator[2*OPERAND_WIDTH-1:0];
                            `SIGNED_SIGNED_MUL,
                            `SIGNED_UNSIGNED_MUL: p = neg_result ? (~accumulator[2*OPERAND_WIDTH-1-1:0])+1'b1 : accumulator;
                            default: ;
                        endcase
                    end
                default: ;
            endcase
        end : state_outputs

always_ff @ (posedge clk)
    begin
        if (rst)
            begin
                curr_state <= IDLE;
                a_reg <= '0;
                b_reg <= '0;
                accumulator <= '0;
                counter <= '0;
                neg_result <= '0;
            end
        else
            begin
                curr_state <= next_state;
                unique case (curr_state)
                    IDLE:
                    begin
                        if (start)
                        begin
                            accumulator <= '0;
                            unique case (mul_type)
                                `UNSIGNED_UNSIGNED_MUL:
                                begin
                                    neg_result <= '0;   // Not used in case of unsigned mul, but just cuz . . .
                                    a_reg <= a;
                                    b_reg <= b;
                                end
                                `SIGNED_SIGNED_MUL:
                                begin
                                    // A -*+ or +*- results in a negative number unless the "positive" number is 0
                                    neg_result <= (a[OPERAND_WIDTH-1] ^ b[OPERAND_WIDTH-1]) && ((a != '0) && (b != '0));
                                    // If operands negative, make positive
                                    a_reg <= (a[OPERAND_WIDTH-1]) ? {/*OPERAND_WIDTH*{1'b0}, */(~a + 1'b1)} : a;
                                    b_reg <= (b[OPERAND_WIDTH-1]) ? {/*OPERAND_WIDTH*{1'b0}, */(~b + 1'b1)} : b;
                                end
                                `SIGNED_UNSIGNED_MUL:
                                begin
                                    neg_result <= a[OPERAND_WIDTH-1];
                                    a_reg <= (a[OPERAND_WIDTH-1]) ? {/*OPERAND_WIDTH*{1'b0}, */(~a + 1'b1)} : a;
                                    b_reg <= b;
                                end
                                default:;
                            endcase
                        end
                    end
                    MUL: ;
                    MUL1:
                        begin
                            // does anything go here ?
                            accumulator <= mul_out;
                        end
                    DONE: counter <= '0;
                    default: ;
                endcase
            end
    end


actual_mult wallace_multiplier(
    .clk(clk),
    .a(a_reg),
	.b(b_reg),
	.out(mul_out)
);
endmodule