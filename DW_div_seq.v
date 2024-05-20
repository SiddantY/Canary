////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2002 - 2021 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Aamir Farooqui                February 20, 2002
//
// VERSION:   Verilog Simulation Model for DW_div_seq
//
// DesignWare_version: e28a7baf
// DesignWare_release: R-2020.09-DWBB_202009.4
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
//ABSTRACT:  Sequential Divider 
//  Uses modeling functions from DW_Foundation.
//
//MODIFIED:
// 2/26/16 LMSU Updated to use blocking and non-blocking assigments in
//              the correct way
// 8/06/15 RJK Update to support VCS-NLP
// 2/06/15 RJK  Updated input change monitor for input_mode=0 configurations to better
//             inform designers of severity of protocol violations (STAR 9000851903)
// 5/20/14 RJK  Extended corruption of output until next start for configurations
//             with input_mode = 0 (STAR 9000741261)
// 9/25/12 RJK  Corrected data corruption detection to catch input changes
//             during the first cycle of calculation (related to STAR 9000506285)
// 1/4/12 RJK Change behavior when inputs change during calculation with
//          input_mode = 0 to corrupt output (STAR 9000506285)
// 3/19/08 KYUNG fixed the reset error of the sim model (STAR 9000233070)
// 5/02/08 KYUNG fixed the divide_by_0 error (STAR 9000241241)
// 1/08/09 KYUNG fixed the divide_by_0 error (STAR 9000286268)
// 8/01/17 AFT fixes to sequential behavior to make the simulation model
//             match the synthesis model. 
// 01/17/18 AFT Star 9001296230 
//              Fixed error in NLP VCS, related to upadtes to next_complete
//              inside always blocks that define registers. NLP forces the
//              code to be synthesizable, forcing the code of this simulation
//              model to be changed.
//------------------------------------------------------------------------------

module DW_div_seq ( clk, rst_n, hold, start, a,  b, complete, divide_by_0, quotient, remainder);


// parameters 

  parameter  integer a_width     = 3; 
  parameter  integer b_width     = 3;
  parameter  integer tc_mode     = 0;
  parameter  integer num_cyc     = 3;
  parameter  integer rst_mode    = 0;
  parameter  integer input_mode  = 1;
  parameter  integer output_mode = 1;
  parameter  integer early_start = 0;
 
//-----------------------------------------------------------------------------

// ports 
  input clk, rst_n;
  input hold, start;
  input [a_width-1:0] a;
  input [b_width-1:0] b;

  output complete;
  output [a_width-1 : 0] quotient;
  output [b_width-1 : 0] remainder;
  output divide_by_0;

//-----------------------------------------------------------------------------
// synopsys translate_off

localparam signed [31:0] CYC_CONT = (input_mode==1 & output_mode==1 & early_start==0)? 3 :
                                    (input_mode==early_start & output_mode==0)? 1 : 2;

//------------------------------------------------------------------------------
  // include modeling functions
