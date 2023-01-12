`include "decoded.vh"

// ALU module
module branch(
   input                           branch_valid,
   input [`GRLEN-1:0]              branch_a,
   input [`GRLEN-1:0]              branch_b,
   input [`LSOC1K_BRU_CODE_BIT-1:0] branch_op,
   input [`GRLEN-1:0]              branch_pc,
   //    input [31:0]                    branch_inst,
   //    input                           branch_taken,
   //    input [`GRLEN-1:0]              branch_target,
   input [`GRLEN-1:0]              branch_offset,
   //    input                           cancel_allow,
   // pc interface
   //    output              bru_valid,
   //    output              bru_cancel,
   output [`GRLEN-1:0] bru_target,
   output              bru_taken,
   output [`GRLEN-1:0] bru_link_pc,
   output              bru_wen
   //    output [`GRLEN-1:0] bru_pc
   );

//define
wire take;
//wire cancel;

//BRANCHop decoder
wire op_beqz  = branch_op == `LSOC1K_BRU_EQZ;
wire op_bnez  = branch_op == `LSOC1K_BRU_NEZ;
wire op_bnc   = branch_op == `LSOC1K_BRU_JR;
wire op_beq   = branch_op == `LSOC1K_BRU_EQ;
wire op_bne   = branch_op == `LSOC1K_BRU_NE;
wire op_blt   = branch_op == `LSOC1K_BRU_LT;
wire op_bge   = branch_op == `LSOC1K_BRU_GE;
wire op_bltu  = branch_op == `LSOC1K_BRU_LTU;
wire op_bgeu  = branch_op == `LSOC1K_BRU_GEU;
wire op_jirl  = branch_op == `LSOC1K_BRU_JR;
wire op_bl    = branch_op == `LSOC1K_BRU_BL;

wire [`GRLEN-1:0] target_next;
wire [`GRLEN-1:0] target_jr;

wire from_s;

wire need_eqx;
wire need_nex;
wire need_ltx;
wire need_gex;
wire need_eqz;
wire need_nez;

wire need_any;
wire need_compute;

wire compare_unsigned;
wire compare_ltx_u;
wire compare_ltx_s;

wire cond_ltx;
wire cond_eqx;
wire cond_seqz;
wire cond_eqz;

assign from_s = 
       op_beqz
    || op_bnez;

assign need_eqx = op_beq;
assign need_nex = op_bne;
assign need_gex = op_bge || op_bgeu;
assign need_ltx = op_blt || op_bltu;
assign need_eqz = op_beqz;
assign need_nez = op_bnez;

assign need_any = 
       need_eqx
    || need_nex
    || need_gex
    || need_ltx
    || need_eqz
    || need_nez;
assign need_compute = op_jirl;

////func
//condition judge
assign compare_unsigned = op_bgeu || op_bltu;

assign compare_ltx_u = branch_a < branch_b;

//`ifdef LA64
//assign compare_ltx_s = (branch_a[63] && !branch_b[63]) || (compare_ltx_u && branch_a[63] == branch_b[63]);
//`elsif LA32
//assign compare_ltx_s = (branch_a[31] && !branch_b[31]) || (compare_ltx_u && branch_a[31] == branch_b[31]);
//`endif
assign compare_ltx_s = (branch_a[31] && !branch_b[31]) || (compare_ltx_u && branch_a[31] == branch_b[31]);

assign cond_ltx = compare_unsigned ? compare_ltx_u : compare_ltx_s;
assign cond_eqx = branch_a == branch_b;

//`ifdef LA64
//assign cond_seqz = !branch_a[63] &&!(|branch_a[62:0]);
//`elsif LA32
//assign cond_seqz = !branch_a[31] &&!(|branch_a[30:0]);
//`endif
assign cond_seqz = !branch_a[31] &&!(|branch_a[30:0]);
assign cond_eqz  = from_s && cond_seqz;

//overall condition
assign take = 
       (!need_eqz || cond_eqz)
    && (!need_nez ||!cond_eqz)
    && (!need_eqx || cond_eqx)
    && (!need_nex ||!cond_eqx)
    && (!need_ltx || cond_ltx)
    && (!need_gex ||!cond_ltx);
    
//assign cancel = need_any && take!=branch_taken || need_compute && bru_target!=branch_target;

// jump target calculate
//`ifdef LA64
//assign target_next = {branch_pc[`GRLEN-1:2]+62'd1,2'b00};
//`elsif LA32
//assign target_next = {branch_pc[`GRLEN-1:2]+30'd1,2'b00};
//`endif
   assign target_next = {branch_pc[`GRLEN-1:2]+30'd1,2'b00};

   wire [`GRLEN-1:0] target_true = {branch_pc[`GRLEN-1:2],2'b00} + branch_offset;
   assign target_jr   = branch_a + branch_offset;

   assign bru_target = 
		       ({`GRLEN{!op_jirl && take}} & target_true)
                    // ({64{!op_jirl && take}} & branch_target)
                      |({`GRLEN{!op_jirl &&!take}} & target_next)
	              |({`GRLEN{op_jirl}} & target_jr );
   //assign bru_cancel = cancel && cancel_allow;
   //assign bru_valid = branch_valid;
   assign bru_taken = take & branch_valid;
   assign bru_link_pc = target_next;
   //assign bru_pc = branch_pc;

   assign bru_wen = (op_jirl | op_bl) & branch_valid;
   
endmodule
