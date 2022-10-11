`include "common.vh"

module cpu7_exu(

   input                   clk,
   input                   resetn,

   input                   port0_valid,
   input  [`GRLEN-1:0]     port0_pc,
   input  [31:0]	   port0_inst,
   input  [`LSOC1K_DECODE_RES_BIT-1:0]  port0_op,
   input  [`GRLEN-3:0]     port0_br_target,
   input                   port0_br_taken,
   input                   port0_exception,
   input  [5:0]            port0_exccode,
   input                   port0_rf_wen,
   input  [4:0]            port0_rf_target,
   input  [`LSOC1K_PRU_HINT:0] port0_hint,

    //debug interface
    output  [`GRLEN-1:0]   debug0_wb_pc,
    output                 debug0_wb_rf_wen,
    output  [ 4:0]         debug0_wb_rf_wnum,
    output  [`GRLEN-1:0]   debug0_wb_rf_wdata,
    
    output  [`GRLEN-1:0]   debug1_wb_pc,
    output                 debug1_wb_rf_wen,
    output  [ 4:0]         debug1_wb_rf_wnum,
    output  [`GRLEN-1:0]   debug1_wb_rf_wdata
   );

   // test
   assign debug0_wb_pc = port0_pc;
   assign debug0_wb_rf_wen = port0_rf_wen;
   assign debug0_wb_rf_wnum = 5'b0;
   assign debug0_wb_rf_wdata = port0_pc;
   
//   assign debug0_wb_pc = `GRLEN'b0;
//   assign debug0_wb_rf_wen = 1'b0;
//   assign debug0_wb_rf_wnum = 5'b0;
//   assign debug0_wb_rf_wdata = `GRLEN'b0;
//
//   assign debug1_wb_pc = `GRLEN'b0;
//   assign debug1_wb_rf_wen = 1'b0;
//   assign debug1_wb_rf_wnum = 5'b0;
//   assign debug1_wb_rf_wdata = `GRLEN'b0;

endmodule // cpu7_exu