`include "DW_div_function.inc"
 

//-------------------Integers-----------------------
  integer count;
  integer next_count;
 

//-----------------------------------------------------------------------------
// wire and registers 

  wire [a_width-1:0] a;
  wire [b_width-1:0] b;
  wire [b_width-1:0] in2_c;
  wire [a_width-1:0] quotient;
  wire [a_width-1:0] temp_quotient;
  wire [b_width-1:0] remainder;
  wire [b_width-1:0] temp_remainder;
  wire clk, rst_n;
  wire hold, start;
  wire divide_by_0;
  wire complete;
  wire temp_div_0;
  wire start_n;
  wire start_rst;
  wire int_complete;
  wire hold_n;

  reg [a_width-1:0] next_in1;
  reg [b_width-1:0] next_in2;
  reg [a_width-1:0] in1;
  reg [b_width-1:0] in2;
  reg [b_width-1:0] ext_remainder;
  reg [b_width-1:0] next_remainder;
  reg [a_width-1:0] ext_quotient;
  reg [a_width-1:0] next_quotient;
  reg run_set;
  reg ext_div_0;
  reg next_div_0;
  reg start_r;
  reg ext_complete;
  reg next_complete;
  reg temp_div_0_ff;

  wire [b_width-1:0] b_mux;
  reg [b_width-1:0] b_reg;
  reg pr_state;
  reg rst_n_clk;
  reg nxt_complete;
  wire reset_st;
  wire nx_state;

//-----------------------------------------------------------------------------
  
  
 
  initial begin : parameter_check
    integer param_err_flg;

    param_err_flg = 0;
    
    
    if (a_width < 3) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter a_width (lower bound: 3)",
	a_width );
    end
    
    if ( (b_width < 3) || (b_width > a_width) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter b_width (legal range: 3 to a_width)",
	b_width );
    end
    
    if ( (num_cyc < 3) || (num_cyc > a_width) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter num_cyc (legal range: 3 to a_width)",
	num_cyc );
    end
    
    if ( (tc_mode < 0) || (tc_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter tc_mode (legal range: 0 to 1)",
	tc_mode );
    end
    
    if ( (rst_mode < 0) || (rst_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter rst_mode (legal range: 0 to 1)",
	rst_mode );
    end
    
    if ( (input_mode < 0) || (input_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter input_mode (legal range: 0 to 1)",
	input_mode );
    end
    
    if ( (output_mode < 0) || (output_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter output_mode (legal range: 0 to 1)",
	output_mode );
    end
    
    if ( (early_start < 0) || (early_start > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter early_start (legal range: 0 to 1)",
	early_start );
    end
    
    if ( (input_mode===0 && early_start===1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m : Invalid parameter combination: when input_mode=0, early_start=1 is not possible" );
    end

  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 


//------------------------------------------------------------------------------

  assign start_n      = ~start;
  assign complete     = ext_complete & (~start_r);
  assign in2_c        =  input_mode == 0 ? in2 : ( int_complete == 1 ? in2 : {b_width{1'b1}});
  assign temp_quotient  = (tc_mode)? DWF_div_tc(in1, in2_c) : DWF_div_uns(in1, in2_c);
  assign temp_remainder = (tc_mode)? DWF_rem_tc(in1, in2_c) : DWF_rem_uns(in1, in2_c);
  assign int_complete = (! start && run_set) || start_rst;
  assign start_rst    = ! start && start_r;
  assign reset_st = nx_state;

  assign temp_div_0 = (b_mux == 0) ? 1'b1 : 1'b0;

  assign b_mux = ((input_mode == 1) && (start == 1'b0)) ? b_reg : b;

  always @(posedge clk) begin : a1000_PROC
    if (start == 1) begin
      b_reg <= b;
    end 
  end

// Begin combinational next state assignments
  always @ (start or hold or count or a or b or in1 or in2 or
            temp_div_0 or temp_quotient or temp_remainder or
            ext_div_0 or ext_quotient or ext_remainder or ext_complete) begin
    if (start === 1'b1) begin                       // Start operation
      next_in1       = a;
      next_in2       = b;
      next_count     = 0;
      nxt_complete   = 1'b0;
      next_div_0     = temp_div_0;
      next_quotient  = {a_width{1'bX}};
      next_remainder = {b_width{1'bX}};
    end else if (start === 1'b0) begin              // Normal operation
      if (hold === 1'b0) begin
        if (count >= (num_cyc+CYC_CONT-4)) begin
          next_in1       = in1;
          next_in2       = in2;
          next_count     = count; 
          nxt_complete   = 1'b1;
          if (run_set == 1) begin
            next_div_0     = temp_div_0;
            next_quotient  = temp_quotient;
            next_remainder = temp_remainder;
          end else begin
            next_div_0     = 0;
            next_quotient  = 0;
            next_remainder = 0;
          end
        end else if (count === -1) begin
          next_in1       = {a_width{1'bX}};
          next_in2       = {b_width{1'bX}};
          next_count     = -1; 
          nxt_complete   = 1'bX;
          next_div_0     = 1'bX;
          next_quotient  = {a_width{1'bX}};
          next_remainder = {b_width{1'bX}};
        end else begin
          next_in1       = in1;
          next_in2       = in2;
          next_count     = count+1; 
          nxt_complete   = 1'b0;
          next_div_0     = temp_div_0;
          next_quotient  = {a_width{1'bX}};
          next_remainder = {b_width{1'bX}};
        end
      end else if (hold === 1'b1) begin             // Hold operation
        next_in1       = in1;
        next_in2       = in2;
        next_count     = count; 
        nxt_complete   = ext_complete;
        next_div_0     = ext_div_0;
        next_quotient  = ext_quotient;
        next_remainder = ext_remainder;
      end else begin                                // hold = X
        next_in1       = {a_width{1'bX}};
        next_in2       = {b_width{1'bX}};
        next_count     = -1;
        nxt_complete   = 1'bX;
        next_div_0     = 1'bX;
        next_quotient  = {a_width{1'bX}};
        next_remainder = {b_width{1'bX}};
      end
    end else begin                                  // start = X 
      next_in1       = {a_width{1'bX}};
      next_in2       = {b_width{1'bX}};
      next_count     = -1;
      nxt_complete   = 1'bX;
      next_div_0     = 1'bX;
      next_quotient  = {a_width{1'bX}};
      next_remainder = {b_width{1'bX}};
    end
  end
// end combinational next state assignments
  
generate
  if (rst_mode == 0) begin : GEN_RM_EQ_0

    assign nx_state = ~rst_n | (~start_r & pr_state);

  // Begin sequential assignments   
    always @ ( posedge clk or negedge rst_n ) begin : ar_register_PROC
      if (rst_n === 1'b0) begin
        count           <= 0;
        if(input_mode == 1) begin
          in1           <= 0;
          in2           <= 0;
        end else if (input_mode == 0) begin
          in1           <= a;
          in2           <= b;
        end 
        ext_complete    <= 0;
        ext_div_0       <= 0;
        start_r         <= 0;
        run_set         <= 0;
        pr_state        <= 1;
        ext_quotient    <= 0;
        ext_remainder   <= 0;
        temp_div_0_ff   <= 0;
        rst_n_clk       <= 1'b0;
      end else if (rst_n === 1'b1) begin
        count           <= next_count;
        in1             <= next_in1;
        in2             <= next_in2;
        ext_complete    <= nxt_complete & start_n;
        ext_div_0       <= next_div_0;
        ext_quotient    <= next_quotient;
        ext_remainder   <= next_remainder;
        start_r         <= start;
        pr_state        <= nx_state;
        run_set         <= 1;
        if (start == 1'b1)
          temp_div_0_ff   <= temp_div_0;
        rst_n_clk       <= rst_n;
      end else begin                                // If nothing is activated then put 'X'
        count           <= -1;
        in1             <= {a_width{1'bX}};
        in2             <= {b_width{1'bX}};
        ext_complete    <= 1'bX;
        ext_div_0       <= 1'bX;
        ext_quotient    <= {a_width{1'bX}};
        ext_remainder   <= {b_width{1'bX}};
        temp_div_0_ff   <= 1'bX;
        rst_n_clk       <= 1'bX;
      end 
    end                                             // ar_register_PROC

  end else begin : GEN_RM_NE_0

    assign nx_state = ~rst_n_clk | (~start_r & pr_state);

  // Begin sequential assignments   
    always @ ( posedge clk ) begin : sr_register_PROC
      if (rst_n === 1'b0) begin
        count           <= 0;
        if(input_mode == 1) begin
          in1           <= 0;
          in2           <= 0;
        end else if (input_mode == 0) begin
          in1           <= a;
          in2           <= b;
        end 
        ext_complete    <= 0;
        ext_div_0       <= 0;
        start_r         <= 0;
        run_set         <= 0;
        pr_state        <= 1;
        ext_quotient    <= 0;
        ext_remainder   <= 0;
        temp_div_0_ff   <= 0;
        rst_n_clk       <= 1'b0;
      end else if (rst_n === 1'b1) begin
        count           <= next_count;
        in1             <= next_in1;
        in2             <= next_in2;
        ext_complete    <= nxt_complete & start_n;
        ext_div_0       <= next_div_0;
        ext_quotient    <= next_quotient;
        ext_remainder   <= next_remainder;
        start_r         <= start;
        pr_state        <= nx_state;
        run_set         <= 1;
        if (start == 1'b1)
          temp_div_0_ff   <= temp_div_0;
        rst_n_clk       <= rst_n;
      end else begin                                // If nothing is activated then put 'X'
        count           <= -1;
        in1             <= {a_width{1'bX}};
        in2             <= {b_width{1'bX}};
        ext_complete    <= 1'bX;
        ext_div_0       <= 1'bX;
        ext_quotient    <= {a_width{1'bX}};
        ext_remainder   <= {b_width{1'bX}};
        temp_div_0_ff   <= 1'bX;
        rst_n_clk       <= 1'bX;
      end 
   end // sr_register_PROC

  end
endgenerate

  always @ (posedge clk) begin: nxt_complete_sync_PROC
    next_complete <= nxt_complete;
  end // complete_reg_PROC

  wire corrupt_data;

generate
  if (input_mode == 0) begin : GEN_IM_EQ_0

    localparam [0:0] NO_OUT_REG = (output_mode == 0)? 1'b1 : 1'b0;
    reg [a_width-1:0] ina_hist;
    reg [b_width-1:0] inb_hist;
    wire next_corrupt_data;
    reg  corrupt_data_int;
    wire data_input_activity;
    reg  init_complete;
    wire next_alert1;
    integer change_count;

    assign next_alert1 = next_corrupt_data & rst_n & init_complete &
                                    ~start & ~complete;

    if (rst_mode == 0) begin : GEN_A_RM_EQ_0
      always @ (posedge clk or negedge rst_n) begin : ar_hist_regs_PROC
	if (rst_n === 1'b0) begin
	    ina_hist        <= a;
	    inb_hist        <= b;
	    change_count    <= 0;

	  init_complete   <= 1'b0;
	  corrupt_data_int <= 1'b0;
	end else begin
	  if ( rst_n === 1'b1) begin
	    if ((hold != 1'b1) || (start == 1'b1)) begin
	      ina_hist        <= a;
	      inb_hist        <= b;
	      change_count    <= (start == 1'b1)? 0 :
	                         (next_alert1 == 1'b1)? change_count + 1 : change_count;
	    end

	    init_complete   <= init_complete | start;
	    corrupt_data_int<= next_corrupt_data | (corrupt_data_int & ~start);
	  end else begin
	    ina_hist        <= {a_width{1'bx}};
	    inb_hist        <= {b_width{1'bx}};
	    change_count    <= -1;
	    init_complete   <= 1'bx;
	    corrupt_data_int <= 1'bX;
	  end
	end
      end
    end else begin : GEN_A_RM_NE_0
      always @ (posedge clk) begin : sr_hist_regs_PROC
	if (rst_n === 1'b0) begin
	    ina_hist        <= a;
	    inb_hist        <= b;
	    change_count    <= 0;
	  init_complete   <= 1'b0;
	  corrupt_data_int <= 1'b0;
	end else begin
	  if ( rst_n === 1'b1) begin
	    if ((hold != 1'b1) || (start == 1'b1)) begin
	      ina_hist        <= a;
	      inb_hist        <= b;
	      change_count    <= (start == 1'b1)? 0 :
	                         (next_alert1 == 1'b1)? change_count + 1 : change_count;
	    end

	    init_complete   <= init_complete | start;
	    corrupt_data_int<= next_corrupt_data | (corrupt_data_int & ~start);
	  end else begin
	    ina_hist        <= {a_width{1'bx}};
	    inb_hist        <= {b_width{1'bx}};
	    init_complete    <= 1'bx;
	    corrupt_data_int <= 1'bX;
	    change_count     <= -1;
	  end
	end
      end
    end // GEN_A_RM_NE_0

    assign data_input_activity =  (((a !== ina_hist)?1'b1:1'b0) |
				 ((b !== inb_hist)?1'b1:1'b0)) & rst_n;

    assign next_corrupt_data = (NO_OUT_REG | ~complete) &
                              (data_input_activity & ~start &
					~hold & init_complete);

`ifdef UPF_POWER_AWARE
  `protected
U>=0T_.31F]_Xc9]ELY-/U,L\KaB[^Q\-7AH8[)e3dZ(eP?9&dH>&),KFbN=)g<A
O)OC\e;89=.Ge)SOFVA;d[@SdEWaY(V9GBDVRQ,/]3)PKSP>8&QV9&)TAe3J:X.]
8XLYIdVEOXQ(g6E2)IcB^gVD;,7R&P:KGJaD169BeAf^L6WVC4VCY6]?2><<0LU7
,HAGNJ?YdSB6M@1_:?USJdVRd-^LHBD6?UL(.-^HFO1.c9K;7TI5B=+Fg=PN9-XI
M3HJ.TS.e]]1K7<UIMf0SU))JR1O#8(LCV0HZ87AUOZ3_FBC&>b-]KP-11I:6[WJ
HGF_a]T\QOS@.+)b6[;/GA:?WPAD=6MEc:/PMO[@&EZ&C6P(.;O/HG.1P6VFGSU]
\&NOIeSd0P(fa9(;\6Q->(B(HVGL^@[WO_KQ829VX\HMO#\O6CS]1VJ3:._:Q#VC
?eSP51HK5I?R,J\cCG^^J;MR;.]La<WFa[D;4>dWRE6(a:V30=4J]ME;/(5OL[CO
S(/f&@?Z;<6G-50E8J#0[.@&[YJ09(]#NI16gAW9C0bT2e^5ZT+gL?G:E?VF5?=C
;Eg4V(HDB10P2VZGFW?ZTNLMf)]I<?Y82<Hf:+gJXV@SJ]\QK;I,F]:UT\8(<3YK
..-<W&c=IS,8<.b_&=P-8YdKB7A6,H82Y\<NE_60EA+HdbZK[YUXAd426^eZK777
2)/ZY,Z.YYS.G0c8U[0dCLOMMA4/=53&QO&fbb,M6/4/6/I8AKUTcecP(5<?SQLX
DK+2f2Ya/DfA0Tc[#R_V+bT9d@Jbg5T5Ab?P4<fH)RK88@f(+,dT_DM,8]_D=I=8
RN.J=;T-C,EH(2ce4X(_<>;P]&H/)\FgYB^&=b.9A2ZUg-Dg3Q>B@\BgY,OVAYc,
VVdO-C@7,1@B#1;:Z>8)SD-fTFO/Je#/KH38R(KOb\RQ]OWgWUX^K)H<b_Hc5CK&
74ZV(G@TPN-c@a&MGYLKZB]W=PN1K+U_Md+abL7SQ#b@L4O/6\V;[fFcM69\O24-
7[V_E#?bea?gI85GG]K,#.6\M0^O#fYbX]E/fS[1R1a<;8MADM@<.65H_+];XURB
3=+4VUQHAY#]CVbgRb:@JT032e(:0NW=OA#2&<8,-0b^NW??:M\CDFg^>6cf_X,B
1RDMS@M:]-9L@?d7LRcG]VHJ5W.K@4A5E3C^9OSUUH]1,+0;PcKCO>(cTKTUXS4J
@.L5&:XDY0B2;6.[\C[CfN&XK932X@M:+Td^2E[Zc#TU@2QL+,Ha5a9ISaMN/<ME
,SSV=G6c1HJQUHa<(Nf[81-F2aYb;OD\KLO:Q#OGMQQ6@K\HZUBKBU<O7[DS#28b
XC_JH)MY=RPdFB9VQY3KRX<2K>B8CF)[F7S,DIfc@Q]1/,5gP@M&SVUf3Uf5-,[E
VWd9dbK(26YWS+9gFOY:\T+X74dC).3=b0McZaSP6Tb>^)PWF?#[0^aVZ;J)b-)/
0I/GdACSA#b4MgWc#QQ.4=V1b(QRF(F5^J_Y_M),Z<0KLbG65G9+_U--;PWJ?1BY
T(7]&9e\^QOUT1J[UL>B5aO3;b4WM2-&bG+bgbJ/39RS#Y6BW65_DUWDgCFg9KA6
HU91LVMS^+<VPSg;ZdS.a.XHP[7.R3@Nbb(f.bHS#?^[FQL4d.e?R^O7<D:\@\;0
d-G=JTD&,46)UX4;?aBO(WP.g=YQ)Eee1+IZ0B/_ZQLN1/C81K-SYLVVZBB)QaZ(
gd2\JW=F20J;V&Ff45]Y/F<NMK3=_(C.>2Z=&(d.DR])M3)ZG[a8Q_F[MQWYaV(3
;4A#A:T35W,AfL8N6OdY:/8#::KYZIdWKeK?D6e?;,GDV0)fW1V,C<(GU8F:_CV&
c?M:_9(Ae=1GYL.Z00#(O_I8g2F&96].ZdN]\cR+GVZ?E?GV<E=H-fD\/V[OZ2+Y
.f8>ab(2eTA:GK7Z@gF0,;]<4SLQb:S=GbSB>E3;J5R(=CLM\8b7A=dMPG-:GeTa
c__XfY8./;]RPU\,[63Y[,d@F?g>>@P9;9cNf8g5]NZaZdMY_KXTB:],gL[MKJ=#
#M7:ROMX^,,TRUBD-OaK@68b_W(M>DA[@E&Z0&]V;9A1gS.05/,/UC\9fU)W<P1S
7@1U\PWfG5TOfA>f8T_bfKH/W](7J>5OLX_I6A@/OU9CD9A^R(S?EOU8GTY7B)8&
W]<OO>UT5OFQgW]\>K8@1UM0TP:=bK6[]9GB_?)_[Z)N44AU0WR4_S.(##?]8ScA
UUFM/31US^5^P)DD-62>cTg;H[LNe&MJ\]^KEZM=DQ[f2[)PW.O;1C43WW\>b)H?
#36Y)P.fD.gU-J#dW_0dA)1=HEH>QV8gLCOO,Y-=YE6S=6RE.0[Z=J2[1IBX4[AF
aQX_3M^(46+/-_H-RdDG(ZeGK+17]f)/g:U:)W]\O:cb#YMH;GNI++->7+A]g77Z
DII&ZPFM)X,JJ\D5(:3Q9H_RSB0CA7@5EZV\_:_RQ=M:g,]F:FfQ3A^_#OE,K\aC
DBIJ4/_B;0.Y<TgSD]32;&F/_5(\ANX;\D+e#WK>7@g9-ZT(beHc3X46G8KGK4Ze
U(\WLBeTY_@5XAG0a_g&/1KH)dUGF-RW_9\X)RFF@ZLYR>1(AP75Jg_9<f)@c^D@
4;E=UQ+V5@S5.$
`endprotected

