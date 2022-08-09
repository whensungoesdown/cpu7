`include "cache.vh"

module atom_alu(
  input [`GRLEN-1:0] a,
  input [`GRLEN-1:0] b,
  input [`ATOM_OP_WIDTH-1:0] atom_op,
  output [`GRLEN-1:0] result
);

  assign result = {`GRLEN{1'b0}}; //TODO

endmodule