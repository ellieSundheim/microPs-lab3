/* Ellie Sundheim esundheim#hmc.edu
9/14/24
This file contains the testbenches for the modules that make up lab3_es
*/

// testbench settings
`timescale 1ns/1ns
`default_nettype none
`define N_TV 8

module test_debouncer();
    logic clk, reset;
    logic [4:0] out;
    logic [3:0] s1, s2;

    debouncer myDebouncer(clk, reset, out, s1, s2);

    always begin
    clk = 0; #5;
    clk = 1; #5;
    end

    //pulse reset
    initial begin
    reset = 0; #7; reset = 1; #7; reset = 0;

    //an nice clean output
    out = 5'b00100; # 60; out = 5'b10000; #60; out = 5'b01110; #60;

    //a gross bouncy output
    out = 5'b00001; #15; out = 5'b10000; #15; out = 5'b00001; #15; out = 5'b10000; #15; out = 5'b00001; #60;
    end
endmodule

module test_FSM();
    logic clk, reset;
    logic [3:0] col;
    logic [4:0] out;
    logic [3:0] row;

    scanner_FSM myFSM (clk, reset, col, out, row);
    always begin
    clk = 0; #5;
    clk = 1; #5;
    end

    //pulse reset
    initial begin
    reset = 0; #7; reset = 1; #24; reset = 0;

    // watch it go through at least one loop
    #10;

    //trigger column, wait, trigger different column
    col = 4'b0001; #30; col = 4'b0000; #20; col = 4'b0010;
    end

endmodule

module test_sync();
    logic clk, reset;
    logic [3:0] d;
    logic [3:0] q;

    synchronizer mySync (clk, reset, d, q);

    always begin
    clk = 0; #5;
    clk = 1; #5;
    end

    //pulse reset
    initial begin
    reset = 0; #7; reset = 1; #14; reset = 0;

    // apply d 
    d = 4'b0001; #10; 
    d = 4'b0010; #20;
    end

endmodule

module test_all();
    logic clk, reset;
    logic [3:0] async_col, col;
    logic [4:0] out;
    logic [3:0] row;

    scanner_FSM myTestFSM (clk, reset, col, out, row);
    synchronizer myTestSync (clk, reset, async_col, col);

    always begin
    clk = 0; #5;
    clk = 1; #5;
    end

    initial begin

    // col always has some value and it's not xxxx so might as well be 0
    async_col = 4'b0000;

    //pulse reset
    reset = 0; #7; reset = 1; #14; reset = 0; 

    // watch it go through at least one loop
    #10;

    //trigger column, wait, trigger different column
    async_col = 4'b0001; #30; async_col = 4'b0000; #20; async_col = 4'b0010; #20; 

    // test other inputs at same time
    async_col = 4'b0111; #20; async_col = 4'b0000; #20;
    end

endmodule

module test_top();
        logic clk;
        logic nreset, reset;
        logic [3:0] async_col, col;
        logic [3:0] row;
        logic [4:0] out;
        logic anode1_en, anode2_en;
		logic [3:0] sshow;
        logic [6:0] seg;

        top lab3_dut(clk, nreset, async_col, row, seg, anode1_en, anode2_en);

        always begin 
            clk = 1; #5;
            clk = 0; #5;
        end

        initial begin

        // col always has some value and it's not xxxx so might as well be 0
        async_col = 4'b0000;

        //pulse reset
        nreset = 1; #7; nreset = 0; #7; nreset = 1; 

        // watch it go through at least one loop
        #10;

        //trigger column, wait, trigger different column
        async_col = 4'b0001; #50; async_col = 4'b0000; #50; async_col = 4'b0010; #50; 

        // test other inputs at same time
        async_col = 4'b0111; #50; async_col = 4'b0000; #50;

        // bouncy col
        async_col = 4'b1111; #15; async_col = 4'b0000; #15; async_col = 4'b1111; #15; async_col = 4'b0000; async_col = 4'b1111; #50;
        end

endmodule