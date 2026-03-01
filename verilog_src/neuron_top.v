`timescale 1ns / 1ps

module neuron_top (
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [7:0] pixel_stream_in, // Stream of pixels coming from an image
    output wire signed [15:0] neuron_out,    // Final activated output
    output wire done                         // Goes high when 784 pixels are processed
);

    // Internal wires to connect the Brain, Muscle, and Memory
    wire [9:0] mem_addr;
    wire mac_valid;
    wire signed [15:0] mac_out;
    wire valid_out;

    // We will hardcode a bias of 15 for this demonstration
    wire signed [15:0] bias = 16'sd15; 

    // Weight Memory (ROM) embedded directly in the chip
    reg signed [7:0] weight_rom [0:783];
    
    initial begin
        // LOAD THE PYTORCH BRAIN INTO THE HARDWARE ROM
        // IMPORTANT: Make sure this path matches the exact path you used in the testbench earlier!
        $readmemh("D:/Projects/FPGA_Neural_Net/python_model/weights/w1_hex.txt", weight_rom);
    end

    wire signed [7:0] current_weight = weight_rom[mem_addr];

    // Instantiate the Muscle (MAC Unit)
    mac_unit datapath (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_stream_in),
        .weight_in(current_weight),
        .valid_in(mac_valid),
        .mac_out(mac_out),
        .valid_out(valid_out)
    );

    // Instantiate the Brain (FSM Controller)
    nn_controller brain (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mem_addr(mem_addr),
        .mac_valid(mac_valid),
        .mac_out(mac_out),
        .bias(bias),
        .neuron_out(neuron_out),
        .done(done)
    );

endmodule