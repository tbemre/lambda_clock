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

    reg [1:0] state; // 0=IDLE, 1=SHIFT, 2=LATCH
    reg [4:0] bit_cnt;          
    reg [23:0] shift_reg;
    reg [5:0] clk_div; // 1MHz SPI clock for breadboard stability 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            sclk <= 0;
            rclk <= 0;
            dio <= 0;
            busy <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            clk_div <= 0;
        end else begin
            if (state != 0) begin
                if (clk_div == 49) clk_div <= 0;
                else clk_div <= clk_div + 1;
            end else clk_div <= 0;

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

                1: begin // SHIFT
                    if (clk_div == 24) begin
                        sclk <= 0;
                        dio <= shift_reg[23]; // MSB first 
                    end else if (clk_div == 49) begin
                        sclk <= 1;
                        shift_reg <= {shift_reg[22:0], 1'b0};
                        if (bit_cnt == 23) state <= 2;
                        else bit_cnt <= bit_cnt + 1;
                    end
                end

                2: begin // LATCH
                    if (clk_div == 24) rclk <= 1;
                    else if (clk_div == 49) begin
                        rclk <= 0;
                        state <= 0;
                        busy <= 0;
                    end
                end
            endcase
        end
    end
endmodule
