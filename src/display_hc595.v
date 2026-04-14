// display_hc595.v  — display_scanner + hc595_driver birlesimi
// Tasarruf: 24-bit ara buffer, update_req/busy sinyalleri kaldirildi
// Tek FSM: IDLE -> SHIFT(24bit) -> LATCH
//
// Parametreler:
//   CLK_HZ  : giris frekans (varsayilan 10 MHz)
//   SPI_DIV : SPI half-period (saat deviri). SPI frekans = CLK_HZ/(2*SPI_DIV)
//             10MHz, SPI_DIV=5 -> 1MHz SPI
`default_nettype none

module display_hc595 #(
    parameter CLK_HZ = 10_000_000,
    parameter SPI_DIV = 5
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_scan,
    input  wire       blink_1hz,
    input  wire [2:0] mode,
    input  wire [3:0] t0, t1, t2, t3,
    input  wire [3:0] dt0, dt1, dt2, dt3, dt4, dt5,
    output reg        sclk,
    output reg        rclk,
    output reg        dio
);

    localparam SPI_W = $clog2(SPI_DIV + 1);

    // --- Segment ROM ---
    function [6:0] seg7(input [3:0] h);
        case (h)
            4'h0: seg7 = 7'b0111111; 4'h1: seg7 = 7'b0000110;
            4'h2: seg7 = 7'b1011011; 4'h3: seg7 = 7'b1001111;
            4'h4: seg7 = 7'b1100110; 4'h5: seg7 = 7'b1101101;
            4'h6: seg7 = 7'b1111101; 4'h7: seg7 = 7'b0000111;
            4'h8: seg7 = 7'b1111111; 4'h9: seg7 = 7'b1101111;
            default: seg7 = 7'b0000000;
        endcase
    endfunction

    // --- Tarama indeksi ---
    reg [3:0] scan_idx;

    // --- Kombinasyonel frame uretimi ---
    reg [3:0] r_hex;
    reg       r_dp;
    reg [7:0] r_u2_sel;
    reg [7:0] r_u3_sel;

    always @(*) begin
        r_u2_sel = 8'hFF; r_u3_sel = 8'hFF;
        r_hex = 4'h0;     r_dp = 1'b0;
        case (scan_idx)
            4'd0: begin r_hex=t0;  r_u2_sel[0]=1'b0; r_dp=(mode==3'd1||mode==3'd6)?blink_1hz:1'b0; end
            4'd1: begin r_hex=t1;  r_u2_sel[1]=1'b0; r_dp=(mode==3'd1||mode==3'd6)?blink_1hz:1'b0; end
            4'd2: begin r_hex=t2;  r_u2_sel[2]=1'b0; r_dp=(mode==3'd2||mode==3'd7)?blink_1hz:(mode==3'd0)?1'b1:1'b0; end
            4'd3: begin r_hex=t3;  r_u2_sel[3]=1'b0; r_dp=(mode==3'd2||mode==3'd7)?blink_1hz:1'b0; end
            4'd4: begin r_hex=dt0; r_u3_sel[0]=1'b0; r_dp=(mode==3'd5)?blink_1hz:1'b0; end
            4'd5: begin r_hex=dt1; r_u3_sel[1]=1'b0; r_dp=(mode==3'd5)?blink_1hz:1'b0; end
            4'd6: begin r_hex=dt2; r_u2_sel[4]=1'b0; r_dp=(mode==3'd4)?blink_1hz:(mode==3'd0)?1'b1:1'b0; end
            4'd7: begin r_hex=dt3; r_u2_sel[5]=1'b0; r_dp=(mode==3'd4)?blink_1hz:1'b0; end
            4'd8: begin r_hex=dt4; r_u2_sel[6]=1'b0; r_dp=(mode==3'd3)?blink_1hz:(mode==3'd0)?1'b1:1'b0; end
            4'd9: begin r_hex=dt5; r_u2_sel[7]=1'b0; r_dp=(mode==3'd3)?blink_1hz:1'b0; end
            default: begin end
        endcase
    end

    wire [7:0]  seg_byte = {r_dp, seg7(r_hex)};
    wire [23:0] frame    = {r_u3_sel, r_u2_sel, seg_byte};

    // --- FSM ---
    localparam ST_IDLE=2'd0, ST_SHIFT=2'd1, ST_LATCH=2'd2;
    reg [1:0]       state;
    reg [4:0]       bit_cnt;
    reg [23:0]      shift_reg;
    reg [SPI_W-1:0] clk_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_idx  <= 4'd0; state     <= ST_IDLE;
            bit_cnt   <= 5'd0; shift_reg <= 24'd0;
            clk_cnt   <= 0;    sclk <= 1'b0; rclk <= 1'b0; dio <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    sclk <= 1'b0; rclk <= 1'b0;
                    if (tick_scan) begin
                        scan_idx  <= (scan_idx==4'd9) ? 4'd0 : scan_idx+1'b1;
                        shift_reg <= frame;
                        bit_cnt   <= 5'd0;
                        clk_cnt   <= 0;
                        state     <= ST_SHIFT;
                    end
                end
                ST_SHIFT: begin
                    if (clk_cnt == SPI_DIV-1) begin
                        clk_cnt <= 0;
                        if (!sclk) begin
                            dio  <= shift_reg[23];
                            sclk <= 1'b1;
                        end else begin
                            sclk      <= 1'b0;
                            shift_reg <= {shift_reg[22:0], 1'b0};
                            if (bit_cnt == 5'd23) state <= ST_LATCH;
                            else                  bit_cnt <= bit_cnt + 1'b1;
                        end
                    end else clk_cnt <= clk_cnt + 1'b1;
                end
                ST_LATCH: begin
                    if (clk_cnt == SPI_DIV-1) begin
                        clk_cnt <= 0;
                        if (!rclk) rclk <= 1'b1;
                        else begin rclk <= 1'b0; state <= ST_IDLE; end
                    end else clk_cnt <= clk_cnt + 1'b1;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
