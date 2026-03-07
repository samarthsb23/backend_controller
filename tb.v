`timescale 1ns/1ps

module tb_backend;

reg i_resetbAll;
reg i_clk;
reg i_sclk;
reg i_sdin;
reg i_vco_clk;

wire o_resetb1;
wire o_resetb2;
wire o_resetbvco;
wire o_ready;
wire [1:0] o_gainA1;
wire [2:0] o_gainA2;


backend dut(
    .i_resetbAll(i_resetbAll),
    .i_clk(i_clk),
    .i_sclk(i_sclk),
    .i_sdin(i_sdin),
    .i_vco_clk(i_vco_clk),
    .o_resetb1(o_resetb1),
    .o_resetb2(o_resetb2),
    .o_resetbvco(o_resetbvco),
    .o_ready(o_ready),
    .o_gainA1(o_gainA1),
    .o_gainA2(o_gainA2)
);

//////////////////////////////////////////////////
// CLOCKS
//////////////////////////////////////////////////

initial i_clk = 0;
always #2.5 i_clk = ~i_clk;   // 200 MHz

initial i_sclk = 1;


//////////////////////////////////////////////////
// SERIAL SEND TASK
//////////////////////////////////////////////////

task send_serial;
input [4:0] data;
integer i;
begin
    for(i=0;i<5;i=i+1) begin
        #100 i_sclk = 0;
        i_sdin = data[i];
        #100 i_sclk = 1;
    end
end
endtask


//////////////////////////////////////////////////
// MAIN TEST
//////////////////////////////////////////////////

initial begin

    $dumpfile("wave.vcd");
    $dumpvars(0,tb_backend);

    i_resetbAll = 0;
    i_sdin = 0;
    i_vco_clk = 0;

    // reset
    repeat(5) @(posedge i_clk);

    // release reset
    i_resetbAll = 1;

    // send data
    // d0=0 d1=1 d2=1 d3=0 d4=1
    send_serial(5'b10110);

    // wait long enough for FSM
    repeat(50) @(posedge i_clk);
    $monitor("t=%0t sdin=%b count=%d gains=%b %b ready=%b",
         $time, i_sdin, dut.ser.count, o_gainA1, o_gainA2, dut.ser.ready_serial);

    $display("gainA1 = %b",o_gainA1);
    $display("gainA2 = %b",o_gainA2);
    $display("resetbvco = %b",o_resetbvco);
    $display("resetb1 = %b",o_resetb1);
    $display("resetb2 = %b",o_resetb2);
    $display("ready = %b",o_ready);

    $finish;

end

endmodule