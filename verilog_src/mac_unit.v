`timescale 1ns / 1ps

module mac_unit (
    input wire clk,
    input wire rst,
    input wire signed [7:0] pixel_in,    // 8-bit quantized pixel
    input wire signed [7:0] weight_in,   // 8-bit quantized weight
    input wire valid_in,                 // Pulse to calculate
    output reg signed [15:0] mac_out,    // 16-bit accumulated output
    output reg valid_out                 // High when done
);

    // Internal pipeline registers to map efficiently to Xilinx DSP48 slices
    reg signed [7:0] pixel_reg;
    reg signed [7:0] weight_reg;
    reg signed [15:0] mult_reg;

    always @(posedge clk) begin
        if (rst) begin
            pixel_reg  <= 0;
            weight_reg <= 0;
            mult_reg   <= 0;
            mac_out    <= 0;
            valid_out  <= 0;
        end else if (valid_in) begin
            // Stage 1: Register inputs
            pixel_reg  <= pixel_in;
            weight_reg <= weight_in;
            
            // Stage 2: Multiply
            mult_reg   <= pixel_reg * weight_reg;
            
            // Stage 3: Accumulate
            mac_out    <= mac_out + mult_reg;
            valid_out  <= 1'b1;
        end else begin
            valid_out  <= 1'b0;
        end
    end
endmodule