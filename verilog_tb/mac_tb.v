`timescale 1ns / 1ps

module mac_tb();
    // 1. Declare signals
    reg clk;
    reg rst;
    reg signed [7:0] pixel_in;
    reg signed [7:0] weight_in;
    reg valid_in;

    wire signed [15:0] mac_out;
    wire valid_out;

    // 2. Create a memory array to hold weights from Python
    // We declare a 1D array of 8-bit registers, 784 deep (for 28x28 image)
    reg [7:0] weight_mem [0:783]; 

    // 3. Instantiate the Unit Under Test (UUT)
    mac_unit uut (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .weight_in(weight_in),
        .valid_in(valid_in),
        .mac_out(mac_out),
        .valid_out(valid_out)
    );

    // 4. Generate a 100 MHz Clock (10ns period)
    always #5 clk = ~clk; 

    integer i;

    initial begin
        // 5. Initialize Inputs
        clk = 0;
        rst = 1;
        pixel_in = 0;
        weight_in = 0;
        valid_in = 0;

        // 6. Load the weights! 
        // IMPORTANT: In Vivado, you often need the absolute path to your txt file, 
        // or you must place w1_hex.txt in the Vivado simulation run directory (sim/sim_1/behav/xsim).
        // For now, replace the path below with your actual absolute path (use forward slashes '/').
        $readmemh("D:/Projects/FPGA_Neural_Net/python_model/weights/w1_hex.txt", weight_mem);

        // 7. Reset the system
        #100;
        rst = 0;
        #20;

        // 8. Feed data into the pipeline
        // We will feed 5 random pixels and multiply them by the first 5 weights from Python
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            valid_in = 1;
            pixel_in = $random % 128; // Generate a random 8-bit pixel
            weight_in = weight_mem[i]; // Fetch the actual weight from Python
        end

        // Stop feeding data
        @(posedge clk);
        valid_in = 0; 

        // Wait for the pipeline to flush (our MAC takes a few clock cycles)
        #50;

        // End simulation
        $finish;
    end
endmodule