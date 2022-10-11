`include "common.vh"


module lsoc1000_stage_de1(
    input               clk,
    input               resetn,
    input               allow_in,
    // port0
    input                      de1_port0_valid,
    input [`GRLEN-1:0]         de1_port0_pc,
    input [31:0]               de1_port0_inst,
    input [`GRLEN-3:0]         de1_port0_br_target,
    input                      de1_port0_br_taken,
    input                      de1_port0_exception,
    input [5 :0]               de1_port0_exccode,
    input [`LSOC1K_PRU_HINT:0] de1_port0_hint,
    input                      de1_port0_robr,
    // port1
    input                      de1_port1_valid,
    input [`GRLEN-1:0]         de1_port1_pc,
    input [31:0]               de1_port1_inst,
    input [`GRLEN-3:0]         de1_port1_br_target,
    input                      de1_port1_br_taken,
    input                      de1_port1_exception,
    input [5 :0]               de1_port1_exccode,
    input [`LSOC1K_PRU_HINT:0] de1_port1_hint,
    input                      de1_port1_robr,
    // port2
    input                      de1_port2_valid,
    input [`GRLEN-1:0]         de1_port2_pc,
    input [31:0]               de1_port2_inst,
    input [`GRLEN-3:0]         de1_port2_br_target,
    input                      de1_port2_br_taken,
    input                      de1_port2_exception,
    input [5 :0]               de1_port2_exccode,
    input [`LSOC1K_PRU_HINT:0] de1_port2_hint,
    input                      de1_port2_robr,
    // port0
    output                      de2_port0_valid,
    output [31:0]               de2_port0_inst,
    output [`GRLEN-1:0]         de2_port0_pc,
    output                      de2_port0_exception,
    output [5 :0]               de2_port0_exccode,
    output [`GRLEN-3:0]         de2_port0_br_target,
    output                      de2_port0_br_taken,
    output [`LSOC1K_PRU_HINT:0] de2_port0_hint,
    // port1
    output                      de2_port1_valid,
    output [31:0]               de2_port1_inst,
    output [`GRLEN-1:0]         de2_port1_pc,
    output                      de2_port1_exception,
    output [5 :0]               de2_port1_exccode,
    output [`GRLEN-3:0]         de2_port1_br_target,
    output                      de2_port1_br_taken,
    output [`LSOC1K_PRU_HINT:0] de2_port1_hint,
    // port2
    output                      de2_port2_valid,
    output [31:0]               de2_port2_inst,
    output [`GRLEN-1:0]         de2_port2_pc,
    output                      de2_port2_exception,
    output [5 :0]               de2_port2_exccode,
    output [`GRLEN-3:0]         de2_port2_br_target,
    output                      de2_port2_br_taken,
    output [`LSOC1K_PRU_HINT:0] de2_port2_hint
);

// define
wire rst = !resetn;

assign de2_port0_valid    = de1_port0_valid    ;
assign de2_port0_inst     = de1_port0_inst     ;
assign de2_port0_pc       = de1_port0_pc       ;
assign de2_port0_exception= de1_port0_exception;
assign de2_port0_exccode  = de1_port0_exccode  ;
assign de2_port0_br_target= de1_port0_br_target;
assign de2_port0_br_taken = de1_port0_br_taken ;
assign de2_port0_hint     = de1_port0_hint     ;

assign de2_port1_valid    = de1_port1_valid    ;
assign de2_port1_inst     = de1_port1_inst     ;
assign de2_port1_pc       = de1_port1_pc       ;
assign de2_port1_exception= de1_port1_exception;
assign de2_port1_exccode  = de1_port1_exccode  ;
assign de2_port1_br_target= de1_port1_br_target;
assign de2_port1_br_taken = de1_port1_br_taken ;
assign de2_port1_hint     = de1_port1_hint     ;

assign de2_port2_valid    = de1_port2_valid;
assign de2_port2_inst     = de1_port2_inst     ;
assign de2_port2_pc       = de1_port2_pc       ;
assign de2_port2_exception= de1_port2_exception;
assign de2_port2_exccode  = de1_port2_exccode  ;
assign de2_port2_br_target= de1_port2_br_target;
assign de2_port2_br_taken = de1_port2_br_taken ;
assign de2_port2_hint     = de1_port2_hint     ;

endmodule
