/* Ellie Sundheim (esundheim@hmc.edu)
9/14/24
This code reads a 4x4 matirx scanner and outputs to 2 seven-segment LED displays*/

//top module, structural verilog
module top (input logic C0, C1, C2, C3);

endmodule

// finits state machine to control scanning
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
            state <= nextstate;

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
                scanR0: out = 5'b10000; row = 4'b0001;
                scanR0: out = 5'b10000; row = 4'b0010;
                scanR0: out = 5'b10000; row = 4'b0100;
                scanR0: out = 5'b10000; row = 4'b1000;
            // pressed states
            //row 0
                pressA: out = 5'b01010; row = 4'b0001;
                press0: out = 5'b00000; row = 4'b0001;
                pressB: out = 5'b01011; row = 4'b0001;
                pressF: out = 5'b01111; row = 4'b0001;
            //row 1
                press7: out = 5'b00111; row = 4'b0010;
                press8: out = 5'b01000; row = 4'b0010;
                press9: out = 5'b01001; row = 4'b0010;
                pressE: out = 5'b01110; row = 4'b0010;
            //row 2
                press4: out = 5'b00100; row = 4'b0100;
                press5: out = 5'b00101; row = 4'b0100;
                press6: out = 5'b00110; row = 4'b0100;
                pressD: out = 5'b01101; row = 4'b0100;
            //row 3
                press1: out = 5'b00001; row = 4'b1000;
                press2: out = 5'b00010; row = 4'b1000;
                press3: out = 5'b00011; row = 4'b1000;
                pressC: out = 5'b01100; row = 4'b1000;
        
            endcase
        end


endmodule