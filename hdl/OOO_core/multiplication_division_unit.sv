module multiplication_division_unit 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input logic flush,
    input reservation_station_entry_t line_to_execute_mul,
    input logic [31:0] pr1_val_mul,
    input logic [31:0] pr2_val_mul,
    input logic execute_valid_mul,
    output data_bus_package_t execute_outputs_mul
);

logic [1:0] mul_type;
logic [63:0] mul_out;
logic done_mult;
logic start_mult;
logic start_mult_del_1;

logic div_funct3;
logic start_div;
logic done_div;
logic div_inuse;
logic [31:0] quotient, remainder;
logic [31:0] div_out;
logic [2:0] div_funct3_latch;

always_ff @(posedge clk)
    begin
        if(rst || flush)
            begin
                start_mult <= 1'b0;
                start_div <= '0;
                div_inuse <= '0;
            end
        else
            begin
                if(done_mult)
                    begin
                        start_mult <= 1'b0;
                    end
                else
                    begin
                        start_mult <= ~done_mult && execute_valid_mul && !div_funct3 ? 1'b1 : 1'b0;
                    end

                if(div_inuse)
                    begin
                        start_div <= 1'b0;
                        if(done_div && !start_div) begin
                            div_inuse <= 1'b0;
                        end
                    end
                else
                    begin
                        start_div <= execute_valid_mul && div_funct3 ? 1'b1 : 1'b0;
                        div_inuse <= execute_valid_mul && div_funct3 ? 1'b1 : 1'b0;
                        // div_funct3_latch <= execute_valid_mul && div_funct3 ? line_to_execute_mul.funct3 : '0;
                    end


            end
    end

