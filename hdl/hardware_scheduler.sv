module hardware_scheduler
import rv32i_types::*;
(
    input       logic       clk,
    input       logic       rst,

    // Counter Enables - OOO

    input       logic  mult_counter_ooo_en,
    input       logic  mem_op_counter_ooo_en,
    input       logic  flush_counter_ooo_en,
    input       logic  rob_full_ooo_en,
    input       logic  alu_op_counter_ooo_en,


    // Counter Enables - PPL

    input       logic  mult_counter_ppl_en,
    input       logic  mem_op_counter_ppl_en,
    input       logic  flush_counter_ppl_en,
    input       logic  rob_full_ppl_threshold,
    input       logic  alu_op_counter_ppl_en,


    // Output
    
    output      logic       hardware_scheduler_en
);

localparam ROB_THRESHOLD = 6666;

/*

For CDC purposes ppl counter blocks can be running on posedge of slower clk.
    - 


*/

logic [31:0] cycle_counter;

always_ff @(posedge clk) begin : cycle_counter_block

    if(rst) begin
        cycle_counter <= '0;
    end else begin

        if(cycle_counter >= 32'd10000) begin

            cycle_counter <= '0;

        end else begin

            cycle_counter <= cycle_counter + 1'b1;

        end

    end
    
end : cycle_counter_block

logic [31:0] multiply_counter_ooo;
logic [31:0] multiply_counter_ppl;

always_ff @(posedge clk) begin : multiply_counter_block

    if(rst) begin

        multiply_counter_ooo <= '0;
        multiply_counter_ppl <= '0;
        
    end else begin

        if(cycle_counter >= 32'd10000) begin

            multiply_counter_ooo <= '0;
            multiply_counter_ppl <= '0;

        end else begin

            if(mult_counter_ooo_en) multiply_counter_ooo <= multiply_counter_ooo + 1'b1;
            if(mult_counter_ppl_en) multiply_counter_ppl <= multiply_counter_ppl + 1'b1;

        end

    end
    
end : multiply_counter_block

logic [31:0] mem_op_counter_ooo;
logic [31:0] mem_op_counter_ppl;

always_ff @(posedge clk) begin : mem_op_counter_block

    if(rst) begin

        mem_op_counter_ooo <= '0;
        mem_op_counter_ppl <= '0;
        
    end else begin

        if(cycle_counter >= 32'd10000) begin

            mem_op_counter_ooo <= '0;
            mem_op_counter_ppl <= '0;

        end else begin

            if(mem_op_counter_ooo_en) mem_op_counter_ooo <= mem_op_counter_ooo + 1'b1;
            if(mem_op_counter_ppl_en) mem_op_counter_ppl <= mem_op_counter_ppl + 1'b1;

        end

    end
    
end : mem_op_counter_block


logic [31:0] flush_counter_ooo;
logic [31:0] flush_counter_ppl;

always_ff @(posedge clk) begin : flush_counter_block

    if(rst) begin

        flush_counter_ooo <= '0;
        flush_counter_ppl <= '0;
        
    end else begin

        if(cycle_counter >= 32'd10000) begin

            flush_counter_ooo <= '0;
            flush_counter_ppl <= '0;

        end else begin

            if(flush_counter_ooo_en) flush_counter_ooo <= flush_counter_ooo + 1'b1;
            if(flush_counter_ppl_en) flush_counter_ppl <= mem_op_counter_ppl + 1'b1;

        end

    end
    
end : flush_counter_block

logic [31:0] rob_full_counter;

always_ff @(posedge clk) begin : rob_full_counter_block

    if (rst) begin

        rob_full_ooo_en <= '0;

    end else begin

        if (cycle_counter >= 32'd10000) begin

            rob_full_ooo_en <= '0;

        end else begin

            if (rob_full_ooo_en) rob_full_counter <= rob_full_counter + 1'b1;

        end

    end
    
end : rob_full_counter_block

logic [31:0] alu_op_counter_ooo;
logic [31:0] alu_op_counter_ppl;

always_ff @(posedge clk) begin : alu_op_counter_block

    if(rst) begin

        alu_op_counter_ooo <= '0;
        alu_op_counter_ppl <= '0;
        
    end else begin

        if(cycle_counter >= 32'd10000) begin

            alu_op_counter_ooo <= '0;
            alu_op_counter_ppl <= '0;

        end else begin

            if(alu_op_counter_ooo_en) alu_op_counter_ooo <= alu_op_counter_ooo + 1'b1;
            if(alu_op_counter_ppl_en) alu_op_counter_ppl <= alu_op_counter_ppl + 1'b1;

        end

    end
    
end : alu_op_counter_block


logic [4:0] hw_sc_counter;

assign counter[0] = (multiply_counter_ooo < multiply_counter_ppl) ? 1'b1 : 1'b0;
assign counter[1] = (mem_op_counter_ooo > mem_op_counter_ppl) ? 1'b1 : 1'b0;
assign counter[2] = (flush_counter_ooo > flush_counter_ppl) ? 1'b1 : 1'b0;
assign counter[3] = (rob_full_counter > ROB_THRESHOLD) ? 1'b1 : 1'b0;
assign counter[4] = (alu_op_counter_ooo < alu_op_counter_ppl) ? 1'b1 : 1'b0;

always_comb begin : hardware_scheduler_enable

    hardware_scheduler_en = 1'b0;

    if(cycle_counter >= 32'd10000) begin

        unique case (counter)
            5'b00111: hardware_scheduler_en = 1'b1;
            5'b01011: hardware_scheduler_en = 1'b1;
            5'b01101: hardware_scheduler_en = 1'b1;
            5'b01110: hardware_scheduler_en = 1'b1;
            5'b01111: hardware_scheduler_en = 1'b1;
            5'b10011: hardware_scheduler_en = 1'b1;
            5'b10101: hardware_scheduler_en = 1'b1;
            5'b10110: hardware_scheduler_en = 1'b1;
            5'b10111: hardware_scheduler_en = 1'b1;
            5'b11000: hardware_scheduler_en = 1'b1;
            5'b11001: hardware_scheduler_en = 1'b1;
            5'b11010: hardware_scheduler_en = 1'b1;
            5'b11011: hardware_scheduler_en = 1'b1;
            5'b11100: hardware_scheduler_en = 1'b1;
            5'b11101: hardware_scheduler_en = 1'b1;
            5'b11110: hardware_scheduler_en = 1'b1;
            5'b11111: hardware_scheduler_en = 1'b1;
            default hardware_scheduler_en = 1'b0;
        endcase

    end

end : hardware_scheduler_enable

endmodule