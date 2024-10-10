module read_pointer_handler#(
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  logic               r_clk,
    input  logic               r_rst,
    input  logic               r_en,
    input  logic [PTR_WIDTH:0] g_wptr_sync,

    output logic               empty,
    output logic [PTR_WIDTH:0] b_rptr,
    output logic [PTR_WIDTH:0] g_rptr
);

    logic [PTR_WIDTH:0] b_rptr_next;
    logic [PTR_WIDTH:0] g_rptr_next;

    logic empty_iter;

    assign b_rptr_next = b_rptr + (r_en && !empty);
    assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;
    assign empty_iter = (g_rptr_next == g_wptr_sync);

    always_ff @(posedge r_clk) begin
        if(r_rst) begin
            b_rptr <= '0;
            g_rptr <= '0;
            empty <= 1'b1;
        end else begin
            b_rptr <= b_rptr_next;
            g_rptr <= g_rptr_next;
            empty <= empty_iter;
        end
    end 

endmodule