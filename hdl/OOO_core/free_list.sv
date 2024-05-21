module free_list
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           flush,
    input   logic           need_free_reg,
    input   logic           reg_freed,
    input   logic   [$clog2(NUM_REGS)-1:0]   liberated_reg,
    input [NUM_REGS-1:0]           phys_reg_valid,
    input logic     [4:0]       arch_rd,
    input   logic   [$clog2(NUM_REGS)-1:0]   rrf_arch_to_physical[32],
    output  logic   [$clog2(NUM_REGS)-1:0]   free_reg,
    output  logic           reg_available
);

logic [NUM_REGS:0] free_list_bit_vector;
logic [$clog2(NUM_REGS)-1:0] free_list_ptr;

assign free_reg = (arch_rd == 5'd0) ? 6'd0 : free_list_ptr;

always_ff @(posedge clk)
    begin
        if(rst) // if reset everything is free
            begin
                
                free_list_bit_vector[31:0] <= 32'hFFFFFFFF;

                for(int i = 32; i < NUM_REGS; i++)
                    begin
                        free_list_bit_vector[i] <= 1'b0; // 0 is free, 1 is busy
                    end
                
                //free_list_ptr <= 6'd32;
            end
        else if(flush)
            begin
                for(int p1 = 0; p1 < NUM_REGS; p1++)
                    begin
                        free_list_bit_vector[p1] <= 1'b0;
                    end

                for(int c = 0; c < 32; c++)
                    begin
                        free_list_bit_vector[rrf_arch_to_physical[c]] <= 1'b1;
                    end
            end
        else
            begin
                if(need_free_reg && ~free_list_bit_vector[free_list_ptr]) // REQUESTING A FREE REG
                    begin
                        free_list_bit_vector[free_list_ptr] <= 1'b1; // SET BUSY
                        // UPDATE LIST PTR
                        // if(free_list_ptr == 6'd127) free_list_ptr <= 6'b1;
                        // //else if(free_list_ptr == '0) free_list_ptr <= 6'b1;
                        // else free_list_ptr <= free_list_ptr + 1'b1;

                    end
                if(reg_freed && liberated_reg != '0) // FREEING A REG
                    begin
                        free_list_bit_vector[liberated_reg] <= 1'b0; // NO LONGER BUSY
                    end
            end
    end

always_comb begin : FREE_REG_CHECK

    if ((free_list_bit_vector[2] == 1'b0) && phys_reg_valid[2] == 1'b1) begin 
        free_list_ptr = 6'd2;
    end else if ((free_list_bit_vector[3] == 1'b0) && phys_reg_valid[3] == 1'b1) begin 
        free_list_ptr = 6'd3;
    end else if ((free_list_bit_vector[4] == 1'b0) && phys_reg_valid[4] == 1'b1) begin 
        free_list_ptr = 6'd4;
    end else if ((free_list_bit_vector[5] == 1'b0) && phys_reg_valid[5] == 1'b1) begin 
        free_list_ptr = 6'd5;
    end else if ((free_list_bit_vector[6] == 1'b0) && phys_reg_valid[6] == 1'b1) begin 
        free_list_ptr = 6'd6;
    end else if ((free_list_bit_vector[7] == 1'b0) && phys_reg_valid[7] == 1'b1) begin 
        free_list_ptr = 6'd7;
    end else if ((free_list_bit_vector[8] == 1'b0) && phys_reg_valid[8] == 1'b1) begin 
        free_list_ptr = 6'd8;
    end else if ((free_list_bit_vector[9] == 1'b0) && phys_reg_valid[9] == 1'b1) begin 
        free_list_ptr = 6'd9;
    end else if ((free_list_bit_vector[10] == 1'b0) && phys_reg_valid[10] == 1'b1) begin 
        free_list_ptr = 6'd10;
    end else if ((free_list_bit_vector[11] == 1'b0) && phys_reg_valid[11] == 1'b1) begin 
        free_list_ptr = 6'd11;
    end else if ((free_list_bit_vector[12] == 1'b0) && phys_reg_valid[12] == 1'b1) begin 
        free_list_ptr = 6'd12;
    end else if ((free_list_bit_vector[13] == 1'b0) && phys_reg_valid[13] == 1'b1) begin 
        free_list_ptr = 6'd13;
    end else if ((free_list_bit_vector[14] == 1'b0) && phys_reg_valid[14] == 1'b1) begin 
        free_list_ptr = 6'd14;
    end else if ((free_list_bit_vector[15] == 1'b0) && phys_reg_valid[15] == 1'b1) begin 
        free_list_ptr = 6'd15;
    end else if ((free_list_bit_vector[16] == 1'b0) && phys_reg_valid[16] == 1'b1) begin 
        free_list_ptr = 6'd16;
    end else if ((free_list_bit_vector[17] == 1'b0) && phys_reg_valid[17] == 1'b1) begin 
        free_list_ptr = 6'd17;
    end else if ((free_list_bit_vector[18] == 1'b0) && phys_reg_valid[18] == 1'b1) begin 
        free_list_ptr = 6'd18;
    end else if ((free_list_bit_vector[19] == 1'b0) && phys_reg_valid[19] == 1'b1) begin 
        free_list_ptr = 6'd19;
    end else if ((free_list_bit_vector[20] == 1'b0) && phys_reg_valid[20] == 1'b1) begin 
        free_list_ptr = 6'd20;
    end else if ((free_list_bit_vector[21] == 1'b0) && phys_reg_valid[21] == 1'b1) begin 
        free_list_ptr = 6'd21;
    end else if ((free_list_bit_vector[22] == 1'b0) && phys_reg_valid[22] == 1'b1) begin 
        free_list_ptr = 6'd22;
    end else if ((free_list_bit_vector[23] == 1'b0) && phys_reg_valid[23] == 1'b1) begin 
        free_list_ptr = 6'd23;
    end else if ((free_list_bit_vector[24] == 1'b0) && phys_reg_valid[24] == 1'b1) begin 
        free_list_ptr = 6'd24;
    end else if ((free_list_bit_vector[25] == 1'b0) && phys_reg_valid[25] == 1'b1) begin 
        free_list_ptr = 6'd25;
    end else if ((free_list_bit_vector[26] == 1'b0) && phys_reg_valid[26] == 1'b1) begin 
        free_list_ptr = 6'd26;
    end else if ((free_list_bit_vector[27] == 1'b0) && phys_reg_valid[27] == 1'b1) begin 
        free_list_ptr = 6'd27;
    end else if ((free_list_bit_vector[28] == 1'b0) && phys_reg_valid[28] == 1'b1) begin 
        free_list_ptr = 6'd28;
    end else if ((free_list_bit_vector[29] == 1'b0) && phys_reg_valid[29] == 1'b1) begin 
        free_list_ptr = 6'd29;
    end else if ((free_list_bit_vector[30] == 1'b0) && phys_reg_valid[30] == 1'b1) begin 
        free_list_ptr = 6'd30;
    end else if ((free_list_bit_vector[31] == 1'b0) && phys_reg_valid[31] == 1'b1) begin 
        free_list_ptr = 6'd31;
    end else if ((free_list_bit_vector[32] == 1'b0) && phys_reg_valid[32] == 1'b1) begin 
        free_list_ptr = 6'd32;
    end else if ((free_list_bit_vector[33] == 1'b0) && phys_reg_valid[33] == 1'b1) begin 
        free_list_ptr = 6'd33;
    end else if ((free_list_bit_vector[34] == 1'b0) && phys_reg_valid[34] == 1'b1) begin 
        free_list_ptr = 6'd34;
    end else if ((free_list_bit_vector[35] == 1'b0) && phys_reg_valid[35] == 1'b1) begin 
        free_list_ptr = 6'd35;
    end else if ((free_list_bit_vector[36] == 1'b0) && phys_reg_valid[36] == 1'b1) begin 
        free_list_ptr = 6'd36;
    end else if ((free_list_bit_vector[37] == 1'b0) && phys_reg_valid[37] == 1'b1) begin 
        free_list_ptr = 6'd37;
    end else if ((free_list_bit_vector[38] == 1'b0) && phys_reg_valid[38] == 1'b1) begin 
        free_list_ptr = 6'd38;
    end else if ((free_list_bit_vector[39] == 1'b0) && phys_reg_valid[39] == 1'b1) begin 
        free_list_ptr = 6'd39;
    end else if ((free_list_bit_vector[40] == 1'b0) && phys_reg_valid[40] == 1'b1) begin 
        free_list_ptr = 6'd40;
    end else if ((free_list_bit_vector[41] == 1'b0) && phys_reg_valid[41] == 1'b1) begin 
        free_list_ptr = 6'd41;
    end else if ((free_list_bit_vector[42] == 1'b0) && phys_reg_valid[42] == 1'b1) begin 
        free_list_ptr = 6'd42;
    end else if ((free_list_bit_vector[43] == 1'b0) && phys_reg_valid[43] == 1'b1) begin 
        free_list_ptr = 6'd43;
    end else if ((free_list_bit_vector[44] == 1'b0) && phys_reg_valid[44] == 1'b1) begin 
        free_list_ptr = 6'd44;
    end else if ((free_list_bit_vector[45] == 1'b0) && phys_reg_valid[45] == 1'b1) begin 
        free_list_ptr = 6'd45;
    end else if ((free_list_bit_vector[46] == 1'b0) && phys_reg_valid[46] == 1'b1) begin 
        free_list_ptr = 6'd46;
    end else if ((free_list_bit_vector[47] == 1'b0) && phys_reg_valid[47] == 1'b1) begin 
        free_list_ptr = 6'd47;
    end else if ((free_list_bit_vector[48] == 1'b0) && phys_reg_valid[48] == 1'b1) begin 
        free_list_ptr = 6'd48;
    end else if ((free_list_bit_vector[49] == 1'b0) && phys_reg_valid[49] == 1'b1) begin 
        free_list_ptr = 6'd49;
    end else if ((free_list_bit_vector[50] == 1'b0) && phys_reg_valid[50] == 1'b1) begin 
        free_list_ptr = 6'd50;
    end else if ((free_list_bit_vector[51] == 1'b0) && phys_reg_valid[51] == 1'b1) begin 
        free_list_ptr = 6'd51;
    end else if ((free_list_bit_vector[52] == 1'b0) && phys_reg_valid[52] == 1'b1) begin 
        free_list_ptr = 6'd52;
    end else if ((free_list_bit_vector[53] == 1'b0) && phys_reg_valid[53] == 1'b1) begin 
        free_list_ptr = 6'd53;
    end else if ((free_list_bit_vector[54] == 1'b0) && phys_reg_valid[54] == 1'b1) begin 
        free_list_ptr = 6'd54;
    end else if ((free_list_bit_vector[55] == 1'b0) && phys_reg_valid[55] == 1'b1) begin 
        free_list_ptr = 6'd55;
    end else if ((free_list_bit_vector[56] == 1'b0) && phys_reg_valid[56] == 1'b1) begin 
        free_list_ptr = 6'd56;
    end else if ((free_list_bit_vector[57] == 1'b0) && phys_reg_valid[57] == 1'b1) begin 
        free_list_ptr = 6'd57;
    end else if ((free_list_bit_vector[58] == 1'b0) && phys_reg_valid[58] == 1'b1) begin 
        free_list_ptr = 6'd58;
    end else if ((free_list_bit_vector[59] == 1'b0) && phys_reg_valid[59] == 1'b1) begin 
        free_list_ptr = 6'd59;
    end else if ((free_list_bit_vector[60] == 1'b0) && phys_reg_valid[60] == 1'b1) begin 
        free_list_ptr = 6'd60;
    end else if ((free_list_bit_vector[61] == 1'b0) && phys_reg_valid[61] == 1'b1) begin 
        free_list_ptr = 6'd61;
    end else if ((free_list_bit_vector[62] == 1'b0) && phys_reg_valid[62] == 1'b1) begin 
        free_list_ptr = 6'd62;
    end else if ((free_list_bit_vector[63] == 1'b0) && phys_reg_valid[63] == 1'b1) begin 
        free_list_ptr = 6'd63;
    end else begin
            free_list_ptr = 'x;
    end


    if(free_list_bit_vector[free_list_ptr] == 1'b0) reg_available = 1'b1;
    else reg_available = 1'b0;
end
endmodule