<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The Lambda Clock is a highly-optimized full digital calendar and clock built for a 10-digit 7-segment multiplexed display architecture using three cascaded 74HC595 shift registers. It features a fully synchronous clock-enable domain (tick-based) that guarantees ASIC synthesis stability. It parses the base 1Hz and 1kHz ticks to manipulate independent BCD limits natively preventing binary-to-BCD resource explosion. It enforces leap-year restrictions automatically and incorporates an 8-state settings menu, tracking and individually updating Days, Months, Years, and Time. A built-in Alarm module is continuously checked against current active BCD time registers.

## How to test

The clock provides an 8-stage interactive module.
- **BTN_MODE (ui[0])**: Cycles between Normal Time, Minutes Edit, Hours Edit, Days Edit, Months Edit, Years Edit, Alarm Min Edit, Alarm Hour Edit. 
- **BTN_INC (ui[1])**: Increments the currently selected active time/date block.
- **BTN_DEC (ui[2])**: Decrements the currently selected active block.
- **BTN_RST (ui[3])**: Manually resets the clock back to the default time (14:10 01.01.2002).

## External hardware

- Three (3) 74HC595 Shift Registers (Cascaded).
- Two (2) 5641AS 4-Digit 7-Segment Displays.
- One (1) 5621AS 2-Digit 7-Segment Display.
- Active Buzzer (for output uo[3]).
- Optional LEDs (for uo[4], uo[5], uo[6]) for Debug/Status indicators.
