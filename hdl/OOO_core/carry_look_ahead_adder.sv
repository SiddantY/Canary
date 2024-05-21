module carry_look_ahead_adder(
    output logic [31:0] sum,
    output logic cout,
	input logic [31:0] a,
    input logic [31:0] b,
    input logic cin
);
    
    logic [32:0] carry0, carry1;
	logic [32:0] carry0_1, carry1_1, carry0_2, carry1_2, carry0_4, carry1_4, carry0_8, carry1_8, carry0_16, carry1_16;

	assign carry0[0] = cin;
	assign carry1[0] = cin;

    always @(*)
        begin

            sum = a^b;
            sum = sum[31:0]^carry0_16[31:0];
            cout = carry0_16[32];	

        end
	
	kpg_init init [32:1] (carry1[32:1], carry0[32:1], a[31:0], b[31:0]);

	assign carry1_1[0] = cin;
	assign carry0_1[0] = cin;
	assign carry1_2[1:0] = carry1_1[1:0];
	assign carry0_2[1:0] = carry0_1[1:0];
	assign carry1_4[3:0] = carry1_2[3:0];
	assign carry0_4[3:0] = carry0_2[3:0];
	assign carry1_8[7:0] = carry1_4[7:0];
	assign carry0_8[7:0] = carry0_4[7:0];
	assign carry1_16[15:0] = carry1_8[15:0];
	assign carry0_16[15:0] = carry0_8[15:0];

	kpg itr_1 [32:1] (carry1[32:1], carry0[32:1], carry1[31:0], carry0[31:0], carry1_1[32:1], carry0_1[32:1]);
	kpg itr_2 [32:2] (carry1_1[32:2], carry0_1[32:2], carry1_1[30:0], carry0_1[30:0], carry1_2[32:2], carry0_2[32:2]);
	kpg itr_4 [32:4] (carry1_2[32:4], carry0_2[32:4], carry1_2[28:0], carry0_2[28:0], carry1_4[32:4], carry0_4[32:4]);
	kpg itr_8 [32:8] (carry1_4[32:8], carry0_4[32:8], carry1_4[24:0], carry0_4[24:0], carry1_8[32:8], carry0_8[32:8]);
	kpg itr_16 [32:16] (carry1_8[32:16], carry0_8[32:16], carry1_8[16:0], carry0_8[16:0], carry1_16[32:16], carry0_16[32:16]);
endmodule

module kpg_init (
	output logic out1, 
    output logic out0,
	input  logic a, 
    input  logic b
);
	always @*
	case ({a, b})
		2'b00: begin
			out0 = 1'b0; out1 = 1'b0;
		end
		2'b11: begin
			out0 = 1'b1; out1 = 1'b1;
		end
		default: begin 
			out0 = 1'b0; out1 = 1'b1;
		end
	endcase

endmodule

module kpg (
	input logic cur_bit_1,
    input logic cur_bit_0, 
    input logic prev_bit_1, 
    input logic prev_bit_0,
	output logic out_bit_1, 
    output logic out_bit_0
);
	always @(*)
	begin
		{out_bit_1, out_bit_0} = {prev_bit_1, prev_bit_0};
		
		if({cur_bit_1, cur_bit_0} == 2'b00)
			{out_bit_1, out_bit_0} = 2'b00;
		
		if({cur_bit_1, cur_bit_0} == 2'b11)
			{out_bit_1, out_bit_0} = 2'b11;

		if({cur_bit_1, cur_bit_0} == 2'b10)
			{out_bit_1, out_bit_0} = {prev_bit_1, prev_bit_0};

	end

endmodule

module FA (
    input logic [63:0] x,
    input logic [63:0] y,
    input logic [63:0] z,
    output logic [63:0] u,
    output logic [63:0] v);

logic [63:0] vtemp;
assign u = x^y^z;
assign v[0] = 1'b0;
assign vtemp = ((x&y) | (y&z) | (z&x));
assign v[63:1] = vtemp[62:0];

endmodule

module partial_products (
    input logic [63:0]a,
    input logic [31:0]b,
    output logic [31:0][63:0]p_prods
);

    integer i;

    always @(a or b)
    begin
        for(i=0; i<32; i=i+1)begin
            if(b[i] == 1)begin
                p_prods[i] <= a << i;
            end
            else
                p_prods[i] <= 64'h00000000;
        end
    end

endmodule