`timescale 1ns / 1ps

module time_calendar_core(
    input clk,
    input rst,
    input tick_1hz,
    input inc_pulse,     
    input dec_pulse,     
    input [2:0] mode,    // 0:Norm, 1:T-Min, 2:T-Hr, 3:D-Day, 4:D-Mon, 5:D-Yr, 6:A-Min, 7:A-Hr
    
    output reg [3:0] t0, t1, t2, t3,             
    output reg [3:0] dt0, dt1, dt2, dt3, dt4, dt5, 
    
    output wire alarm_match,
    output wire blink_1hz
    );

    // Time Regs (BCD)
    reg [3:0] m0, m1, h0, h1;
    reg [3:0] sec0, sec1; 
    
    // Date Regs (BCD)
    reg [3:0] D0, D1, M0, M1; 
    reg [3:0] Y0, Y1;         
    
    // Alarm Regs (BCD)
    reg [3:0] am0, am1, ah0, ah1;
    
    reg dp_blink;
    assign blink_1hz = dp_blink;

    // Dynamic Days in Month Logic (Leap year logic for 2000-2099)
    reg [3:0] max_D1, max_D0;
    always @(*) begin
        if (M1 == 0 && M0 == 2) begin // February
            // Leap year rule in BCD: year is divisible by 4.
            // If Y1 is even, Y0 must be 0, 4, 8. If Y1 is odd, Y0 must be 2, 6.
            if ((Y1[0] == 0 && (Y0 == 0 || Y0 == 4 || Y0 == 8)) ||
                (Y1[0] == 1 && (Y0 == 2 || Y0 == 6))) begin
                max_D1 = 2; max_D0 = 9; // 29 days
            end else begin
                max_D1 = 2; max_D0 = 8; // 28 days
            end
        end else if ((M1 == 0 && (M0 == 4 || M0 == 6 || M0 == 9)) || 
                     (M1 == 1 && M0 == 1)) begin // Apr, Jun, Sep, Nov
            max_D1 = 3; max_D0 = 0; // 30 days
        end else begin
            max_D1 = 3; max_D0 = 1; // 31 days
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {h1, h0, m1, m0} <= {4'h1, 4'h4, 4'h1, 4'h0}; // 14:10
            {sec1, sec0} <= 0;
            {D1, D0, M1, M0} <= {4'h0, 4'h1, 4'h0, 4'h1}; // 01.01
            {Y1, Y0} <= {4'h0, 4'h2}; // 2002
            {ah1, ah0, am1, am0} <= {4'h0, 4'h0, 4'h0, 4'h0};
            dp_blink <= 0;
        end else begin
            if (tick_1hz) dp_blink <= ~dp_blink;

            // --- 1. Real Time Clock Update ---
            if (tick_1hz) begin
                if (sec0 == 9) begin
                    sec0 <= 0;
                    if (sec1 == 5) begin
                        sec1 <= 0;
                        if (m0 == 9) begin
                            m0 <= 0;
                            if (m1 == 5) begin
                                m1 <= 0;
                                if (h1 == 2 && h0 == 3) begin
                                    {h1, h0} <= {4'h0, 4'h0};
                                    if ((D1 > max_D1) || (D1 == max_D1 && D0 >= max_D0)) begin
                                        {D1, D0} <= {4'h0, 4'h1};
                                        if (M1 == 1 && M0 == 2) begin
                                            {M1, M0} <= {4'h0, 4'h1};
                                            if (Y0 == 9) begin
                                                Y0 <= 0;
                                                if (Y1 == 9) Y1 <= 0;
                                                else Y1 <= Y1 + 1;
                                            end else Y0 <= Y0 + 1;
                                        end else if (M0 == 9) begin
                                            M0 <= 0;
                                            M1 <= M1 + 1;
                                        end else M0 <= M0 + 1;
                                    end else if (D0 == 9) begin
                                        D0 <= 0;
                                        D1 <= D1 + 1;
                                    end else D0 <= D0 + 1;
                                end else if (h0 == 9) begin
                                    h0 <= 0;
                                    h1 <= h1 + 1;
                                end else h0 <= h0 + 1;
                            end else m1 <= m1 + 1;
                        end else m0 <= m0 + 1;
                    end else sec1 <= sec1 + 1;
                end else sec0 <= sec0 + 1;
            end
            
            // --- 2. Manual Adjustment ---
            if (inc_pulse || dec_pulse) begin
                case (mode)
                    3'd1: begin // Time Min
                        {sec1, sec0} <= 0; 
                        if (inc_pulse) begin
                            if (m0 == 9) begin m0 <= 0; if (m1 == 5) m1 <= 0; else m1 <= m1 + 1; end 
                            else m0 <= m0 + 1;
                        end else begin
                            if (m0 == 0) begin m0 <= 9; if (m1 == 0) m1 <= 5; else m1 <= m1 - 1; end 
                            else m0 <= m0 - 1;
                        end
                    end
                    3'd2: begin // Time Hr
                        if (inc_pulse) begin
                            if (h1 == 2 && h0 == 3) {h1, h0} <= {4'h0, 4'h0}; else if (h0 == 9) {h1, h0} <= {h1 + 4'd1, 4'h0}; else h0 <= h0 + 1;
                        end else begin
                            if (h1 == 0 && h0 == 0) {h1, h0} <= {4'h2, 4'h3}; else if (h0 == 0) {h1, h0} <= {h1 - 4'd1, 4'h9}; else h0 <= h0 - 1;
                        end
                    end
                    3'd3: begin // Date Day
                        if (inc_pulse) begin
                            if ((D1 > max_D1) || (D1 == max_D1 && D0 >= max_D0)) {D1, D0} <= {4'h0, 4'h1}; else if (D0 == 9) {D1, D0} <= {D1 + 4'd1, 4'h0}; else D0 <= D0 + 1;
                        end else begin
                            if (D1 == 0 && D0 <= 1) {D1, D0} <= {max_D1, max_D0}; else if (D0 == 0) {D1, D0} <= {D1 - 4'd1, 4'h9}; else D0 <= D0 - 1;
                        end
                    end
                    3'd4: begin // Date Month
                        if (inc_pulse) begin
                            if (M1 == 1 && M0 == 2) {M1, M0} <= {4'h0, 4'h1}; else if (M0 == 9) {M1, M0} <= {M1 + 4'd1, 4'h0}; else M0 <= M0 + 1;
                        end else begin
                            if (M1 == 0 && M0 <= 1) {M1, M0} <= {4'h1, 4'h2}; else if (M0 == 0) {M1, M0} <= {M1 - 4'd1, 4'h9}; else M0 <= M0 - 1;
                        end
                    end
                    3'd5: begin // Date Year
                        if (inc_pulse) begin
                            if (Y0 == 9) begin Y0 <= 0; if (Y1 == 9) Y1 <= 0; else Y1 <= Y1 + 1; end else Y0 <= Y0 + 1;
                        end else begin
                            if (Y0 == 0) begin Y0 <= 9; if (Y1 == 0) Y1 <= 9; else Y1 <= Y1 - 1; end else Y0 <= Y0 - 1;
                        end
                    end
                    3'd6: begin // Alarm Min
                        if (inc_pulse) begin
                            if (am0 == 9) begin am0 <= 0; if (am1 == 5) am1 <= 0; else am1 <= am1 + 1; end else am0 <= am0 + 1;
                        end else begin
                            if (am0 == 0) begin am0 <= 9; if (am1 == 0) am1 <= 5; else am1 <= am1 - 1; end else am0 <= am0 - 1;
                        end
                    end
                    3'd7: begin // Alarm Hr
                        if (inc_pulse) begin
                            if (ah1 == 2 && ah0 == 3) {ah1, ah0} <= {4'h0, 4'h0}; else if (ah0 == 9) {ah1, ah0} <= {ah1 + 4'd1, 4'h0}; else ah0 <= ah0 + 1;
                        end else begin
                            if (ah1 == 0 && ah0 == 0) {ah1, ah0} <= {4'h2, 4'h3}; else if (ah0 == 0) {ah1, ah0} <= {ah1 - 4'd1, 4'h9}; else ah0 <= ah0 - 1;
                        end
                    end
                endcase
            end
        end
    end

    // Concurrent Outputs for 10-Digits
    always @(*) begin
        // Time section: Show real time UNLESS in Alarm mode (modes 6,7)
        if (mode >= 3'd6) {t3, t2, t1, t0} = {ah1, ah0, am1, am0};
        else              {t3, t2, t1, t0} = {h1, h0, m1, m0};
        
        // Date section: Always show DD.MM.YY
        {dt5, dt4, dt3, dt2, dt1, dt0} = {D1, D0, M1, M0, Y1, Y0};
    end
    
    // Alarm Match logic
    // Now stays active for the ENTIRE minute instead of just the 0th second. 
    assign alarm_match = ({h1, h0, m1, m0} == {ah1, ah0, am1, am0}) ? 1'b1 : 1'b0;

endmodule
