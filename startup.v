// This is the file where the FSM design would be created 

module startup_fsm(
    input reset_all, //Active low 
    input i_clk,
    input ready_serial, // This would come from the serial_comm module showing data has been transferred 
    output reg o_ready,
    output reg o_resetb1,  //Active low for amp1
    output reg o_resetb2, //Active low for amp2
    output reg o_resetbvco //Active low for VCO
);

// We need to handle the clock domain crossing part. 
// Ready serial comes from i_sclk clock and now we have a high freq i_clk
// This needs to be taken care of using a synchornizer 

    reg ready_sync1, ready_sync2;

    always @(posedge i_clk) begin
        if (!reset_all) begin
            ready_sync1 <= 0;
            ready_sync2 <= 0;
        end else begin
            ready_sync1 <= ready_serial;
            ready_sync2 <= ready_sync1;
        end
    end

    // Now we can start with the actual FSM now that CDC is handeled 
    
    // State encoding. We have 8 states (2 of these are similar so they might be reducable)
    // I am doing a Moore implementation now, but a Mealey can be done to save the last state
    // But still we would need 3 flip flops even in moore
    parameter RST=3'b000; //reset_all
    parameter WAIT_SERIAL =3'b001; //wait_serial
    parameter WAIT_2CYC = 3'b010;
    parameter SET_VCO = 3'b011;
    parameter WAIT_10A = 3'b100;
    parameter SET_AMPS = 3'b101;
    parameter WAIT_10B = 3'b110;
    parameter DONE = 3'b111;

    //Registers for FSM
    reg [2:0] current_state, next_state;
    reg [3:0] counter; // counter for the delay blocks

    // Sequential logic to update states

    always @(posedge i_clk) begin //The PS does not mention a reset type. Assuming synchronous reset for simplicity

    if(!reset_all) begin 
        counter <= 0;
        current_state <= RST; //Since active low, this handles reset here so we wont have to do it again and again in each state
    end

    else begin 
        current_state <= next_state;
        if (current_state != next_state) begin //during transitions
            counter <= 0;
        end

        else counter <= counter + 1; //increment counter to find delay
    end

    end

    //Combinational logic that just sets the next state and all corresponding outputs

    always @(*) begin
        // default outputs
        o_ready = 0;
        o_resetb1 = 0;
        o_resetb2 = 0;
        o_resetbvco = 0;

        next_state = current_state;
        case(current_state)
            RST: begin
                // Reset all backend outputs and other regs
                o_ready = 0;
                o_resetb1 = 0;
                o_resetb2 = 0;
                o_resetbvco = 0;

                if(reset_all) next_state = WAIT_SERIAL;

            end

            WAIT_SERIAL: begin 
                // serial comm would happen and set the ready-serial high, which after CDC synchronization has become ready_sync2
                if (ready_sync2) next_state = WAIT_2CYC;

            end

            WAIT_2CYC: begin
                if (counter == 2) next_state = SET_VCO; //counter set in the sequential block above
            end

            SET_VCO: begin 
                o_resetbvco = 1;
                next_state = WAIT_10A;

            end

            WAIT_10A: begin
                o_resetbvco = 1;
                if (counter == 10) next_state = SET_AMPS;
            end

            SET_AMPS: begin 
                o_resetbvco = 1;
                o_resetb1 = 1;
                o_resetb2 = 1;
                next_state = WAIT_10B;
            end

            WAIT_10B: begin 
                o_resetbvco = 1;
                o_resetb1 = 1;
                o_resetb2 = 1;
                if (counter == 10) next_state = DONE;
            end

            DONE: begin
                o_resetbvco = 1;
                o_resetb1 = 1;
                o_resetb2 = 1; // Hold all values
                o_ready = 1; // Chip is ready!
            end

            default: next_state = RST; //for synthesizability


        endcase

    end

endmodule