always_comb
    begin
        unique case(line_to_execute_mul.opcode)
            op_b_reg: begin
                    unique case (line_to_execute_mul.funct3)
                        3'b000, 3'b001: begin
                            mul_type = 2'b01;
                            div_funct3 = 1'b0;
                        end
                        3'b010: begin
                            mul_type = 2'b10;
                            div_funct3 = 1'b0;
                        end
                        3'b011: begin
                            mul_type = 2'b00;
                            div_funct3 = 1'b0;
                        end
                    default: begin
                        mul_type = 2'bxx;
                        div_funct3 = 1'b1;
                    end
                    endcase
                end
            default: begin
                mul_type = 2'bxx;
                div_funct3 = '0;
            end
        endcase


        execute_outputs_mul.phys_rd = line_to_execute_mul.phys_rd; // rd matching
        if(line_to_execute_mul.funct3 == 3'b000)
            begin
                execute_outputs_mul.phys_rd_val = mul_out[31:0]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(line_to_execute_mul.funct3 == 3'b001)
            begin
                execute_outputs_mul.phys_rd_val = mul_out[63:32]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(line_to_execute_mul.funct3 == 3'b010)
            begin
                execute_outputs_mul.phys_rd_val = mul_out[63:32]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(line_to_execute_mul.funct3 == 3'b011)
            begin
                execute_outputs_mul.phys_rd_val = mul_out[63:32]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(div_funct3) begin
            execute_outputs_mul.phys_rd_val = div_out;
        end else
            begin
                execute_outputs_mul.phys_rd_val = 'x; // alu out to f. FUCK LOADS AND STORES :(
            end
                
        
        execute_outputs_mul.rob_index = line_to_execute_mul.rob_index;
        execute_outputs_mul.regf_we = line_to_execute_mul.regf_we && (done_mult || (done_div && div_inuse && !start_div));

        // if a load and store not a valid thing to update the rat, prf, rob. 0 is ld/st, 1 is alu/cmp
        execute_outputs_mul.alu_or_cmp_op = (line_to_execute_mul.opcode == op_b_reg && line_to_execute_mul.funct7[0] == 1'b1) ? 1'b1 : 1'b0;
        execute_outputs_mul.execute_valid = done_mult || (done_div && div_inuse && !start_div);
        execute_outputs_mul.arch_rd = (line_to_execute_mul.arch_rd == 5'd0) ? 1'b0 : line_to_execute_mul.arch_rd;
        
        // rvfi
        execute_outputs_mul.rvfi.valid = 1'b0;
        execute_outputs_mul.rvfi.order = line_to_execute_mul.order;
        execute_outputs_mul.rvfi.inst = line_to_execute_mul.inst;
        execute_outputs_mul.rvfi.rs1_addr = line_to_execute_mul.arch_rs1;
        execute_outputs_mul.rvfi.rs2_addr = line_to_execute_mul.arch_rs2;
        execute_outputs_mul.rvfi.rs1_rdata = pr1_val_mul;
        execute_outputs_mul.rvfi.rs2_rdata = pr2_val_mul;
        execute_outputs_mul.rvfi.rd_addr = line_to_execute_mul.arch_rd;

        //execute_outputs_mul.rvfi.rd_wdata = f;
        // if(div_funct3_latch) begin
        //     execute_outputs_mul.rvfi.rd_wdata = div_out;
        // end else 
        if(line_to_execute_mul.funct3 == 3'b000)
            begin
                execute_outputs_mul.rvfi.rd_wdata = mul_out[31:0]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(line_to_execute_mul.funct3 == 3'b001)
            begin
                execute_outputs_mul.rvfi.rd_wdata = mul_out[63:32]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(line_to_execute_mul.funct3 == 3'b010)
            begin
                execute_outputs_mul.rvfi.rd_wdata = mul_out[63:32]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(line_to_execute_mul.funct3 == 3'b011) begin
                execute_outputs_mul.rvfi.rd_wdata = mul_out[63:32]; // alu out to f. FUCK LOADS AND STORES :(
            end
        else if(div_funct3) begin
            execute_outputs_mul.rvfi.rd_wdata = div_out;
        // end
        // end else if(line_to_execute_mul.funct3 == 3'b011) begin
        // end else if(line_to_execute_mul.funct3 == 3'b011) begin
        // end else if(line_to_execute_mul.funct3 == 3'b011) begin
        end else
            begin
                execute_outputs_mul.rvfi.rd_wdata = 'x; // alu out to f. FUCK LOADS AND STORES :(
            end

        execute_outputs_mul.rvfi.pc_rdata = line_to_execute_mul.pc;
        execute_outputs_mul.rvfi.pc_wdata = line_to_execute_mul.pc + 32'h4;
        execute_outputs_mul.rvfi.mem_addr = '0;
        execute_outputs_mul.rvfi.mem_rmask = '0;
        execute_outputs_mul.rvfi.mem_wmask = '0;
        execute_outputs_mul.rvfi.mem_rdata = '0;
        execute_outputs_mul.rvfi.mem_wdata = '0;

        execute_outputs_mul.branch_mismatch = 1'b0;
    end




wallace_multiplier
//shift_add_multiplier
#(
    .OPERAND_WIDTH(32)
)

mul_unit_1

(
    .clk(clk),
    .rst(rst || flush),
    // Start must be reset after the done flag is set before another multiplication can execute
    .start(start_mult),

    // Use this input to select what type of multiplication you are performing
    // 0 = Multiply two unsigned numbers
    // 1 = Multiply two signed numbers
    // 2 = Multiply a signed number and unsigned number
    //      a = signed
    //      b = unsigned
    .mul_type(mul_type),

    .a(pr1_val_mul),
    .b(pr2_val_mul),
    .p(mul_out),
    .done(done_mult)
);


// DIVISION TYPES
always_comb begin 
    unique case(line_to_execute_mul.funct3)
        3'b100 : begin // div
            div_out = ~quotient + 1'b1;
        end
        3'b101 : begin // div unsigned
            div_out = quotient;
        end
        3'b110 : begin // remainder
            div_out = ~remainder + 1'b1;
        end
        3'b111 : begin // remainder unsigned
            div_out = remainder;

        end
        default: begin
            div_out = 'x;
        end
    endcase
end


DW_div_seq #(
    .a_width(32),
    .b_width(32),
    .tc_mode(0), // unsigned
    .num_cyc(32),
    .rst_mode(1),
    .input_mode(1), // not registered?
    // .ouput_mode(0),
    .early_start(0)
)
divider(
    .clk(clk),
    .rst_n(!rst),
    .hold('0), // dont hold?
    // .hold(div_inuse), // dont hold?
    .start(start_div),
    .a(pr1_val_mul),
    .b(pr2_val_mul),

    .complete(done_div),
    .quotient(quotient),
    .remainder(remainder),
    .divide_by_0()
);

endmodule