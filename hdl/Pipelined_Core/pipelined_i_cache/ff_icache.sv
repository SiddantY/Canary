module ff_icache #(
            parameter               S_INDEX     = 4,
            parameter               WIDTH       = 1
)(
    input   logic                   clk0,
    input   logic                   rst0,
    input   logic                   csb0,
    input   logic                   web0,
    input   logic   [S_INDEX-1:0]   addr0, addr1, // 0 - write, 1 - read
    input   logic   [WIDTH-1:0]     din0,
    output  logic   [WIDTH-1:0]     dout1

    // input   logic                   invalidate_en,
    // input   logic    [3:0]          invalid_set
);

            localparam              NUM_SETS    = 2**S_INDEX;

            logic                   web0_reg;
            logic   [S_INDEX-1:0]   addr0_reg, addr1_reg;
            logic   [WIDTH-1:0]     din0_reg;

            logic   [WIDTH-1:0]     internal_array [NUM_SETS];

    always_ff @(posedge clk0) begin
        if (rst0) begin
            web0_reg  <= 1'b0;
            addr0_reg <= 'x;
            addr1_reg <= 'x;
            din0_reg  <= 'x;
        end else begin
            if (!csb0) begin
                web0_reg  <= web0;
                addr0_reg <= addr0;
                addr1_reg <= addr1;
                din0_reg  <= din0;
            end
        end
    end

    always_ff @(posedge clk0) begin
        if (rst0) begin
            for (int i = 0; i < NUM_SETS; i++) begin
                internal_array[i] <= '0;
            end
        end else begin
            if (!web0_reg) begin
                internal_array[addr0_reg] <= din0_reg;
            end

            // if(invalidate_en) begin
            //     internal_array[invalid_set] <= 1'b0;
            // end
        end
    end

    always_comb begin
        dout1 = internal_array[addr1_reg];
    end

endmodule : ff_icache