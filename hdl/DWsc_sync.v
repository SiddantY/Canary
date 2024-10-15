////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2005 - 2021 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Doug Lee         3/3/05
//
// VERSION:   Simulation Architecture
//
// DesignWare_version: 4e64d804
// DesignWare_release: R-2020.09-DWBB_202009.4
//
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Behavioral model of Fundamental Synchronizer for s2_sf based FIFO methods
//
//           This synchronizes incoming data into the destination domain
//           with a configurable number of sampling stages.
//
//              Parameters:     Valid Values
//              ==========      ============
//              width           [ 1 to 1024 ]
//              f_sync_type     [ 0 = single clock design, no synchronizing stages implemented,
//                                1 = 1-stage synchronization w/ pos-edge capturing,
//                                2 = 2-stage synchronization w/ both stages pos-edge capturing,
//                                3 = 3-stage synchronization w/ all stages pos-edge capturing,
//                                4 = 4-stage synchronization w/ all stages pos-edge capturing ]
//              tst_mode        [ 0 = no hold latch inserted,
//                                1 = insert hold 'latch' using a neg-edge triggered register
//                                2 = reserved (functions same as tst_mode=0 ]
//		verif_en        [ 0 = no sampling errors inserted,
//                                1 = sampling errors are randomly inserted with 0 or 1 destination clock cycle delays
//                                2 = sampling errors are randomly inserted with 0, 0.5, 1, or 1.5 destination clock cycle delays
//                                3 = sampling errors are randomly inserted with 0, 1, 2, or 3 destination clock cycle delays
//                                4 = sampling errors are randomly inserted with 0 or up to 0.5 destination clock cycle delays ]
//              
//              Input Ports:    Size    Description
//              ===========     ====    ===========
//              clk_d           1 bit   Destination Domain Input Clock
//              rst_d_n         1 bit   Destination Domain Active Low Async. Reset
//		init_d_n        1 bit   Destination Domain Active Low Sync. Reset
//              data_s          N bits  Source Domain Data Input
//              test            1 bit   Test input
//
//              Output Ports    Size    Description
//              ============    ====    ===========
//              data_d          N bits  Destination Domain Data Output
//
//                Note: the value of N is equal to the 'width' parameter value
//
//
// MODIFIED: 
//              RJK   09-12-17 Derived simulation model DWsc_sync from DW_sync

module DWsc_sync (
    clk_d,
    rst_d_n,
    init_d_n,
    data_s,
    test,
    data_d
    );

parameter integer width        = 8;
parameter integer f_sync_type  = 2;
parameter integer tst_mode     = 0;
parameter integer verif_en     = 1;

input			clk_d;
input			rst_d_n;
input			init_d_n;
input  [width-1:0]      data_s;
input                   test;
output [width-1:0]      data_d;


