module lock_table (

    input   logic           clk,
    input   logic           rst,

    input   logic   [31:0]  ooo_locked_address,
    input   logic           ooo_lock,

    input   logic           ooo_unlock,

    input   logic   [31:0]  ppl_locked_address,
    input   logic           ppl_lock,

    input   logic           ppl_unlock,

    output  logic   [32:0]  this_address_locked_by_ooo,
    output  logic   [32:0]  this_address_locked_by_ppl
);

logic [32:0] lock_table[2]; // L/Address

always_ff @(posedge clk) begin

    if(rst) begin
        lock_table[0] <= '0;
        lock_table[1] <= '0;
    end else begin
        if(ooo_lock) begin
            lock_table[0][31:0] <= ooo_locked_address;
            lock_table[0][32] <= 1'b1;
        end else if(ooo_unlock) begin
            lock_table[0][32] <= 1'b0;
        end

        if(ppl_lock) begin
            lock_table[1][31:0] <= ppl_locked_address;
            lock_table[1][32] <= 1'b1;
        end else if(ppl_unlock) begin
            lock_table[1][32] <= 1'b0;
        end
    end

end

always_comb begin
    this_address_locked_by_ooo = lock_table[0][32:0];
    this_address_locked_by_ppl = lock_table[1][32:0];
end



endmodule