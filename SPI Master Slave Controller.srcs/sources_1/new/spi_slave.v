`timescale 1ns/1ps


module spi_slave(
    input wire clk,
    input wire rst,
    input wire SCLK,
    input wire CS,
    input wire MOSI,
    input wire [7:0] tx,
    input wire cpol,
    input wire cpha,

    output reg [7:0] rx,
    output reg MISO,
    output reg done
);

    reg [7:0] tx_shift_reg;
    reg [7:0] rx_shift_reg;

    reg [3:0] bit_count;

    reg sclk_prev;
    reg cs_prev;

    always @(posedge clk) begin

        if (rst) begin

            tx_shift_reg <= 8'b00000000;
            rx_shift_reg <= 8'b00000000;

            bit_count <= 4'b0000;

            rx   <= 8'b00000000;
            MISO <= 1'b0;
            done <= 1'b0;

            sclk_prev <= cpol;
            cs_prev   <= 1'b1;

        end

        else begin

            done <= 1'b0;

            sclk_prev <= SCLK;
            cs_prev   <= CS;


            if (CS) begin

                bit_count <= 4'b0000;
                rx_shift_reg <= 8'b00000000;

                MISO <= 1'b0;

            end


            else begin

                /*
                 * Detect CS falling edge.
                 */

                if (cs_prev == 1'b1) begin

                    tx_shift_reg <= tx;
                    rx_shift_reg <= 8'b00000000;

                    bit_count <= 4'b0000;

                    /*
                     * CPHA = 0:
                     * First MISO bit must already be present
                     * before the first leading edge.
                     */

                    if (cpha == 1'b0) begin

                        MISO <= tx[7];

                        tx_shift_reg <= {
                            tx[6:0],
                            1'b0
                        };

                    end

                    else begin

                        MISO <= 1'b0;

                    end

                end


                /*
                 * Detect SCLK transition.
                 */

                else if (SCLK != sclk_prev) begin

                    /*
                     * If SCLK changes away from CPOL,
                     * this is the leading edge.
                     *
                     * If SCLK changes toward CPOL,
                     * this is the trailing edge.
                     */

                    if (SCLK != cpol) begin

                        // Leading edge

                        if (cpha == 1'b0) begin

                            /*
                             * CPHA = 0
                             * Sample MOSI on leading edge.
                             */

                            rx_shift_reg <= {
                                rx_shift_reg[6:0],
                                MOSI
                            };

                            bit_count <= bit_count + 1'b1;

                            if (bit_count == 4'd7) begin

                                rx <= {
                                    rx_shift_reg[6:0],
                                    MOSI
                                };

                                done <= 1'b1;

                            end

                        end

                        else begin

                            /*
                             * CPHA = 1
                             * Change MISO on leading edge.
                             */

                            MISO <= tx_shift_reg[7];

                            tx_shift_reg <= {
                                tx_shift_reg[6:0],
                                1'b0
                            };

                        end

                    end


                    else begin

                        // Trailing edge

                        if (cpha == 1'b0) begin

                            /*
                             * CPHA = 0
                             * Change MISO on trailing edge.
                             */

                            MISO <= tx_shift_reg[7];

                            tx_shift_reg <= {
                                tx_shift_reg[6:0],
                                1'b0
                            };

                        end

                        else begin

                            /*
                             * CPHA = 1
                             * Sample MOSI on trailing edge.
                             */

                            rx_shift_reg <= {
                                rx_shift_reg[6:0],
                                MOSI
                            };

                            bit_count <= bit_count + 1'b1;

                            if (bit_count == 4'd7) begin

                                rx <= {
                                    rx_shift_reg[6:0],
                                    MOSI
                                };

                                done <= 1'b1;

                            end

                        end

                    end

                end

            end

        end

    end

endmodule