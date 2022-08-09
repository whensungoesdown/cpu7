/*
//  Description:	
//  Contains the pc incrementer.
*/

module cpu7_ifu_incr30(a, a_inc, ofl);
   input  [29:0]  a;
   output [29:0]  a_inc;
   output 	  ofl;
   
   reg [29:0] 	  a_inc;
   reg 		  ofl;
   
   always @ (a)
     begin
	      a_inc = a + (30'b1);
	      ofl = (~a[29]) & a_inc[29];
     end
   
   
   
endmodule // sparc_ifu_incr46


