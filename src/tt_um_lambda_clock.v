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

    wire tick_scan, tick_1hz, tick_4hz;
    wire [3:0] t0, t1, t2, t3;
    wire [3:0] dt0, dt1, dt2, dt3, dt4, dt5;

    // 1. Clock Divider
    clock_divider u_clk_div (
        .clk(clk),
        .rst(sys_rst),
        .tick_scan(tick_scan),
        .tick_1hz(tick_1hz),
        .tick_4hz(tick_4hz)
    );

    // 2. Buttons 
    wire btn_mode_press, btn_inc_press, btn_dec_press;
    
    button_debounce u_btn_mode (
        .clk(clk),
        .tick_scan(tick_scan),
        .btn_in(ui_in[0]),
        .btn_down(btn_mode_press)
    );

    button_debounce u_btn_inc (
        .clk(clk),
        .tick_scan(tick_scan),
        .btn_in(ui_in[1]),
        .btn_down(btn_inc_press)
    );
    
    button_debounce u_btn_dec (
        .clk(clk),
        .tick_scan(tick_scan),
        .btn_in(ui_in[2]),
        .btn_down(btn_dec_press)
    );

    // 3. 8-State FSM for Mode
    reg [2:0] disp_mode;
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) disp_mode <= 3'd0;
        else if (btn_mode_press) disp_mode <= disp_mode + 1;
    end
    
    // LEDs for UX Debugging / Setup Info (DISABLED TO SAVE SILICON AREA)
    assign uo_out[4] = 1'b0; // led_setup
    assign uo_out[5] = 1'b0; // led_alarm

    // 4. Time/Calendar/Alarm Core
    wire blink_1hz, alarm_match;
    assign uo_out[6] = 1'b0; // led_alarm_match
    
    time_calendar_core u_core (
        .clk(clk),
        .rst(sys_rst),
        .tick_1hz(tick_1hz),
        .inc_pulse(btn_inc_press),
        .dec_pulse(btn_dec_press),
        .mode(disp_mode),
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .dt0(dt0), .dt1(dt1), .dt2(dt2), .dt3(dt3), .dt4(dt4), .dt5(dt5),
        .blink_1hz(blink_1hz),
        .alarm_match(alarm_match)
    );

    // 5. Solid Alarm Buzzer (Active Buzzer needs solid HIGH to beep continuously)
    assign uo_out[3] = alarm_match; // buzzer

    // 6. Unified Display Driver (Scanner + SPI Output without Double Buffering)
    display_driver u_display (
        .clk(clk),
        .rst(sys_rst),
        .tick_scan(tick_scan),
        .blink_1hz(blink_1hz),
        .mode(disp_mode),
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .dt0(dt0), .dt1(dt1), .dt2(dt2), .dt3(dt3), .dt4(dt4), .dt5(dt5),
        .sclk(uo_out[0]),
        .rclk(uo_out[1]),
        .dio(uo_out[2])
    );

    // Tie unused output to 0
    assign uo_out[7] = 1'b0;

endmodule
