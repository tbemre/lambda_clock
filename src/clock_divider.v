`timescale 1ns / 1ps

module clock_divider(
    input clk,            // 50 MHz
    input rst,
    output reg tick_scan, // 1 kHz tick
    output reg tick_1hz,  // 1 Hz tick
    output reg tick_4hz   // 4 Hz tick for fast alarm blinking/setup
    );

    // 1 kHz tick from 50 MHz (50,000 counts)
    reg [15:0] cnt_scan;
    
    // 1 Hz and 4 Hz ticks derived from 1 kHz tick 
    // Need 1000 counts for 1 Hz (10 bits: 0-999)
    reg [9:0] cnt_1hz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_scan <= 0;
            tick_scan <= 0;
            cnt_1hz <= 0;
            tick_1hz <= 0;
            tick_4hz <= 0;
        end else begin
            // 1. Generate 1 kHz Scan Tick
            if (cnt_scan == 49999) begin
                cnt_scan <= 0;
                tick_scan <= 1;
            end else begin
                cnt_scan <= cnt_scan + 1;
                tick_scan <= 0;
            end
            
            // 2. Derive slower ticks from tick_scan
            tick_1hz <= 0;
            tick_4hz <= 0; // Default off
            
            if (tick_scan) begin
                if (cnt_1hz == 999) begin
                    cnt_1hz <= 0;
                    tick_1hz <= 1;
                    tick_4hz <= 1;
                end else begin
                    cnt_1hz <= cnt_1hz + 1;
                    // Tick 4Hz at 249, 499, 749, 999
                    if (cnt_1hz == 249 || cnt_1hz == 499 || cnt_1hz == 749) begin
                        tick_4hz <= 1;
                    end
                end
            end
        end
    end
endmodule
