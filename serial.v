module serial_comm (
    input i_sclk,
    input i_sdin,
    input i_reset, // this will be an active low reset
    output reg [1:0] o_gainA1,
    output reg [2:0] o_gainA2,
    output reg ready_serial
);

reg [4:0] d; 
reg [2:0] count;
reg stop, final_stop;

always @(posedge i_sclk or negedge i_reset) begin //asynch reset

    if(!i_reset) begin 
        d <= 0;
        ready_serial <= 0;
        o_gainA1 <= 0;
        o_gainA2 <= 0;
        count <= 0;
        stop <= 0;
        final_stop <= 0;
    end

    else if (stop & !(final_stop)) begin 
        // I am updating the gains one clk edge after the 5th clk edge 
        // this is done solely for ease of design. 
        o_gainA1[0] <= d[0];
        o_gainA1[1] <= d[1];
        o_gainA2[0] <= d[2];
        o_gainA2[1] <= d[3];
        o_gainA2[2] <= d[4];
        ready_serial <= 1;
        final_stop <= 1; // this will now ensure that gains are assigned only once
    end

    else if (!stop) begin 

        // Sample the input
        d[count] <= i_sdin;

        count <= count + 1;
        if(count == (3'b100)) stop <= 1;

    end

end

endmodule