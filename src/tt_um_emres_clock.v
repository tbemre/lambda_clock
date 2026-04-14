// tt_um_emres_clock.v — TinyTapeout wrapper (optimize edilmis)
// Degisiklikler:
//   - display_scanner + hc595_driver -> display_hc595 (tek modul)
//   - clock_divider parametrik (CLK_HZ ile)
//   - busy/update_req/shift_data ara sinyalleri kaldirildi
`default_nettype none

module tt_um_emres_clock (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire sys_rst = (~rst_n) | ui_in[3];

    // --- Saat sinyalleri ---
    wire tick_scan, tick_1hz, tick_4hz;

    clock_divider #(.CLK_HZ(10_000_000)) u_clk_div (
        .clk      (clk),
        .rst      (sys_rst),
        .tick_scan(tick_scan),
        .tick_1hz (tick_1hz),
        .tick_4hz (tick_4hz)
    );

    // --- Buton debounce ---
    wire btn_mode_press, btn_inc_press, btn_dec_press;

    button_debounce u_btn_mode (
        .clk      (clk),
        .tick_scan(tick_scan),
        .btn_in   (ui_in[0]),
        .btn_down (btn_mode_press)
    );
    button_debounce u_btn_inc (
        .clk      (clk),
        .tick_scan(tick_scan),
        .btn_in   (ui_in[1]),
        .btn_down (btn_inc_press)
    );
    button_debounce u_btn_dec (
        .clk      (clk),
        .tick_scan(tick_scan),
        .btn_in   (ui_in[2]),
        .btn_down (btn_dec_press)
    );

    // --- Mod FSM ---
    reg [2:0] disp_mode;
    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) disp_mode <= 3'd0;
        else if (btn_mode_press) disp_mode <= disp_mode + 1'b1;
    end

    // --- Zaman / Takvim / Alarm cekirdegi ---
    wire [3:0] t0, t1, t2, t3;
    wire [3:0] dt0, dt1, dt2, dt3, dt4, dt5;
    wire blink_1hz, alarm_match;

    time_calendar_core u_core (
        .clk      (clk),
        .rst      (sys_rst),
        .tick_1hz (tick_1hz),
        .inc_pulse(btn_inc_press),
        .dec_pulse(btn_dec_press),
        .mode     (disp_mode),
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .dt0(dt0),.dt1(dt1),.dt2(dt2),.dt3(dt3),.dt4(dt4),.dt5(dt5),
        .blink_1hz  (blink_1hz),
        .alarm_match(alarm_match)
    );

    // --- Birlesik display + HC595 surucu ---
    display_hc595 #(
        .CLK_HZ (10_000_000),
        .SPI_DIV(5)              // 10MHz / (2*5) = 1 MHz SPI
    ) u_disp (
        .clk      (clk),
        .rst      (sys_rst),
        .tick_scan(tick_scan),
        .blink_1hz(blink_1hz),
        .mode     (disp_mode),
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .dt0(dt0),.dt1(dt1),.dt2(dt2),.dt3(dt3),.dt4(dt4),.dt5(dt5),
        .sclk(uo_out[0]),
        .rclk(uo_out[1]),
        .dio (uo_out[2])
    );

    // --- Diger cikislar ---
    assign uo_out[3] = alarm_match;                              // buzzer
    assign uo_out[4] = (disp_mode >= 3'd1 && disp_mode <= 3'd5); // led_setup
    assign uo_out[5] = (disp_mode >= 3'd6);                      // led_alarm
    assign uo_out[6] = alarm_match;                              // led_alarm_match
    assign uo_out[7] = 1'b0;

endmodule
