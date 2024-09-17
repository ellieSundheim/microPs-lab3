/* Ellie Sundheim (esundheim@hmc.edu)
9/14/24
This code reads a 4x4 matrix scanner and outputs to 2 seven-segment LED displays*/

//top module, structural verilog
module top (
            input logic nreset,
            input logic [3:0] async_col,
            output logic [3:0] row,
            output logic [6:0] seg,
            output logic anode1_en, anode2_en);
		
			logic reset;
			assign reset = ~nreset;
            logic clk;
            logic [3:0] col;
            logic [4:0] out;
            logic [3:0] s1, s2;
			logic [3:0] sshow;

            oscillator myOsc (clk); //24 MHz
            synchronizer #(0) mySync (clk, reset, async_col, col); //div cuts by 2^15 
            scanner_FSM #(0) myFSM (clk, reset, col, out, row);
            debouncer  #(0) myDebounce(clk, reset, out, s1, s2);
			display_muxer #(16) myDisplayMuxer(clk, reset, s1, s2, anode1_en, anode2_en, sshow);
			seven_seg_disp mySevenSegDisp(sshow, seg);

endmodule

// synchronizer reduces chances of invalid logic level from async button presses
module synchronizer #(parameter SLOWDOWN_EXP = 0)
					(input logic clk,
                    input logic reset,
                    input logic [3:0] d,
                    output logic [3:0] q);

        logic [3:0] n1;
        logic [SLOWDOWN_EXP:0] counter;
        logic enable;

        always_ff @(posedge clk)
            if (reset) counter <= 0;
            else counter <= counter + 1;
        assign enable = counter[SLOWDOWN_EXP];

        always_ff @(posedge clk)
            if (reset) begin
                n1 <= 4'b0;
                q <= 4'b0;
            end
            else if (enable) begin
                n1 <= d;
                q <= n1;
            end
            // no else needed, will keep its value
endmodule

