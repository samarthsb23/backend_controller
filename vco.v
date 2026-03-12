module vco ( 	i_resetbvco, 
		o_vcoclk );

input i_resetbvco;
output o_vcoclk;
reg vcoclk1;

assign o_vcoclk = (i_resetbvco)?vcoclk1:0;

initial 
begin
	vcoclk1 <= 0;
end

always #2 vcoclk1 <= ~vcoclk1;


endmodule


// if i_resetbvco is x or z, the vco model will not behave correctly.

	
