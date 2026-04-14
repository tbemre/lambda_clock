`default_nettype none

module tt_um_lambda_clock (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Bidirectional pins unused, tie to 0
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Active-high reset for internal system
    wire sys_rst = (~rst_n) | ui_in[3];

    // Instantiate core logic
    top_module u_core (
        .clk(clk),
        .btn_rst(sys_rst),             // Reset
        .btn_pause(ui_in[0]),          // Mode
        .btn_inc(ui_in[1]),            // Increment
        .btn_dec(ui_in[2]),            // Decrement
        
        .sclk(uo_out[0]),              // Shift CLK
        .rclk(uo_out[1]),              // Latch CLK
        .dio(uo_out[2]),               // Serial Data
        .buzzer(uo_out[3]),            // Buzzer
        .led_setup(uo_out[4]),         // Setup LED
        .led_alarm(uo_out[5]),         // Alarm LED
        .led_alarm_match(uo_out[6])    // Match LED
    );

    // Tie unused output to 0
    assign uo_out[7] = 1'b0;

endmodule
