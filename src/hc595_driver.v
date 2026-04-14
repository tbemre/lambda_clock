`timescale 1ns / 1ps

module hc595_driver(
    input wire clk,             
    input wire rst,
    input wire [23:0] data_in,  
    input wire start_send,
    output reg sclk,            
    output reg rclk,            
    output reg dio,             
    output reg busy
    );

    reg [2:0] state; // 0=IDLE, 1=SHIFT_LOW, 2=SHIFT_HIGH, 3=LATCH_HIGH, 4=LATCH_LOW
    reg [4:0] bit_cnt;          
    reg [23:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            sclk <= 0;
            rclk <= 0;
            dio <= 0;
            busy <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
        end else begin

            case (state)
                0: begin // IDLE
                    rclk <= 0;
                    sclk <= 0;
                    busy <= 0;
                    if (start_send) begin
                        shift_reg <= data_in;
                        state <= 1;
                        busy <= 1;
                        bit_cnt <= 0;
                    end
                end

                1: begin // SHIFT_LOW (Setup data, sclk low)
                    sclk <= 0;
                    dio <= shift_reg[23]; // MSB first 
                    state <= 2;
                end

                2: begin // SHIFT_HIGH (Latch data into HC595, sclk high)
                    sclk <= 1;
                    shift_reg <= {shift_reg[22:0], 1'b0};
                    if (bit_cnt == 23) state <= 3;
                    else begin
                        bit_cnt <= bit_cnt + 1;
                        state <= 1;
                    end
                end

                3: begin // LATCH_HIGH (Transfer to outputs)
                    rclk <= 1;
                    state <= 4;
                end
                
                4: begin // LATCH_LOW (Finish transfer)
                    rclk <= 0;
                    state <= 0;
                    busy <= 0;
                end
                
                default: state <= 0;
            endcase
        end
    end
endmodule
