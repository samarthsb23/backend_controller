// This is the main file where we will connect all blocks

/*
EE619 project 1 
Submitted by - Samarth Sharma Bhardwaj (230903)
*/

module backend(
    input i_resetbAll, i_clk, i_sclk, i_sdin, i_vco_clk,
    output o_resetb1, o_resetb2, o_resetbvco, o_ready,
    output [1:0] o_gainA1,
    output [2:0] o_gainA2
);

    wire ready_serial;

    // Instantiate the modules

    serial_comm ser(
    .i_sclk(i_sclk),
    .i_sdin(i_sdin),
    .i_reset(i_resetbAll),
    .o_gainA1(o_gainA1),
    .o_gainA2(o_gainA2),
    .ready_serial(ready_serial)
    );

    startup_fsm fsm(
        .reset_all(i_resetbAll),
        .i_clk(i_clk),
        .ready_serial(ready_serial),
        .o_ready(o_ready),
        .o_resetb1(o_resetb1),
        .o_resetb2(o_resetb2),
        .o_resetbvco(o_resetbvco)
    );

endmodule
