module gs232c_predecoder(
    input  wire [31:0] inst       ,
    output wire        predec_bl_b,
    output wire        predec_brop,
    output wire        predec_jrop,
    output wire        predec_jrra,
    output wire        predec_link,
    output wire        predec_must,
    output wire [25:0] predec_offs,
    output wire        predec_sign 
);
wire predec_blop;
wire predec_bseg;
wire predec_bunc;
wire predec_cmpz;
wire predec_cond;
wire predec_jirl;
wire predec_rdra;
wire predec_rjra;
assign predec_bl_b = predec_bseg && predec_bunc;
assign predec_blop = predec_bunc && inst[26];
assign predec_brop = predec_bseg && (predec_cmpz || predec_cond);
assign predec_bseg = inst[31:30] == 2'h1;
assign predec_bunc = inst[29:27] == 3'h2;
assign predec_cmpz = inst[29:27] == 3'h0;
assign predec_cond = inst[29:27] == 3'h3 || inst[29:28] == 2'h2;
assign predec_jirl = inst[29:26] == 4'h3;
assign predec_jrop = predec_bseg && predec_jirl && !predec_rjra;
assign predec_jrra = predec_bseg && predec_jirl &&  predec_rjra;
assign predec_link = predec_bseg && (predec_blop || predec_jirl && predec_rdra);
assign predec_must = predec_bseg && (predec_bunc || predec_jirl);
assign predec_offs = {predec_bunc ? inst[9:5] : {5{predec_sign}},predec_cond ? {5{predec_sign}} : inst[4:0],inst[25:10]};
assign predec_rdra = inst[4 :0] == 5'h01      ;
assign predec_rjra = inst[25:0] == 26'h0000020;
assign predec_sign = predec_cond && inst[25] || predec_cmpz && inst[4] || predec_bunc && inst[9];
endmodule // gs232c_predecoder