// finite state machine to control scanning
module scanner_FSM #(parameter SLOWDOWN_EXP = 0)
			(input logic clk,
            input logic reset,
            input logic [3:0] col,
            output logic [4:0] out,
            output logic [3:0] row);

        typedef enum logic [4:0] {scanR0, pressA, press0, pressB, pressF, 
                                scanR1, press7, press8, press9, pressE,
                                scanR2, press4, press5, press6, pressD,
                                scanR3, press1, press2, press3, pressC, error  } statetype;
        statetype state, nextstate;

        // clock divider
        logic [SLOWDOWN_EXP:0] counter;
        logic enable;

        always_ff @(posedge clk)
            if (reset) counter <= 0;
            else counter <= counter + 1;
        assign enable = counter[SLOWDOWN_EXP];

        // state register
        always_ff @(posedge clk)
            if (reset) state <= scanR0;
            else if (enable) state <= nextstate;

        // next state logic
        always_comb begin 
            case (state)
            //scanning states
                scanR0: //pulse R0, read R2
                    casez (col)
                        4'b???1: nextstate = press4;
                        4'b??1?: nextstate = press5;
                        4'b?1??: nextstate = press6;
                        4'b1???: nextstate = pressD;
                        default: nextstate = scanR1;
                    endcase
                scanR1: //pulse R1, read R3
                    casez (col)
                        4'b???1: nextstate = press1;
                        4'b??1?: nextstate = press2;
                        4'b?1??: nextstate = press3;
                        4'b1???: nextstate = pressC;
                        default: nextstate = scanR2;
                    endcase
                scanR2: //pulse R2, read R0
                    casez (col)
                        4'b???1: nextstate = pressA;
                        4'b??1?: nextstate = press0;
                        4'b?1??: nextstate = pressB;
                        4'b1???: nextstate = pressF;
                        default: nextstate = scanR3;
                    endcase
                scanR3: //pulse R3, read R1
                    casez (col)
                        4'b???1: nextstate = press7;
                        4'b??1?: nextstate = press8;
                        4'b?1??: nextstate = press9;
                        4'b1???: nextstate = pressE;
                        default: nextstate = scanR0;
                    endcase

                // pressed states
                //row 0
                pressA: if (col[0] == 0) nextstate = scanR0; else nextstate = pressA;
                press0: if (col[1] == 0) nextstate = scanR0; else nextstate = press0;
                pressB: if (col[2] == 0) nextstate = scanR0; else nextstate = pressB;
                pressF: if (col[3] == 0) nextstate = scanR0; else nextstate = pressF;

                //row 1
                press7: if (col[0] == 0) nextstate = scanR1; else nextstate = press7;
                press8: if (col[1] == 0) nextstate = scanR1; else nextstate = press8;
                press9: if (col[2] == 0) nextstate = scanR1; else nextstate = press9;
                pressE: if (col[3] == 0) nextstate = scanR1; else nextstate = pressE;

                //row 2
                press4: if (col[0] == 0) nextstate = scanR2; else nextstate = press4;
                press5: if (col[1] == 0) nextstate = scanR2; else nextstate = press5;
                press6: if (col[2] == 0) nextstate = scanR2; else nextstate = press6;
                pressD: if (col[3] == 0) nextstate = scanR2; else nextstate = pressD;

                //row 3
                press1: if (col[0] == 0) nextstate = scanR3; else nextstate = press1;
                press2: if (col[1] == 0) nextstate = scanR3; else nextstate = press2;
                press3: if (col[2] == 0) nextstate = scanR3; else nextstate = press3;
                pressC: if (col[3] == 0) nextstate = scanR3; else nextstate = pressC;
                default: nextstate = error;
            endcase
        end


        // output logic
        always_comb begin
            case (state)
            //scanning states
                scanR0: begin out = 5'b10000; row = 4'b0001; end
                scanR1: begin out = 5'b10000; row = 4'b0010; end
                scanR2: begin out = 5'b10000; row = 4'b0100; end
                scanR3: begin out = 5'b10000; row = 4'b1000; end
            // pressed states
            //row 0
                pressA: begin out = 5'b01010; row = 4'b0100; end
                press0: begin out = 5'b00000; row = 4'b0100; end
                pressB: begin out = 5'b01011; row = 4'b0100; end
                pressF: begin out = 5'b01111; row = 4'b0100; end
            //row 1
                press7: begin out = 5'b00111; row = 4'b1000; end
                press8: begin out = 5'b01000; row = 4'b1000; end
                press9: begin out = 5'b01001; row = 4'b1000; end
                pressE: begin out = 5'b01110; row = 4'b1000; end
            //row 2
                press4: begin out = 5'b00100; row = 4'b0001; end
                press5: begin out = 5'b00101; row = 4'b0001; end
                press6: begin out = 5'b00110; row = 4'b0001; end
                pressD: begin out = 5'b01101; row = 4'b0001; end
            //row 3
                press1: begin out = 5'b00001; row = 4'b0010; end
                press2: begin out = 5'b00010; row = 4'b0010; end
                press3: begin out = 5'b00011; row = 4'b0010; end
                pressC: begin out = 5'b01100; row = 4'b0010; end

                error: begin out = 5'bxxxxx; row = 4'bxxxx; end
		default: begin out = 5'bxxxxx; row = 4'bxxxx; end
            endcase
        end


endmodule

