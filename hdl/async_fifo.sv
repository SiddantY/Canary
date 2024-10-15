module async_fifo #(
    parameter DEPTH = 8, // Technically it is 7 but we will need to round up to 8 items
    parameter WIDTH = 33,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    // CPU
    input  logic [WIDTH-1:0] data_in,
    input  logic             w_en,
    input  logic             w_clk,
    input  logic             w_rst,
    output logic             full,
    
    // FPGA
    output logic [WIDTH-1:0] data_out,
    input  logic             r_en,
    input  logic             r_clk,
    input  logic             r_rst,
    output logic             empty    
);
    // FIFO
    logic [WIDTH-1:0] fifo[0:DEPTH-1];

    // Write pointer handler signals
    logic [PTR_WIDTH:0] b_wptr;       
    logic [PTR_WIDTH:0] g_wptr;
    logic [PTR_WIDTH:0] g_rptr_sync;

    // Read pointer handler signals
    logic [PTR_WIDTH:0] g_rptr;
    logic [PTR_WIDTH:0] b_rptr;
    logic [PTR_WIDTH:0] g_wptr_sync;

    // Gray Code Read Pointer Synchronizer
    logic [PTR_WIDTH:0] g_rptr_inter; // Intermittent signal between FF
    always_ff @(posedge w_clk) begin
        if(w_rst) begin
            g_rptr_inter <= '0;
            g_rptr_sync <= '0;
        end else begin
            g_rptr_inter <= g_rptr;
            g_rptr_sync <= g_rptr_inter;
        end
    end

    // Gray Code Write Pointer Synchronizer
    logic [PTR_WIDTH:0] g_wptr_inter; // Intermittent signal between FF
    always_ff @(posedge r_clk) begin
        if(r_rst) begin
            g_wptr_inter <= '0;
            g_wptr_sync <= '0;
        end else begin
            g_wptr_inter <= g_wptr;
            g_wptr_sync <= g_wptr_inter;
        end
    end

    write_pointer_handler write_pointer_handler(
        // Input Signals
        .w_clk(w_clk),
        .w_rst(w_rst),
        .w_en(w_en),
        .g_rptr_sync(g_rptr_sync),
        
        // Output Signals
        .full(full),
        .b_wptr(b_wptr),
        .g_wptr(g_wptr)
    );

    read_pointer_handler read_pointer_handler(
        // Input Signals
        .r_clk(r_clk),
        .r_rst(r_rst),
        .r_en(r_en),
        .g_wptr_sync(g_wptr_sync),

        // Output Signals
        .empty(empty),
        .b_rptr(b_rptr),
        .g_rptr(g_rptr)
    );

    // Writitng to FIFO
    always_ff @(posedge w_clk) begin
        if(w_en && !full) begin
            fifo[b_wptr[PTR_WIDTH-1:0]] <= data_in;
        end 
    end

    // Reading from FIFO
    always_ff @(posedge r_clk) begin
        if(r_en && !empty) begin
            data_out <= fifo[b_rptr[PTR_WIDTH-1:0]];
        end 
    end


endmodule