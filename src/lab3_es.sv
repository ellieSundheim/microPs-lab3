/* Ellie Sundheim (esundheim@hmc.edu)
9/14/24
This code reads a 4x4 matirx scanner and outputs to 2 seven-segment LED displays*/

//top module, structural verilog
module top (input logic [3:0] async_col,
            output logic [3:0] row,
            output logic [6:0] seg,
            output logic anode1_en, anode2_en);

            oscillator myOsc (clk);
            synchronizer mySync (clk, async_col, col);

endmodule

// synchronizer reduces chances of invalid logic level from async button presses
module synchronizer(input logic clk,
                    input logic [3:0] d,
                    output logic [3:0] q);

        logic n1;
        always_ff @(posedge clk)
            begin
                n1 <= d;
                q <= n1;
            end
endmodule

// finite state machine to control scanning
module FSM (input logic clk,
            input logic reset,
            input logic [3:0] col,
            output logic [4:0] out,
            output logic [3:0] row);

        typedef enum logic [4:0] {scanR0, pressA, press0, pressB, pressF, 
                                scanR1, press7, press8, press9, pressE,
                                scanR2, press4, press5, press6, pressD,
                                scanR3, press1, press2, press3, pressC  } statetype;
        statetype state, nextstate;

        // state register
        always_ff @(posedge clk, posedge reset)
            if (reset) state <= scanR0;
            else state <= nextstate;

        // next state logic
        always_comb begin 
            case (state)
            //scanning states
                scanR0: 
                    case (col)
                        4'b0001: nextstate = pressA;
                        4'b0010: nextstate = press0;
                        4'b0100: nextstate = pressB;
                        4'b1000: nextstate = pressF;
                        default: nextstate = scanR1;
                    endcase
                scanR1:
                    case (col)
                        4'b0001: nextstate = press7;
                        4'b0010: nextstate = press8;
                        4'b0100: nextstate = press9;
                        4'b1000: nextstate = pressE;
                        default: nextstate = scanR2;
                    endcase
                scanR2:
                    case (col)
                        4'b0001: nextstate = press4;
                        4'b0010: nextstate = press5;
                        4'b0100: nextstate = press6;
                        4'b1000: nextstate = pressD;
                        default: nextstate = scanR3;
                    endcase
                scanR3: 
                    case (col)
                        4'b0001: nextstate = press1;
                        4'b0010: nextstate = press2;
                        4'b0100: nextstate = press3;
                        4'b1000: nextstate = pressC;
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
                pressE: if (col[3] == 0) nextstate = scanR1; else nextstate = press0;

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

            endcase
        end


        // output logic
        always_comb begin
            case (state)
            //scanning states
                scanR0: begin out = 5'b10000; row = 4'b0001; end
                scanR0: begin out = 5'b10000; row = 4'b0010; end
                scanR0: begin out = 5'b10000; row = 4'b0100; end
                scanR0: begin out = 5'b10000; row = 4'b1000; end
            // pressed states
            //row 0
                pressA: begin out = 5'b01010; row = 4'b0001; end
                press0: begin out = 5'b00000; row = 4'b0001; end
                pressB: begin out = 5'b01011; row = 4'b0001; end
                pressF: begin out = 5'b01111; row = 4'b0001; end
            //row 1
                press7: begin out = 5'b00111; row = 4'b0010; end
                press8: begin out = 5'b01000; row = 4'b0010; end
                press9: begin out = 5'b01001; row = 4'b0010; end
                pressE: begin out = 5'b01110; row = 4'b0010; end
            //row 2
                press4: begin out = 5'b00100; row = 4'b0100; end
                press5: begin out = 5'b00101; row = 4'b0100; end
                press6: begin out = 5'b00110; row = 4'b0100; end
                pressD: begin out = 5'b01101; row = 4'b0100; end
            //row 3
                press1: begin out = 5'b00001; row = 4'b1000; end
                press2: begin out = 5'b00010; row = 4'b1000; end
                press3: begin out = 5'b00011; row = 4'b1000; end
                pressC: begin out = 5'b01100; row = 4'b1000; end
        
            endcase
        end


endmodule

// debouncer handles if output changes rapidly
module debouncer (input logic clk,
                input logic reset,
                input logic [4:0] out,
                output logic [3:0] s1,
                output logic [3:0] s2);

            logic threshold = 2'd10; //num of cycles we want to maintain before a press counts
            logic [4:0] lastOut;
            logic [23:0] counter;

            always_ff @(posedge clk, posedge reset)
                if (reset) begin
                            s1 <= 4'b000;
                            s2 <= 4'b000;
                            counter <= 0;
                            lastOut <= 5'b10000;
                end
				// perform checks to see if the output is good enough to display
				else begin
					// check what the output is
					if  (out == 5'b10000) counter <= 0;
					else if (out == lastOut) counter <= counter + 1;
					else lastOut <= out;
						
					// check if it's been that long enough to update display
					if (counter == threshold) begin 
						s1 <= s2;
						s2 <= out;
						counter <= counter;
						lastOut <= out;
					end
				end
                
endmodule