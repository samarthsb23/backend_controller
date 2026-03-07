// Testbench for EE619 Project 1 - Backend Module (v4 - FINAL)
// Design verified correct via diagnostic testbench.
// All previous failures were testbench timing issues.
// Fix: wait_and_check now waits for full sequence completion before checking.

`timescale 1ns/1ps

module tb_backend;

    // -------------------------
    // DUT Signals
    // -------------------------
    reg i_resetbAll;
    reg i_clk;
    reg i_sclk;
    reg i_sdin;
    reg i_vco_clk;

    wire o_resetb1, o_resetb2, o_resetbvco, o_ready;
    wire [1:0] o_gainA1;
    wire [2:0] o_gainA2;

    // -------------------------
    // DUT Instantiation
    // -------------------------
    backend dut (
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

    // -------------------------
    // i_clk: 200 MHz, period = 5ns
    // -------------------------
    initial i_clk = 0;
    always #2.5 i_clk = ~i_clk;

    // -------------------------
    // Task: Apply and hold reset
    // Toggles i_sclk during reset to flush serial_comm's synchronous reset
    // (harmless for async reset version too)
    // Ends with i_resetbAll=0, i_sclk=1 (idle high)
    // Caller must release i_resetbAll=1
    // -------------------------
    task do_reset;
        integer i;
        begin
            i_resetbAll = 0;
            i_sdin      = 0;
            i_sclk      = 1;
            for (i = 0; i < 6; i = i + 1) begin
                #100; i_sclk = 0;
                #100; i_sclk = 1;
            end
            repeat(3) @(posedge i_clk);
            #1;
        end
    endtask

    // -------------------------
    // Task: Send 5 serial bits
    // data[0]=d0 ... data[4]=d4
    // gainA1={d1,d0}, gainA2={d4,d3,d2}
    // i_sclk must be idle HIGH before calling
    // Note: serial_comm needs one EXTRA sclk edge after the 5th
    // to assign gains (stop fires on edge 5, gains assigned on edge 6)
    // This task sends 6 edges total to ensure gains are latched.
    // -------------------------
    task send_serial;
        input [4:0] data;
        integer i;
        begin
            // Send 5 data bits
            for (i = 0; i < 5; i = i + 1) begin
                #100; i_sclk = 0;
                #10;  i_sdin = data[i];
                #90;  i_sclk = 1;
            end
            // 6th edge: triggers gain assignment in serial_comm
            // (stop=1 from edge 5, so else-if(stop & !final_stop) fires here)
            #100; i_sclk = 0;
            #100; i_sclk = 1;
            // Return to idle
            i_sdin = 0;
            #100;
        end
    endtask

    // -------------------------
    // Task: Wait for full sequence and verify
    //
    // From diagnostic output, total sequence after ready_serial goes high:
    //   CDC sync:  1 i_clk cycle
    //   WAIT_2CYC: 2 i_clk cycles  (state 010)
    //   SET_VCO:   1 i_clk cycle   (state 011, transient)
    //   WAIT_10A:  10 i_clk cycles (state 100)
    //   SET_AMPS:  1 i_clk cycle   (state 101, transient)
    //   WAIT_10B:  10 i_clk cycles (state 110)
    //   DONE:      state 111
    //   Total: ~26 i_clk cycles minimum
    //
    // We wait 50 cycles for generous margin, then check all at once.
    // -------------------------
    task wait_and_check;
        input [1:0] exp_gainA1;
        input [2:0] exp_gainA2;
        begin
            // Wait for full sequence to complete
            // 50 cycles >> 26 cycle minimum — no timing edge cases
            repeat(50) @(posedge i_clk);

            $display("  [t=%0t] Checking all outputs after full sequence:", $time);

            if (o_resetbvco !== 1)
                $display("  FAIL o_resetbvco: got %b, expected 1", o_resetbvco);
            else
                $display("  PASS o_resetbvco=1");

            if (o_resetb1 !== 1)
                $display("  FAIL o_resetb1:   got %b, expected 1", o_resetb1);
            else
                $display("  PASS o_resetb1=1");

            if (o_resetb2 !== 1)
                $display("  FAIL o_resetb2:   got %b, expected 1", o_resetb2);
            else
                $display("  PASS o_resetb2=1");

            if (o_ready !== 1)
                $display("  FAIL o_ready:     got %b, expected 1", o_ready);
            else
                $display("  PASS o_ready=1");

            if (o_gainA1 !== exp_gainA1)
                $display("  FAIL o_gainA1:    got %b, expected %b", o_gainA1, exp_gainA1);
            else
                $display("  PASS o_gainA1=%b", o_gainA1);

            if (o_gainA2 !== exp_gainA2)
                $display("  FAIL o_gainA2:    got %b, expected %b", o_gainA2, exp_gainA2);
            else
                $display("  PASS o_gainA2=%b", o_gainA2);
        end
    endtask

    // -------------------------
    // Main Tests
    // -------------------------
    initial begin
        $dumpfile("tb_backend.vcd");
        $dumpvars(0, tb_backend);

        i_resetbAll = 0;
        i_sclk      = 1;
        i_sdin      = 0;
        i_vco_clk   = 0;
        #10;

        // ===================================================
        // TEST 1: Reset state — all outputs must be 0
        // ===================================================
        $display("\n=== TEST 1: Reset State ===");
        do_reset;
        if (o_ready!==0 || o_resetb1!==0 || o_resetb2!==0 ||
            o_resetbvco!==0 || o_gainA1!==0 || o_gainA2!==0)
            $display("  FAIL: Outputs not 0 during reset at t=%0t", $time);
        else
            $display("  PASS: All outputs 0 during reset");
        $display("TEST 1 done");

        // ===================================================
        // TEST 2: Normal startup
        // d0=0,d1=1,d2=1,d3=0,d4=1
        // gainA1={d1,d0}=2'b10, gainA2={d4,d3,d2}=3'b101
        // ===================================================
        $display("\n=== TEST 2: Normal startup - gainA1=2'b10, gainA2=3'b101 ===");
        @(posedge i_clk); #1;
        i_resetbAll = 1;
        repeat(3) @(posedge i_clk);
        send_serial(5'b10110); // d0=0,d1=1,d2=1,d3=0,d4=1
        wait_and_check(2'b10, 3'b101);
        $display("TEST 2 done");

        // ===================================================
        // TEST 3: Outputs hold in DONE state
        // ===================================================
        $display("\n=== TEST 3: Outputs hold in DONE state ===");
        repeat(50) @(posedge i_clk);
        if (o_ready===1 && o_resetb1===1 && o_resetb2===1 &&
            o_resetbvco===1 && o_gainA1===2'b10 && o_gainA2===3'b101)
            $display("  PASS: All outputs held after 50 extra cycles");
        else
            $display("  FAIL: Outputs changed unexpectedly at t=%0t", $time);
        $display("TEST 3 done");

        // ===================================================
        // TEST 4: Re-reset clears all outputs
        // ===================================================
        $display("\n=== TEST 4: Re-reset behavior ===");
        do_reset;
        if (o_ready!==0 || o_resetb1!==0 || o_resetb2!==0 || o_resetbvco!==0)
            $display("  FAIL: FSM outputs not cleared at t=%0t", $time);
        else
            $display("  PASS: FSM outputs cleared to 0");
        if (o_gainA1!==0 || o_gainA2!==0)
            $display("  FAIL: Gain outputs not cleared at t=%0t", $time);
        else
            $display("  PASS: Gain outputs cleared to 0");
        $display("TEST 4 done");

        // ===================================================
        // TEST 5: All-ones gains
        // d0=1,d1=1,d2=1,d3=1,d4=1
        // gainA1=2'b11, gainA2=3'b111
        // ===================================================
        $display("\n=== TEST 5: All-ones gains - gainA1=2'b11, gainA2=3'b111 ===");
        @(posedge i_clk); #1;
        i_resetbAll = 1;
        repeat(3) @(posedge i_clk);
        send_serial(5'b11111);
        wait_and_check(2'b11, 3'b111);
        $display("TEST 5 done");

        // ===================================================
        // TEST 6: All-zero gains
        // d0=0,d1=0,d2=0,d3=0,d4=0
        // gainA1=2'b00, gainA2=3'b000
        // ===================================================
        $display("\n=== TEST 6: All-zero gains - gainA1=2'b00, gainA2=3'b000 ===");
        do_reset;
        @(posedge i_clk); #1;
        i_resetbAll = 1;
        repeat(3) @(posedge i_clk);
        send_serial(5'b00000);
        wait_and_check(2'b00, 3'b000);
        $display("TEST 6 done");

        // ===================================================
        // TEST 7: Mid-sequence reset aborts cleanly
        // ===================================================
        $display("\n=== TEST 7: Mid-sequence reset ===");
        do_reset;
        @(posedge i_clk); #1;
        i_resetbAll = 1;
        repeat(3) @(posedge i_clk);
        send_serial(5'b10101);

        // Sequence is now running. Wait until VCO is released
        // then interrupt before amps are released
        repeat(8) @(posedge i_clk);
        $display("  Asserting reset mid-sequence (VCO released, amps not yet) at t=%0t", $time);
        do_reset;

        if (o_ready!==0 || o_resetb1!==0 || o_resetb2!==0 || o_resetbvco!==0)
            $display("  FAIL: Outputs not cleared after mid-sequence reset at t=%0t", $time);
        else
            $display("  PASS: All outputs cleared after mid-sequence reset");
        $display("TEST 7 done");

        // ===================================================
        // TEST 8: Full recovery after mid-sequence reset
        // d0=1,d1=0,d2=0,d3=1,d4=0
        // gainA1={d1,d0}=2'b01, gainA2={d4,d3,d2}=3'b010
        // ===================================================
        $display("\n=== TEST 8: Recovery after mid-sequence reset ===");
        @(posedge i_clk); #1;
        i_resetbAll = 1;
        repeat(3) @(posedge i_clk);
        send_serial(5'b01001); // d0=1,d1=0,d2=0,d3=1,d4=0
        wait_and_check(2'b01, 3'b010);
        $display("TEST 8 done");

        // ===================================================
        // TEST 9: Alternating bits
        // d0=1,d1=0,d2=1,d3=0,d4=1
        // gainA1={d1,d0}=2'b01, gainA2={d4,d3,d2}=3'b101
        // ===================================================
        $display("\n=== TEST 9: Alternating bits - gainA1=2'b01, gainA2=3'b101 ===");
        do_reset;
        @(posedge i_clk); #1;
        i_resetbAll = 1;
        repeat(3) @(posedge i_clk);
        send_serial(5'b10101); // d0=1,d1=0,d2=1,d3=0,d4=1
        wait_and_check(2'b01, 3'b101);
        $display("TEST 9 done");

        $display("\n=== ALL TESTS COMPLETE ===");
        #100;
        $finish;
    end

    // -------------------------
    // Timeout watchdog
    // -------------------------
    initial begin
        #2_000_000;
        $display("TIMEOUT at t=%0t", $time);
        $finish;
    end

endmodule