`else
    always @ (posedge clk) begin : corrupt_alert_PROC
      integer updated_count;

      updated_count = change_count;

      if (next_alert1 == 1'b1) begin
`ifndef DW_SUPPRESS_WARN
          $display ("WARNING: %m:\n at time = %0t: Operand input change on DW_div_seq during calculation (configured without an input register) will cause corrupted results if operation is allowed to complete.", $time);
`endif
	updated_count = updated_count + 1;
      end

      if (((rst_n & init_complete & ~start & ~complete & next_complete) == 1'b1) &&
          (updated_count > 0)) begin
	$display(" ");
	$display("############################################################");
	$display("############################################################");
	$display("##");
	$display("## Error!! : from %m");
	$display("##");
	$display("##    This instance of DW_div_seq has encountered %0d change(s)", updated_count);
	$display("##    on operand input(s) after starting the calculation.");
	$display("##    The instance is configured with no input register.");
	$display("##    So, the result of the operation was corrupted.  This");
	$display("##    message is generated at the point of completion of");
	$display("##    the operation (at time %0d), separate warning(s) were", $time );
`ifndef DW_SUPPRESS_WARN
	$display("##    generated earlier during calculation.");
`else
	$display("##    suppressed earlier during calculation.");
`endif
	$display("##");
	$display("############################################################");
	$display("############################################################");
	$display(" ");
      end
    end
