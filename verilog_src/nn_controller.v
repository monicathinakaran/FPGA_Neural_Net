`timescale 1ns / 1ps

module nn_controller (
    input wire clk,
    input wire rst,
    input wire start,
    
    // Interface to Memory
    output reg [9:0] mem_addr,       // Address to fetch pixel/weight (0 to 783)
    
    // Interface to MAC Unit
    output reg mac_valid,            // Tells MAC to start multiplying
    input wire signed [15:0] mac_out,// The accumulated result from MAC
    
    // Hardware ReLU & Bias Interface
    input wire signed [15:0] bias,   // The bias value from Python
    output reg signed [15:0] neuron_out, // Final output of the neuron
    output reg done                  // Tells the system this neuron is finished
);

    // FSM State Encoding
    localparam S_IDLE       = 3'd0;
    localparam S_CALC       = 3'd1;
    localparam S_WAIT_PIPE  = 3'd2;
    localparam S_BIAS_RELU  = 3'd3;
    localparam S_DONE       = 3'd4;

    reg [2:0] state, next_state;
    reg [9:0] counter; // Counts from 0 to 783
    reg [1:0] pipe_wait; // Counts 3 cycles for MAC pipeline to flush

    // 1. State Register (Sequential Logic)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 2. Next State Logic (Combinational Logic)
    always @(*) begin
        next_state = state; // Default stay in current state
        case (state)
            S_IDLE: begin
                if (start) next_state = S_CALC;
            end
            S_CALC: begin
                if (counter == 783) next_state = S_WAIT_PIPE;
            end
            S_WAIT_PIPE: begin
                if (pipe_wait == 3) next_state = S_BIAS_RELU;
            end
            S_BIAS_RELU: begin
                next_state = S_DONE;
            end
            S_DONE: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // 3. Output & Datapath Control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_addr <= 0;
            counter <= 0;
            mac_valid <= 0;
            pipe_wait <= 0;
            done <= 0;
            neuron_out <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    mem_addr <= 0;
                    counter <= 0;
                    done <= 0;
                    mac_valid <= 0;
                end
                
                S_CALC: begin
                    mac_valid <= 1'b1;
                    mem_addr <= counter;
                    counter <= counter + 1;
                end
                
                S_WAIT_PIPE: begin
                    mac_valid <= 1'b0; // Stop MAC from accepting new data
                    pipe_wait <= pipe_wait + 1;
                end
                
                S_BIAS_RELU: begin
                    // ADD BIAS AND APPLY RELU IN ONE CLOCK CYCLE!
                    // If the MSB (bit 15) of the sum is 1, it's negative. So output 0.
                    if ((mac_out + bias) < 0) begin
                        neuron_out <= 0; // ReLU zeroes out negative numbers
                    end else begin
                        neuron_out <= mac_out + bias;
                    end
                end
                
                S_DONE: begin
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule