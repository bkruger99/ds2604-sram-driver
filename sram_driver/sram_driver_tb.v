`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

`timescale 1ns/1ns
`default_nettype none
module test;

    reg reset = 1; 
    integer i;

    /* Make a reset that pulses once. */
    initial begin

        $dumpfile("test.vcd");
        $dumpvars(0,test);
        # 800;
        reset <= 0;
 
        wait(ready == 1);
        // read first 255 addresses and check data is correct
        // data generated by gen_mem.py
        for( i = 13'd0; i <= 13'd255; i ++ ) begin
            address <= i;
            re <= 1;
            start <= 1;
            wait(ready == 0);
            start <= 0;
            wait(ready == 1);
            `assert(data_out, address);
        end

        # 800;
        wait(ready == 1);

        // write first 255 addresses back to front
        for( i = 13'd0; i <= 13'd255; i ++ ) begin
            address <= i;
            re <= 0;
            data_in <= 13'd255 - i;
            start <= 1;
            wait(ready == 0);
            start <= 0;
            wait(ready == 1);
        end

        # 800;
        wait(ready == 1);

        // read first 255 addresses and check data is correct
        // data written by routine above
        for( i = 13'd0; i <= 13'd255; i ++ ) begin
            address <= i;
            re <= 1;
            start <= 1;
            wait(ready == 0);
            start <= 0;
            wait(ready == 1);
            `assert(data_out, 13'd255 - i);
        end

        # 800
        $finish;

    end

    // about 12mhz with 1ns timescale
    reg clk = 0;

    always #80 clk = !clk;

    // wires for sram interface
    wire ready;
    reg [12:0] address = 0;
    reg [7:0] data_in = 0;
    wire [7:0] data_out;
    reg re = 0;
    reg start = 0;

    // sram driver
    sram_driver sram_driver_0(
        .clk(clk),
        .reset(reset),

        // module interface
        .ready(ready),
        .re(re),
        .start(start),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),

        // sram control pins
        .sram_address(sram_address),
        .sram_data_read(sram_data_read),
        .sram_data_write(sram_data_write),
        .sram_data_pins_oe(sram_data_pins_oe),
        .n_ce1(n_ce1),
        .ce2(ce2),
        .n_we(n_we),
        .n_oe(n_oe)
    );

    // wires for sram chip
    wire sram_data_pins_oe;
    wire [7:0] sram_data_write;
    wire [7:0] sram_data_read;
    wire [7:0] sram_data;

    // this will be done with the ICE40 inout config
    assign sram_data_read = sram_data_pins_oe ? 8'bz : sram_data;
    assign sram_data = sram_data_pins_oe ? sram_data_write : 8'bz;

    wire n_ce1;
    wire n_we;
    wire n_oe;
    wire ce2;
    wire [12:0] sram_address;

    // sram chip
    ds2064 #(.FILE("../ds2064/sram.txt")) ds2064_inst (.address(sram_address), .data(sram_data), .n_ce1(n_ce1), .ce2(ce2), .n_we(n_we), .n_oe(n_oe));

    endmodule
