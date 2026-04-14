`timescale 1ns / 1ps

module clock_divider(
    input clk,            // 32768 Hz RTC Crystal
    input rst,
    output wire tick_scan, // ~1 kHz tick
    output wire tick_1hz,  // 1 Hz tick
    output wire tick_4hz   // 4 Hz tick for fast alarm blinking/setup
    );

    // Single 15-bit counter for 32768 Hz
    reg [14:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end
    
    // Derived ticks based entirely on bit-level rollovers! No adders/comparators!
    
    // cnt[4:0] rolls over every 32 ticks (32768 / 32 = ~1 kHz)
    assign tick_scan = (cnt[4:0] == 5'h1F);
    
    // cnt[12:0] rolls over every 8192 ticks (32768 / 8192 = 4 Hz)
    assign tick_4hz = (cnt[12:0] == 13'h1FFF);
    
    // cnt rolls over every 32768 ticks (32768 / 32768 = 1 Hz)
    assign tick_1hz = (cnt == 15'h7FFF);

endmodule
