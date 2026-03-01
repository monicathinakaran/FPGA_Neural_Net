`timescale 1ns / 1ps

module top_tb();
    // 1. Declare Signals
    reg clk;
    reg rst;
    reg start;
    reg signed [7:0] pixel_stream_in;
    
    wire signed [15:0] neuron_out;
    wire done;

    // 2. Instantiate the Motherboard (Top Module)
    neuron_top uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .pixel_stream_in(pixel_stream_in),
        .neuron_out(neuron_out),
        .done(done)
    );

    // 3. Generate 100MHz Clock
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        start = 0;
        pixel_stream_in = 0;

        // Reset the system
        #100;
        rst = 0;
        #20;

        // 4. Send the START pulse to wake up the FSM Brain
        start = 1;
        @(posedge clk);
        start = 0;

        // 5. Stream 784 pixels (simulating an incoming 28x28 image)
        for (i = 0; i < 784; i = i + 1) begin
            pixel_stream_in = $random % 128; // Feed a random pixel value
            @(posedge clk);
        end

        // 6. Wait for the Brain to assert the 'done' signal
        wait(done == 1'b1);
        
        // Let the waveform run a little longer so we can see the final output
        #50;
        
        // Print the final result to the Vivado Tcl Console
        $display("Simulation Finished!");
        $display("Final Activated Output: %d", neuron_out);
        
        $finish;
    end
endmodule