// debouncer handles if output changes rapidly
module debouncer #(parameter SLOWDOWN_EXP = 0)
				(input logic clk,
                input logic reset,
                input logic [4:0] out,
                output logic [3:0] s1,
                output logic [3:0] s2);



            //clock divider
            logic [SLOWDOWN_EXP:0] divcounter;
            logic enable;

            always_ff @(posedge clk)
                if (reset) divcounter <= 0;
                else divcounter <= divcounter + 1;
            assign enable = divcounter[SLOWDOWN_EXP];

            logic [23:0] threshold = 24'd10; //num of cycles we want to maintain before a press counts
            logic real_press;
            logic [4:0] lastOut;
            logic [23:0] counter;

            always_ff @(posedge clk)
                if (reset) begin
                            s1 <= 4'b0000;
                            s2 <= 4'b0000;
                            counter <= 0;
                            lastOut <= 5'b10000;
                            real_press <= 0;
                end
				// perform checks to see if the output is good enough to display
				else if (enable) begin
					// no button is being pressed
					if  (out == 5'b10000) begin
                        counter <= 0;
                        s1 <= s1;
                        s2 <= s2;
                        real_press <= 0;
                    end
                    // we know for sure that a button is being intentionally pressed (keeps us from repeatedly cycling input)
                    else if (real_press) begin
                        counter <= counter;
                        s1 <= s1;
                        s2 <= s2;
                        real_press <= 1;
                    end

                    // some button is being pressed, but for how long?
					else if (out == lastOut) begin
                        if (counter < threshold) begin //not there yet, increment
                            counter <= counter + 1;
                            s1 <= s1;
                            s2 <= s2;
                            real_press <= 0;
                        end
                        else begin //counter is at threshold (we should only hit this once because after it get caught above by real press block)
                            counter <= counter;
                            s1 <= s2;
                            s2 <= out[3:0];
                            real_press <= 1;
                        end
                    end

                    //else, just in case we need to catch something where the output changes from one valid num to another
                    else begin 
                        counter <= 0;
                        s1 <= s1;
                        s2 <= s2;
                        real_press <= 0;
                    end

                    //always update the last value of out that we saw
					lastOut <= out;
                end
endmodule

// apparently humans can see flicker below 90Hz
// switching time of electronics is limited by ??
// to cut from 24 Mhz to 90 Hz, divide by 2^18 (roughly)
module display_muxer #(parameter NUM_CYCLES_ON_EXP = 18) //NUM_CYCLES_ON_EXP sets the number of clk cycles (2^N) that each side of the display is on for
                    (input logic clk,
					 input logic reset,
                     input logic [3:0] s1,s2,
                     output logic anode1_en, anode2_en,
                     output logic [3:0] sshow);

    logic [NUM_CYCLES_ON_EXP-1:0] counter;

    always_ff @(posedge clk, posedge reset)
		if (reset) counter <= 0;
        	else counter <= counter + 1;

    assign anode1_en = counter[NUM_CYCLES_ON_EXP-1];
	assign anode2_en = ~anode1_en;
    mux displayMux(anode1_en, s1, s2, sshow);

endmodule

//arbitrary width mux, defaults to 4
module mux #(parameter WIDTH = 4)
            (input logic select,
            input logic [WIDTH-1:0] s0, s1,
            output logic [WIDTH-1:0] out);

            always_comb
            case (select)
                1'b0: out = s0;
                1'b1: out = s1;
                default: out = 1'bx;
            endcase
endmodule

// internal oscillator
module oscillator (output logic clk);

	logic int_osc;
  
	// Internal high-speed oscillator (div 2'b01 makes it oscillate at 24Mhz)
	HSOSC #(.CLKHF_DIV(2'b01)) 
         hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

	assign clk = int_osc;
    
endmodule

// combinational logic for seven segment display
module seven_seg_disp(input logic[3:0] s,
					  output logic[6:0] seg);
	always_comb
	begin
		case(s[3:0])
			// select which segments need to light up based on which hex munber is input (seg = 7'b 6543210)
			4'b0000: seg = 7'b0111111;
			4'b0001: seg = 7'b0000110;
			4'b0010: seg = 7'b1011011;
			4'b0011: seg = 7'b1001111;
			4'b0100: seg = 7'b1100110;
			4'b0101: seg = 7'b1101101;
			4'b0110: seg = 7'b1111101;
			4'b0111: seg = 7'b0000111;
			
			4'b1000: seg = 7'b1111111;
			4'b1001: seg = 7'b1100111;
			4'b1010: seg = 7'b1110111;
			4'b1011: seg = 7'b1111100;
			4'b1100: seg = 7'b1011000;
			4'b1101: seg = 7'b1011110;
			4'b1110: seg = 7'b1111001;
			4'b1111: seg = 7'b1110001;
			default: seg = 7'b0000001;
		endcase
		//flip the bits because segment leds are actually active low
		seg = ~seg;
	end 

endmodule