localparam		F_SYNC_TYPE_INT = f_sync_type % 8;

  //-------------------------------------------------------------------------
  // Parameter legality check
  //-------------------------------------------------------------------------



  wire [width-1:0]       data_s_int;
  reg  [width-1:0]       ndata1_int;
  reg  [width-1:0]       data1_int;
  reg  [width-1:0]       data_d2_int;
  reg  [width-1:0]       data_d3_int;
  reg  [width-1:0]       data_d4_int;
  reg  [width-1:0]       test_nout1_int;

  wire [width-1:0]       next_data1_int;
  wire [width-1:0]       next_data_d2_int;
  wire [width-1:0]       next_data_d3_int;
  wire [width-1:0]       tst_mode_sel_data;
  wire [width-1:0]       f_sync_type0_data;


  `ifdef DW_MODEL_MISSAMPLES





reg     [width-1:0]     test_hold_ms;
wire			hclk_odd;
reg  [width-1:0]	last_data_dyn, data_s_delta_t;
reg  [width-1:0]	last_data_s, last_data_s_q, last_data_s_qq;
wire [width-1:0]	data_s_sel_0, data_s_sel_1;
reg  [width-1:0]	data_select; initial data_select = 0;
reg  [width-1:0]	data_select_2; initial data_select_2 = 0;

  always @ (negedge clk_d or negedge rst_d_n) begin : PROC_test_hold_ms_registers
    if (rst_d_n == 1'b0) begin
      test_hold_ms        <= {width{1'b0}};
    end else if (init_d_n == 1'b0) begin
      test_hold_ms        <= {width{1'b0}};
    end else begin
      test_hold_ms        <= data_s;
    end
  end
reg			init_dly_n;


  always @ (posedge hclk_odd or data_s or rst_d_n) begin : PROC_catch_last_data
    data_s_delta_t <= (data_s | (data_s ^ data_s)) & {width{rst_d_n}} & {width{init_dly_n}};
    last_data_dyn <= data_s_delta_t & {width{rst_d_n}} & {width{init_dly_n}};
  end // PROC_catch_last_data

generate if ((verif_en % 2) == 1) begin : GEN_HO_VE_EVEN
  assign hclk_odd = clk_d;
end else begin : GEN_HO_VE_ODD
  assign hclk_odd = ~clk_d;
end
endgenerate

  always @ (posedge clk_d or negedge rst_d_n) begin : PROC_missample_hist_even
    if (rst_d_n == 1'b0) begin
      last_data_s_q  <= {width{1'b0}};
      init_dly_n     <= 1'b1;
    end else if (init_d_n == 1'b0) begin
      last_data_s_q  <= {width{1'b0}};
      init_dly_n     <= 1'b0;
    end else begin
      last_data_s_q <= last_data_s;
      init_dly_n     <= 1'b1;
    end
  end // PROC_missample_hist_even

  always @ (posedge hclk_odd or negedge rst_d_n) begin : PROC_missample_hist_odd
    if (rst_d_n == 1'b0) begin
      last_data_s <= {width{1'b0}};
      last_data_s_qq  <= {width{1'b0}};
    end else if (init_d_n == 1'b0) begin
      last_data_s <= {width{1'b0}};
      last_data_s_qq  <= {width{1'b0}};
    end else begin
      last_data_s <= (data_s | (data_s ^ data_s));
      last_data_s_qq <= last_data_s_q;
    end
  end // PROC_missample_hist_odd

  always @ (data_s or last_data_s) begin : PROC_mk_next_data_select
    if (data_s != last_data_s) begin
      data_select = wide_random(width);

      if ((verif_en == 2) || (verif_en == 3))
	data_select_2 = wide_random(width);
      else
	data_select_2 = {width{1'b0}};
    end
  end  // PROC_mk_next_data_select

  assign data_s_sel_0 = (verif_en < 1)? data_s : ((data_s & ~data_select) | (last_data_dyn & data_select));

  assign data_s_sel_1 = (verif_en < 2)? {width{1'b0}} : ((last_data_s_q & ~data_select) | (last_data_s_qq & data_select));

  assign data_s_int = ((data_s_sel_0 & ~data_select_2) | (data_s_sel_1 & data_select_2));


  function [width-1:0] wide_random;
    input [31:0]        in_width;   // should match "width" parameter -- need one input to satisfy Verilog function requirement

    reg   [width-1:0]   temp_result;
    reg   [31:0]        rand_slice;
    integer             i, j, base;


    begin
      temp_result = $random;
      if (((width / 32) + 1) > 1) begin
        for (i=1 ; i < ((width / 32) + 1) ; i=i+1) begin
          base = i << 5;
          rand_slice = $random;
          for (j=0 ; ((j < 32) && (base+j < in_width)) ; j=j+1) begin
            temp_result[base+j] = rand_slice[j];
          end
        end
      end

      wide_random = temp_result;
    end
  endfunction  // wide_random

  initial begin : seed_random_PROC
    integer seed, init_rand;
    `ifdef DW_MISSAMPLE_SEED
      seed = `DW_MISSAMPLE_SEED;
    `else
      seed = 32'h0badbeef;
    `endif

    init_rand = $random(seed);
  end // seed_random_PROC







  `else
  assign data_s_int = (data_s | (data_s ^ data_s));
  `endif



  assign tst_mode_sel_data  = (tst_mode == 1) ? test_nout1_int : data_s;

  assign f_sync_type0_data  = (test == 1'b1) ? tst_mode_sel_data : data_s;

  assign next_data1_int     = (test == 1'b0) ? data_s_int : tst_mode_sel_data; 


  generate
    if ((f_sync_type & 7) == 1) begin : GEN_NXT_SMPL_SM1_FST_EQUAL1
      assign next_data_d2_int = ndata1_int;
    end
    if ((f_sync_type & 7) > 1) begin : GEN_NXT_SMPL_SM1_FST_GRTH1
      assign next_data_d2_int = data1_int;
    end
  endgenerate
				
  always @(negedge clk_d or negedge rst_d_n) begin : a1000_PROC
    if (rst_d_n === 1'b0) begin
      ndata1_int     <= {width{1'b0}}; 
      test_nout1_int <= {width{1'b0}};
    end else if (rst_d_n === 1'b1) begin
      if (init_d_n === 1'b0) begin
        ndata1_int     <= {width{1'b0}};
        test_nout1_int <= {width{1'b0}};
      end else if (init_d_n === 1'b1) begin
        ndata1_int     <= data_s_int; 
        test_nout1_int <= data_s;
      end else begin
        ndata1_int     <= {width{1'bX}};
        test_nout1_int <= {width{1'bX}};
      end
    end else begin
      ndata1_int     <= {width{1'bX}}; 
      test_nout1_int <= {width{1'bX}};
    end
  end

  always @(posedge clk_d or negedge rst_d_n) begin : a1001_PROC
    if (rst_d_n === 1'b0) begin
      data1_int          <= {width{1'b0}};
      data_d2_int        <= {width{1'b0}};
      data_d3_int        <= {width{1'b0}};
      data_d4_int        <= {width{1'b0}};
    end else if (rst_d_n === 1'b1) begin
      if (init_d_n === 1'b0) begin
        data1_int          <= {width{1'b0}};
        data_d2_int        <= {width{1'b0}};
        data_d3_int        <= {width{1'b0}};
        data_d4_int        <= {width{1'b0}};
      end else if (init_d_n === 1'b1) begin
        data1_int          <= next_data1_int; 
        data_d2_int        <= next_data_d2_int;
        data_d3_int        <= data_d2_int;
        data_d4_int        <= data_d3_int;
      end else begin
        data1_int          <= {width{1'bX}};
        data_d2_int        <= {width{1'bX}};
        data_d3_int        <= {width{1'bX}};
        data_d4_int        <= {width{1'bX}};
      end
    end else begin
      data1_int          <= {width{1'bX}};
      data_d2_int        <= {width{1'bX}};
      data_d3_int        <= {width{1'bX}};
      data_d4_int        <= {width{1'bX}};
    end
  end

  assign data_d = (F_SYNC_TYPE_INT == 0) ? f_sync_type0_data :
		    (F_SYNC_TYPE_INT == 3) ? data_d3_int : 
                      (F_SYNC_TYPE_INT == 4) ? data_d4_int :
		        (F_SYNC_TYPE_INT == 1)? data1_int : data_d2_int;
			  

  

endmodule
/* vcs gen_ip dbg_ip off */
 /* */
