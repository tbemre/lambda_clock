`timescale 1ns / 1ps

module top_module(
    input clk,
    input btn_rst,
    input btn_pause, 
    input btn_dec,   
    input btn_inc,
    output sclk,
    output rclk,
    output dio,
    output buzzer,
    output led_setup,
    output led_alarm,
    output led_alarm_match
    );

    wire rst = btn_rst;

    wire tick_scan, tick_1hz, tick_4hz;
    wire [3:0] t0, t1, t2, t3;
    wire [3:0] dt0, dt1, dt2, dt3, dt4, dt5;
    wire [23:0] shift_data;
    wire update_req, driver_busy;
    
    // 1. Clock Divider
    clock_divider u_clk_div (
        .clk(clk),
        .rst(rst),
        .tick_scan(tick_scan),
        .tick_1hz(tick_1hz),
        .tick_4hz(tick_4hz)
    );

    // 2. Buttons 
    wire btn_mode_press, btn_inc_press, btn_dec_press;
    
    button_debounce u_btn_mode (
        .clk(clk),
        .tick_scan(tick_scan),
        .btn_in(btn_pause),
        .btn_down(btn_mode_press)
    );

    button_debounce u_btn_inc (
        .clk(clk),
        .tick_scan(tick_scan),
        .btn_in(btn_inc),
        .btn_down(btn_inc_press)
    );
    
    button_debounce u_btn_dec (
        .clk(clk),
        .tick_scan(tick_scan),
        .btn_in(btn_dec),
        .btn_down(btn_dec_press)
    );

    // 3. 8-State FSM for Mode
    reg [2:0] disp_mode;
    always @(posedge clk or posedge rst) begin
        if (rst) disp_mode <= 3'd0;
        else if (btn_mode_press) disp_mode <= disp_mode + 1;
    end
    
    // LEDs for UX Debugging / Setup Info (DISABLED TO SAVE SILICON AREA)
    assign led_setup = 1'b0;
    assign led_alarm = 1'b0;

    // 4. Time/Calendar/Alarm Core
    wire blink_1hz, alarm_match;
    assign led_alarm_match = 1'b0; // Drive LD3 when alarm matches (DISABLED)
    time_calendar_core u_core (
        .clk(clk),
        .rst(rst),
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
    assign buzzer = alarm_match;

    // 6. Scanner & Data Formatter (24-bit Output)
    display_scanner u_scanner (
        .clk(clk),
        .rst(rst),
        .tick_scan(tick_scan),
        .blink_1hz(blink_1hz),
        .mode(disp_mode),
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .dt0(dt0), .dt1(dt1), .dt2(dt2), .dt3(dt3), .dt4(dt4), .dt5(dt5),
        .shift_data(shift_data),
        .update_req(update_req)
    );

    // 7. 74HC595 Driver (24-bit)
    hc595_driver u_driver (
        .clk(clk),
        .rst(rst),
        .data_in(shift_data),
        .start_send(update_req), 
        .sclk(sclk),
        .rclk(rclk),
        .dio(dio),
        .busy(driver_busy)
    );

endmodule
