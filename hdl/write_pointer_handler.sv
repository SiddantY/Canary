module write_pointer_handler #(
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  logic               w_clk,
    input  logic               w_rst,
    input  logic               w_en,
    input  logic [PTR_WIDTH:0] g_rptr_sync,

    output logic               full,
    output logic [PTR_WIDTH:0] b_wptr,
    output logic [PTR_WIDTH:0] g_wptr
);

    logic [PTR_WIDTH:0] b_wptr_next;
    logic [PTR_WIDTH:0] g_wptr_next;

    logic full_inter;

    assign b_wptr_next = b_wptr + (w_en && !full);
    assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next;
    assign full_inter = (g_wptr_next == {~g_rptr_sync[PTR_WIDTH:PTR_WIDTH-1], g_rptr_sync[PTR_WIDTH-2:0]});

    always_ff @(posedge w_clk) begin
        if(w_rst) begin
            b_wptr <= '0;
            g_wptr <= '0;
            full <= 1'b0;
        end else begin
            b_wptr <= b_wptr_next;
            g_wptr <= g_wptr_next;
            full <= full_inter;
        end
    end 

endmodule