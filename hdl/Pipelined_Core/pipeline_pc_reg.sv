module pipeline_pc_reg(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  pc,
    output  logic   [31:0]  pc_prev,

    input   logic           mispredict_br_en,
    input   logic   [31:0]  mispredict_pc,

    input   logic           hardware_scheduler_swap_pc,
    input   logic   [31:0]  hardware_scheduler_pc,

    input   logic           stall
);

logic [31:0] pc_next;

always_ff @(posedge clk)
    begin
        if(rst) // pc defaults to 0x6000_0000 on reset
            begin
                pc <= 32'h1ece_b000;
                pc_prev <= 32'h1ece_b000;
            end
        else // pc <- pc_next 
            begin
                if(~stall)
                    begin
                        pc <= pc_next;
                        pc_prev <= pc;
                    end
                else
                    begin
                        pc <= hardware_scheduler_swap_pc ? pc_next : pc;
                        pc_prev <= hardware_scheduler_swap_pc ? pc_next + 32'h4: pc_prev;  
                    end
            end
    end

always_comb
    begin
        
        if(hardware_scheduler_swap_pc) 
            begin
                pc_next = hardware_scheduler_pc;
            end
        else if(mispredict_br_en)
            begin
                pc_next = mispredict_pc;
            end
        else // else pc just pc + 4
            begin
                pc_next = pc + 32'h4;
            end
    end

endmodule
