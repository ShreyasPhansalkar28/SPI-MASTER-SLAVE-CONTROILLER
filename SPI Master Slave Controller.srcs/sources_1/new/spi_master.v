`timescale 1ns/1ps


module spi_master(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] tx,
    input wire cpol,
    input wire cpha,
    input wire [15:0] clk_div,
    input wire MISO,

    output reg [7:0] rx_data,
    output reg busy,
    output reg done,
    output reg MOSI,
    output reg SCLK,
    output reg CS
);

    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;

    reg [4:0] edge_count;
    reg [15:0] clk_counter;

    localparam IDLE     = 2'b00;
    localparam LOAD     = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam FINISH   = 2'b11;

    reg [1:0] state;

    always @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            tx_shift_reg <= 8'b00000000;
            rx_shift_reg <= 8'b00000000;

            edge_count  <= 5'b00000;
            clk_counter <= 16'b0000000000000000;

            rx_data <= 8'b00000000;

            busy <= 1'b0;
            done <= 1'b0;

            MOSI <= 1'b0;
            SCLK <= cpol;
            CS   <= 1'b1;

        end

        else begin

            case (state)

                IDLE: begin

                    busy <= 1'b0;
                    done <= 1'b0;

                    CS   <= 1'b1;
                    SCLK <= cpol;

                    if (start) begin
                        state <= LOAD;
                    end

                end


                LOAD: begin

                    tx_shift_reg <= tx;
                    rx_shift_reg <= 8'b00000000;

                    edge_count  <= 5'b00000;
                    clk_counter <= 16'b0000000000000000;

                    busy <= 1'b1;
                    CS   <= 1'b0;
                    SCLK <= cpol;

                    if (cpha == 1'b0) begin
                        MOSI <= tx[7];
                    end
                    else begin
                        MOSI <= 1'b0;
                    end

                    state <= TRANSFER;

                end


                TRANSFER: begin

                    if (clk_counter == clk_div) begin

                        clk_counter <= 16'b0000000000000000;

                        /*
                         * SCLK is currently at its old level.
                         *
                         * If current SCLK is equal to CPOL,
                         * the next edge is the leading edge.
                         *
                         * If current SCLK is different from CPOL,
                         * the next edge is the trailing edge.
                         */

                        if (SCLK == cpol) begin

                            // Leading edge

                            SCLK <= ~SCLK;

                            if (cpha == 1'b0) begin

                                // CPHA = 0
                                // Sample MISO on leading edge

                                rx_shift_reg <= {
                                    rx_shift_reg[6:0],
                                    MISO
                                };

                            end

                            else begin

                                // CPHA = 1
                                // Change MOSI on leading edge

                                MOSI <= tx_shift_reg[7];

                                tx_shift_reg <= {
                                    tx_shift_reg[6:0],
                                    1'b0
                                };

                            end

                        end

                        else begin

                            // Trailing edge

                            SCLK <= ~SCLK;

                            if (cpha == 1'b0) begin

                                // CPHA = 0
                                // Change MOSI on trailing edge

                                tx_shift_reg <= {
                                    tx_shift_reg[6:0],
                                    1'b0
                                };

                                MOSI <= tx_shift_reg[6];

                            end

                            else begin

                                // CPHA = 1
                                // Sample MISO on trailing edge

                                rx_shift_reg <= {
                                    rx_shift_reg[6:0],
                                    MISO
                                };

                            end

                        end

                        edge_count <= edge_count + 1'b1;

                        if (edge_count == 5'd15) begin
                            state <= FINISH;
                        end

                    end

                    else begin

                        clk_counter <= clk_counter + 1'b1;

                    end

                end


                FINISH: begin

                    rx_data <= rx_shift_reg;

                    busy <= 1'b0;
                    done <= 1'b1;

                    CS   <= 1'b1;
                    SCLK <= cpol;

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule