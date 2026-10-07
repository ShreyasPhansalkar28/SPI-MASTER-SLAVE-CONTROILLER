`timescale 1ns/1ps

module spi_tb;

    reg clk;
    reg rst;
    reg start;

    reg [7:0] master_tx;
    reg [7:0] slave_tx;

    reg cpol;
    reg cpha;

    reg [15:0] clk_div;

    wire [7:0] master_rx;
    wire [7:0] slave_rx;

    wire busy;
    wire done;
    wire slave_done;

    wire MOSI;
    wire MISO;
    wire SCLK;
    wire CS;


    spi_master master_inst (

        .clk(clk),
        .rst(rst),
        .start(start),

        .tx(master_tx),

        .cpol(cpol),
        .cpha(cpha),

        .clk_div(clk_div),

        .MISO(MISO),

        .rx_data(master_rx),
        .busy(busy),
        .done(done),

        .MOSI(MOSI),
        .SCLK(SCLK),
        .CS(CS)

    );


    spi_slave slave_inst (

        .clk(clk),
        .rst(rst),

        .SCLK(SCLK),
        .CS(CS),
        .MOSI(MOSI),

        .tx(slave_tx),

        .cpol(cpol),
        .cpha(cpha),

        .rx(slave_rx),
        .MISO(MISO),
        .done(slave_done)

    );


    /*
     * 100 MHz system clock
     */

    always #5 clk = ~clk;


    /*
     * SPI transaction task
     */

    task run_test;

        input [1:0] mode;

        begin

            if (mode == 2'b00) begin
                cpol = 1'b0;
                cpha = 1'b0;
            end

            else if (mode == 2'b01) begin
                cpol = 1'b0;
                cpha = 1'b1;
            end

            else if (mode == 2'b10) begin
                cpol = 1'b1;
                cpha = 1'b0;
            end

            else begin
                cpol = 1'b1;
                cpha = 1'b1;
            end


            master_tx = 8'hA5;
            slave_tx  = 8'h3C;


            #20;

            start = 1'b1;

            #10;

            start = 1'b0;


            wait(done == 1'b1);


            #10;


            if (master_rx == slave_tx)

                $display(
                    "MASTER RX PASS: Mode = %0d Expected = %h Received = %h",
                    mode,
                    slave_tx,
                    master_rx
                );

            else

                $display(
                    "MASTER RX FAIL: Mode = %0d Expected = %h Received = %h",
                    mode,
                    slave_tx,
                    master_rx
                );


            if (slave_rx == master_tx)

                $display(
                    "SLAVE RX PASS : Mode = %0d Expected = %h Received = %h",
                    mode,
                    master_tx,
                    slave_rx
                );

            else

                $display(
                    "SLAVE RX FAIL : Mode = %0d Expected = %h Received = %h",
                    mode,
                    master_tx,
                    slave_rx
                );


            if ((master_rx == slave_tx) &&
                (slave_rx == master_tx)) begin

                $display(
                    "========================================"
                );

                $display(
                    "MODE %0d TEST PASSED",
                    mode
                );

                $display(
                    "========================================"
                );

            end

            else begin

                $display(
                    "========================================"
                );

                $display(
                    "MODE %0d TEST FAILED",
                    mode
                );

                $display(
                    "========================================"
                );

            end


            #100;

        end

    endtask


    initial begin

        clk = 1'b0;

        rst = 1'b1;

        start = 1'b0;

        master_tx = 8'h00;
        slave_tx  = 8'h00;

        cpol = 1'b0;
        cpha = 1'b0;

        /*
         * 100 MHz system clock
         *
         * clk_div = 50
         *
         * approximately 1 MHz SPI clock
         */

        clk_div = 16'd50;


        /*
         * Reset
         */

        #100;

        rst = 1'b0;


        /*
         * MODE 0
         */

        run_test(2'b00);


        /*
         * MODE 1
         */

        run_test(2'b01);


        /*
         * MODE 2
         */

        run_test(2'b10);


        /*
         * MODE 3
         */

        run_test(2'b11);


        /*
         * Finish simulation
         */

        #100;

        $display("");
        $display("========================================");
        $display("ALL SPI MODE TESTS COMPLETED");
        $display("========================================");

        $finish;

    end

endmodule