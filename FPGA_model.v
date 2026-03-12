///////////////////////////////////////////////////////////////////////////////
/*FPGA model
 * Generates reset signal for the chip
 * Sends out progamming bits to the chip
*/
module FPGA_model(	i_resetbFPGA,
			i_ready,
			i_mainclk,
			o_resetbAll,
			o_sclk, 
			o_sdout, 
			opcode_gainA1,
			opcode_gainA2);

//============================================================================
//Parameter declarations
//parameter opcode_gainA1	= 1; //range: 0-3. Gain for amplifier 1
//parameter opcode_gainA2	= 5; //range: 0-7. Gain for amplifier 2

//FPGA states
parameter sRESET 	= 0; //Reset all internal variables. Make o_resetbAll=0.
parameter sPROGRAM	= 1; //Send programming bits to chip.
parameter sIDLE		= 2; //Do nothing.
//===========================================================================
//Input output declarations
input i_resetbFPGA; 		//resets FPGA
input i_ready;			//Alerts FPGA that chip is programmed and ready
input i_mainclk;		//Main clock
input [1:0] opcode_gainA1;
input [2:0] opcode_gainA2;

output reg o_resetbAll;		//Reset for the chip
output reg o_sclk;		//Serial clock for communication
output reg o_sdout;		//Serial data out from FPGA (to chip)


//Internal wire, reg declarations
reg [1:0] FPGAstate;		//Holds the state of FPGA
reg [3:0] count;		//Used for controlling sclk generation and transmission of serial data
reg mainclkby2, mainclkby4, mainclkby8, mainclkby16; //Low frequency clocks derived from mainclk

//=============================================================
//BEHAVIORAL DESCRIPTION
//=============================================================
// Setting the FPGA state
always @ (posedge(i_mainclk) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		FPGAstate <= sRESET;
	else
	begin
		case(FPGAstate)
		sRESET: FPGAstate <= sPROGRAM;
		sPROGRAM: 
		begin	
			if(count== 10)
				FPGAstate <= sIDLE;
			else
				FPGAstate <= sPROGRAM;
		end
		sIDLE: FPGAstate <=sIDLE;
		default: FPGAstate <= sIDLE;
		endcase
	end
end
//========================================================
/*resetbALL
 * resetbAll=0, when FPGA is reset. 
 * resetbAll=1 at all other times.
*/
always @(posedge(i_mainclk) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		o_resetbAll <= 0;
	else
	begin
		if(FPGAstate == sRESET)
			o_resetbAll <= 0;
		else
			o_resetbAll <= 1;
	end
end
//==========================================================
/* Generation of low frequency clocks from mainclk using divide-by-2 method
*/
always @ (posedge(i_mainclk) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		mainclkby2 <= 0;
	else
		mainclkby2 <= ~mainclkby2;
end

always @ (posedge(mainclkby2) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		mainclkby4 <= 0;
	else
		mainclkby4 <= ~mainclkby4;
end

always @(posedge(mainclkby4) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		mainclkby8 <= 0;
	else
		mainclkby8 <= ~mainclkby8;
end

always @(posedge(mainclkby8) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		mainclkby16 <= 0;
	else
		mainclkby16 <= ~mainclkby16;
end
//==========================================================
/*count
 * used for the generation of sclk and selecting the data to be sent in through sdin
 */
always	@(posedge(mainclkby16) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		count <= 0;
	else
	begin
		if(FPGAstate == sPROGRAM)
		begin
			if(count == 11)
				count <= count;
			else
				count <= count+1;
		end
		else
			count <= count;
	end
end
//=========================================================
/*sclk
 * sclk is a clock only when the FPGA is programming the chip.
 */
always @ (posedge(mainclkby16) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		o_sclk <= 1;
	else
	begin
		if(FPGAstate == sPROGRAM)
		begin
			if (count >= 1 && count <= 10)
				o_sclk <= ~o_sclk;
			else
				o_sclk <= 1;
		end
		else
			o_sclk <= 1;
	end
end

//=========================================================
/*sdin
 *serial data out from FPGA
 */
always @ (negedge(o_sclk) or negedge(i_resetbFPGA))
begin
	if(i_resetbFPGA == 0)
		o_sdout <= 0;
	else
	begin
		if(FPGAstate == sPROGRAM)
		begin
			case(count)
			4'd2: o_sdout <= opcode_gainA1[0];
			4'd4: o_sdout <= opcode_gainA1[1];
			4'd6: o_sdout <= opcode_gainA2[0];
			4'd8: o_sdout <= opcode_gainA2[1];
			4'd10: o_sdout <= opcode_gainA2[2];
			default: o_sdout <= o_sdout;
			endcase
		end
		else
			o_sdout <= 0;
		
	end
end
//==========================================================
endmodule
