/* Ellie Sundheim esundheim#hmc.edu
9/14/24
This file contains the testbenches for the modules that make up lab3_es
*/

module test_debouncer()
    logic clk, reset;
    logic [4:0] out;
    logic [3:0] s1, s2;

    debouncer myDebouncer(clk, reset, out, s1, s2);

    always_comb begin
    clk = 0; #5;
    clk = 1; #5;
    end

    //pulse reset
    reset = 0; #7; reset = 1; #23; reset = 0; #8;

    //an nice clean output
    out = 5'b00100; # 30; output = 5'b10000; #10; output = 5'b01110; #10;

    //a gross bouncy output
    out = 5'b00001; #2; out = 5'b10000; #3; out = 5'b00001; #4; out = 5'b10000; #5; out = 5'b00001; #20;

endmodule