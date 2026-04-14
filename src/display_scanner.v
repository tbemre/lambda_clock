`timescale 1ns / 1ps

module display_scanner(
    input clk,
    input rst,
    input tick_scan,        
    input blink_1hz,         
    input [2:0] mode,        
    input [3:0] t0, t1, t2, t3,
    input [3:0] dt0, dt1, dt2, dt3, dt4, dt5,         
    output reg [23:0] shift_data, 
    output reg update_req   
    );

    reg [3:0] scan_idx;     
    reg [7:0] next_segments;
    reg [7:0] next_u2_sel;
    reg [7:0] next_u3_sel;
    reg [3:0] current_hex;
    reg dp_on;

    always @(*) begin
        next_u2_sel = 8'hFF;
        next_u3_sel = 8'hFF;
        current_hex = 0;
        dp_on = 0;
        
        case(scan_idx)
            // Time digits (U2 Q3..0)
            4'd0: begin current_hex = t0; next_u2_sel[0] = 0; if (mode == 3'd1) dp_on = blink_1hz; else if (mode == 3'd6) dp_on = blink_1hz; end  
            4'd1: begin current_hex = t1; next_u2_sel[1] = 0; if (mode == 3'd1) dp_on = blink_1hz; else if (mode == 3'd6) dp_on = blink_1hz; end  
            4'd2: begin current_hex = t2; next_u2_sel[2] = 0; if (mode == 3'd2) dp_on = blink_1hz; else if (mode == 3'd7) dp_on = blink_1hz; else if (mode == 0) dp_on = 1'b1; end 
            4'd3: begin current_hex = t3; next_u2_sel[3] = 0; if (mode == 3'd2) dp_on = blink_1hz; else if (mode == 3'd7) dp_on = blink_1hz; end 
            
            // Date digits (U2 Q4..7, U3 Q0..1)
            4'd4: begin current_hex = dt0; next_u3_sel[0] = 0; if (mode == 3'd5) dp_on = blink_1hz; end // Y0
            4'd5: begin current_hex = dt1; next_u3_sel[1] = 0; if (mode == 3'd5) dp_on = blink_1hz; end // Y1
            4'd6: begin current_hex = dt2; next_u2_sel[4] = 0; if (mode == 3'd4) dp_on = blink_1hz; else if (mode == 0) dp_on = 1'b1; end // M0
            4'd7: begin current_hex = dt3; next_u2_sel[5] = 0; if (mode == 3'd4) dp_on = blink_1hz; end // M1
            4'd8: begin current_hex = dt4; next_u2_sel[6] = 0; if (mode == 3'd3) dp_on = blink_1hz; else if (mode == 0) dp_on = 1'b1; end // D0
            4'd9: begin current_hex = dt5; next_u2_sel[7] = 0; if (mode == 3'd3) dp_on = blink_1hz; end // D1 
        endcase
    end

    // ROM
    always @(*) begin
        case(current_hex)
            4'h0: next_segments = 8'b00111111; 4'h1: next_segments = 8'b00000110;
            4'h2: next_segments = 8'b01011011; 4'h3: next_segments = 8'b01001111;
            4'h4: next_segments = 8'b01100110; 4'h5: next_segments = 8'b01101101;
            4'h6: next_segments = 8'b01111101; 4'h7: next_segments = 8'b00000111;
            4'h8: next_segments = 8'b01111111; 4'h9: next_segments = 8'b01101111;
            default: next_segments = 8'b00000000;
        endcase
        if (dp_on) next_segments[7] = 1'b1;
    end

    // Scanner
    reg update_trigger;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_idx <= 0;
            update_req <= 0;
            shift_data <= 0;
            update_trigger <= 0;
        end else begin
            update_req <= 0; 

            if (tick_scan) begin
                if (scan_idx == 9) scan_idx <= 0;
                else scan_idx <= scan_idx + 1;
                
                update_trigger <= 1; 
            end else if (update_trigger) begin
                update_trigger <= 0;
                shift_data <= {next_u3_sel, next_u2_sel, next_segments};
                update_req <= 1; 
            end
        end
    end

endmodule