`endif

    assign corrupt_data = corrupt_data_int;

  if (output_mode == 0) begin : GEN_OM_EQ_0
    reg  alert2_issued;
    wire next_alert2;

    assign next_alert2 = next_corrupt_data & rst_n & init_complete &
                                     ~start & complete & ~alert2_issued;

`ifdef UPF_POWER_AWARE
  `protected
@E1<,@ZGOSH:W7V;[4SFNM8.:PG6>cL9MFF#0\E334:L2AY:?+Ee))e<cd0e;CV5
<Z<L4U>E(M57Y;_8@I;53EGH_fe=R#(e3ZL2K:E>.D[O+bJ_IN.DT]>JgR1c97&6
<fVIO>AKH&V.fND8Fa)>e0O4+FA&LFd]L#1/,/ERf@>=4[HcNFTTA[>.fJ1FMa=,
TF.?6DcMA>;FI7988YU<L_3\U)^L@N+AEA+31@]_C?IGZ[M]b1JQ\CgS.e^X;3f@
&C@F0[)a7V6XcD6Z:\aQbV[WU.c9fO[Q8TJLZc\H@M]>c^^:/7Q4VePC4=f;0HcB
fd]JX68gfE?c6eH.]Q?)=BRQGRV8-Vd<;249<W=5VAaQXB0DJAc3U09UA_[]CbP?
6M1F[&FKBZ@g75D+.9Lg;7g)0Q+FC4Y67\c[FSKQD)=[&He9I8_@&IT@a75HW:GU
.U@d_[CC>;U;6[N(ZZV:3)#@8Q1C0e;YfI,Z_7273J^VZB=c]:-bdgZ=T/W00W;L
9b45W\Ie72XeKOdA^g5XM6[AG[&Ne3#A:^/O.B,MBKBX6IK8AVEQPKR8]aKRCgJX
5_(B0=<CQ1K?VH(EDG4G->\e>_X1(^NFX]=QL2VY;B<^1df73ab.Pe[S_0.I03_O
:f6E8<9C6NX>4g1)F\>XHgUL]2VGd-L;=$
`endprotected

