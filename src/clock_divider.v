// clock_divider.v  — parametrik, alan optimizasyonlu
// CLK_HZ parametresi ile farklı giriş frekanslarını destekler.
// Varsayılan: 10 MHz  → en küçük sayaçlar
// 50 MHz için: #(.CLK_HZ(50_000_000)) şeklinde kullan
`default_nettype none

module clock_divider #(
    parameter CLK_HZ = 10_000_000
)(
    input  wire clk,
    input  wire rst,
    output reg  tick_scan,   // 1 kHz
    output reg  tick_1hz,    // 1 Hz
    output reg  tick_4hz     // 4 Hz
);

    localparam SCAN_DIV = CLK_HZ / 1000;
    localparam SCAN_W   = $clog2(SCAN_DIV);  // 10MHz→14-bit, 50MHz→16-bit

    reg [SCAN_W-1:0] cnt_scan;
    reg [9:0]        cnt_hz;   // 0-999 → 10-bit, değişmez

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_scan  <= 0;
            cnt_hz    <= 0;
            tick_scan <= 1'b0;
            tick_1hz  <= 1'b0;
            tick_4hz  <= 1'b0;
        end else begin
            tick_scan <= 1'b0;
            tick_1hz  <= 1'b0;
            tick_4hz  <= 1'b0;

            if (cnt_scan == SCAN_DIV - 1) begin
                cnt_scan  <= 0;
                tick_scan <= 1'b1;

                if (cnt_hz == 999) begin
                    cnt_hz   <= 0;
                    tick_1hz <= 1'b1;
                    tick_4hz <= 1'b1;
                end else begin
                    cnt_hz <= cnt_hz + 1'b1;
                    if (cnt_hz == 249 || cnt_hz == 499 || cnt_hz == 749)
                        tick_4hz <= 1'b1;
                end
            end else begin
                cnt_scan <= cnt_scan + 1'b1;
            end
        end
    end

endmodule
