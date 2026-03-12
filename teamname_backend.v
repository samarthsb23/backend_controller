module backend( i_resetbAll,
		i_clk,
		i_sclk,
		i_sdin,
		i_vco_clk,
		o_ready,
		o_resetb1,
		o_gainA1,
		o_resetb2,
		o_gainA2,
		o_resetbvco);

input i_resetbAll, i_clk, i_sclk, i_sdin, i_vco_clk;
output reg o_ready, o_resetb1, o_resetb2, o_resetbvco;
output reg [1:0] o_gainA1;
output reg [2:0] o_gainA2;

endmodule

