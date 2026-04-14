`timescale 1ns / 1ps

module button_debounce(
    input clk,          // 50 MHz
    input tick_scan,    // 1 kHz sampling tick
    input btn_in,
    output wire btn_down // One-cycle pulse on press
    );

    // 4-bit shift register for Debounce
    reg [3:0] shift_reg;
    
    // Synchronize async button input to avoid metastability
    reg sync_0, sync_1;
    always @(posedge clk) begin
        sync_0 <= btn_in;
        sync_1 <= sync_0;
    end

    // Shift on target frequency (1 kHz -> 1ms per shift)
    always @(posedge clk) begin
        if (tick_scan) begin
            shift_reg <= {shift_reg[2:0], sync_1};
        end
    end

    // Edge Detection: 
    // Button pressed when sequence is 0 -> 1 -> 1 -> 1
    // Meaning the last 3 ms it was high, but 4 ms ago it was low.
    assign btn_down = (shift_reg == 4'b0111) & tick_scan;

endmodule
