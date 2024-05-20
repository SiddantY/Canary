//-----------------------------------------------------------------------------
// Title         : random_tb
// Project       : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File          : random_tb.sv
// Author        : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_tb
import rv32i_types_1::*;
(
  // mem_itf.mem itf

  mem_itf.mem itf_i,
  mem_itf.mem itf_d

);

  `include "../../hvl/randinst.svh"

  RandInst gen = new();

  task nop();
    @(posedge itf_i.clk iff (itf_i.rmask == 4'b1111));
      itf_i.rdata <= 32'h00000013;
      itf_i.resp <= 1'b1;
  endtask

  // Do a bunch of LUIs to get useful register state.
  task init_register_state();
    for (int i = 0; i < 32; ++i) begin
      @(posedge itf_i.clk iff itf_i.rmask);
      gen.randomize() with {
        instr.j_type.opcode == op_lui;
        instr.j_type.rd == i[4:0];
      };

      // Your code here: package these memory interactions into a task.
      itf_i.rdata <= gen.instr.word;
      itf_i.resp <= 1'b1;
      // @(posedge itf_i.clk) itf_i.resp <= 1'b0;
      // for (int k = 0; k < 5; k++) begin
      //   nop();
      // end

    end
  endtask : init_register_state

  // Note that this memory model is not consistent! It ignores
  // writes and always reads out a random, valid instruction.
  task run_random_instrs();
    repeat (500000) begin
      @(posedge itf_i.clk iff ((itf_i.rmask) || itf_d.rmask));

      if (itf_d.rmask && itf_d.wmask) begin
        $error("Simultaneous read and write to memory model!");
      end

      // Always read out a valid instruction.
      if (itf_i.rmask) begin
        gen.randomize();
        itf_i.rdata <= gen.instr.word;
      end

      // If it's a write, do nothing and just respond.
      itf_i.resp <= 1'b1;

      if (itf_d.wmask) begin
        itf_d.resp <= 1'b1;
      end

      else if (itf_d.rmask) begin
        itf_d.rdata <= 32'b0;
        itf_d.resp <= 1'b1;
      end 
      
      else begin
        itf_d.resp <= 1'b0;
      end


      // @(posedge itf_i.clk) itf_i.resp <= 1'b0;
      // for (int k = 0; k < 5; k++) begin
      //   nop();
      // end
      
    end
  endtask : run_random_instrs

  // A single initial block ensures random stability.
  initial begin

    // Wait for reset.
    @(posedge itf_i.clk iff itf_i.rst == 1'b0);

    // Get some useful state into the processor by loading in a bunch of state.
    init_register_state();

    // Run!
    run_random_instrs();

    // Finish up
    $display("Random testbench finished!");
    $finish;
  end

endmodule : random_tb