`else
    always @ (posedge clk) begin : corrupt_alert2_PROC
      if (next_alert2 == 1'b1) begin
`ifndef DW_SUPPRESS_WARN
          $display ("WARNING: %m:\n at time = %0t: Operand input change on DW_div_seq during calculation (configured with neither input nor output register) causes output to no longer retain result of previous operation.", $time);
`endif
      end
    end
`endif

    if (rst_mode == 0) begin : GEN_AI_REG_AR
      always @ (posedge clk or negedge rst_n) begin : ar_alrt2_reg_PROC
        if (rst_n == 1'b0) alert2_issued <= 1'b0;

	  else alert2_issued <= ~start & (alert2_issued | next_alert2);
      end
    end else begin : GEN_AI_REG_SR
      always @ (posedge clk) begin : sr_alrt2_reg_PROC
        if (rst_n == 1'b0) alert2_issued <= 1'b0;

	  else alert2_issued <= ~start & (alert2_issued | next_alert2);
      end
    end

  end  // GEN_OM_EQ_0

  // GEN_IM_EQ_0
  end else begin : GEN_IM_NE_0
    assign corrupt_data = 1'b0;
  end // GEN_IM_NE_0
endgenerate
    

  assign quotient     = (reset_st == 1) ? {a_width{1'b0}} :
                        ((((input_mode==0)&&(output_mode==0))||(early_start==1)) & start == 1'b1) ? {a_width{1'bX}} :
                        (corrupt_data !== 1'b0)? {a_width{1'bX}} : ext_quotient;
  assign remainder    = (reset_st == 1) ? {b_width{1'b0}} :
                        ((((input_mode==0)&&(output_mode==0))||(early_start==1)) & start == 1'b1) ? {b_width{1'bX}} :
                        (corrupt_data !== 1'b0)? {b_width{1'bX}} : ext_remainder;
  assign divide_by_0  = (reset_st == 1) ? 1'b0 :
                        (input_mode == 1 && output_mode == 0 && early_start == 0) ? ext_div_0 :
                        (output_mode == 1 && early_start == 0) ? temp_div_0_ff :
                        temp_div_0_ff;

 
`ifndef DW_DISABLE_CLK_MONITOR
`ifndef DW_SUPPRESS_WARN
  always @ (clk) begin : P_monitor_clk 
    if ( (clk !== 1'b0) && (clk !== 1'b1) && ($time > 0) )
      $display ("WARNING: %m:\n at time = %0t: Detected unknown value, %b, on clk input.", $time, clk);
    end // P_monitor_clk 
`endif
`endif
// synopsys translate_on

endmodule
