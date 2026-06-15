`default_nettype none

/* verilator lint_off WIDTHEXPAND */

module uart0 #(
    parameter integer CLKS_PER_BIT = 8
) (
    input  wire       clk,
    input  wire       rst,

    // TX register interface
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_busy,
    output wire       tx,

    // RX register interface
    input  wire       rx,
    input  wire       rx_clear,
    output wire [7:0] rx_data,
    output wire       rx_valid
);

    // ---------------------------------------------------------------------
    // UART TX
    // ---------------------------------------------------------------------
    //
    // Frame:
    //   idle  = 1
    //   start = 0
    //   8 data bits, LSB first
    //   stop  = 1

    localparam [2:0]
        TX_IDLE  = 3'd0,
        TX_START = 3'd1,
        TX_DATA  = 3'd2,
        TX_STOP  = 3'd3;

    reg [2:0]  tx_state;
    reg [15:0] tx_clk_count;
    reg [2:0]  tx_bit_index;
    reg [7:0]  tx_shift;
    reg        tx_reg;

    assign tx      = tx_reg;
    assign tx_busy = (tx_state != TX_IDLE);

    always @(posedge clk) begin
        if (rst) begin
            tx_state     <= TX_IDLE;
            tx_clk_count <= 16'd0;
            tx_bit_index <= 3'd0;
            tx_shift     <= 8'd0;
            tx_reg       <= 1'b1;
        end else begin
            case (tx_state)

                TX_IDLE: begin
                    tx_reg       <= 1'b1;
                    tx_clk_count <= 16'd0;
                    tx_bit_index <= 3'd0;

                    if (tx_start) begin
                        tx_shift <= tx_data;
                        tx_state <= TX_START;
                    end
                end

                TX_START: begin
                    tx_reg <= 1'b0;

                    if (tx_clk_count == (CLKS_PER_BIT - 1)) begin
                        tx_clk_count <= 16'd0;
                        tx_state     <= TX_DATA;
                    end else begin
                        tx_clk_count <= tx_clk_count + 16'd1;
                    end
                end

                TX_DATA: begin
                    tx_reg <= tx_shift[tx_bit_index];

                    if (tx_clk_count == (CLKS_PER_BIT - 1)) begin
                        tx_clk_count <= 16'd0;

                        if (tx_bit_index == 3'd7) begin
                            tx_bit_index <= 3'd0;
                            tx_state     <= TX_STOP;
                        end else begin
                            tx_bit_index <= tx_bit_index + 3'd1;
                        end
                    end else begin
                        tx_clk_count <= tx_clk_count + 16'd1;
                    end
                end

                TX_STOP: begin
                    tx_reg <= 1'b1;

                    if (tx_clk_count == (CLKS_PER_BIT - 1)) begin
                        tx_clk_count <= 16'd0;
                        tx_state     <= TX_IDLE;
                    end else begin
                        tx_clk_count <= tx_clk_count + 16'd1;
                    end
                end

                default: begin
                    tx_state <= TX_IDLE;
                end

            endcase
        end
    end

    // ---------------------------------------------------------------------
    // UART RX
    // ---------------------------------------------------------------------
    //
    // Simple receiver:
    //   - Detects falling edge/start bit.
    //   - Samples in the middle of the start bit.
    //   - Samples each data bit every CLKS_PER_BIT cycles.
    //   - Stores one byte.
    //   - Raises rx_valid until rx_clear is asserted.
    //
    // No FIFO.
    // No parity.
    // No framing error flag yet.
    // No interrupt yet.

    localparam [2:0]
        RX_IDLE  = 3'd0,
        RX_START = 3'd1,
        RX_DATA  = 3'd2,
        RX_STOP  = 3'd3,
        RX_DONE  = 3'd4;

    reg [2:0]  rx_state;
    reg [15:0] rx_clk_count;
    reg [2:0]  rx_bit_index;
    reg [7:0]  rx_shift;
    reg [7:0]  rx_data_reg;
    reg        rx_valid_reg;

    reg rx_meta;
    reg rx_sync;

    assign rx_data  = rx_data_reg;
    assign rx_valid = rx_valid_reg;

    always @(posedge clk) begin
        if (rst) begin
            rx_state     <= RX_IDLE;
            rx_clk_count <= 16'd0;
            rx_bit_index <= 3'd0;
            rx_shift     <= 8'd0;
            rx_data_reg  <= 8'd0;
            rx_valid_reg <= 1'b0;
            rx_meta      <= 1'b1;
            rx_sync      <= 1'b1;
        end else begin
            // Synchronize asynchronous RX input.
            rx_meta <= rx;
            rx_sync <= rx_meta;

            if (rx_clear) begin
                rx_valid_reg <= 1'b0;
            end

            case (rx_state)

                RX_IDLE: begin
                    rx_clk_count <= 16'd0;
                    rx_bit_index <= 3'd0;

                    // Start bit detection.
                    if (rx_sync == 1'b0) begin
                        rx_state <= RX_START;
                    end
                end

                RX_START: begin
                    // Sample in the middle of the start bit.
                    if (rx_clk_count == ((CLKS_PER_BIT / 2) - 1)) begin
                        if (rx_sync == 1'b0) begin
                            rx_clk_count <= 16'd0;
                            rx_state     <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 16'd1;
                    end
                end

                RX_DATA: begin
                    if (rx_clk_count == (CLKS_PER_BIT - 1)) begin
                        rx_clk_count <= 16'd0;
                        rx_shift[rx_bit_index] <= rx_sync;

                        if (rx_bit_index == 3'd7) begin
                            rx_bit_index <= 3'd0;
                            rx_state     <= RX_STOP;
                        end else begin
                            rx_bit_index <= rx_bit_index + 3'd1;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 16'd1;
                    end
                end

                RX_STOP: begin
                    if (rx_clk_count == (CLKS_PER_BIT - 1)) begin
                        rx_clk_count <= 16'd0;

                        // Accept the byte only if stop bit is high.
                        if (rx_sync == 1'b1) begin
                            rx_data_reg  <= rx_shift;
                            rx_valid_reg <= 1'b1;
                        end

                        rx_state <= RX_DONE;
                    end else begin
                        rx_clk_count <= rx_clk_count + 16'd1;
                    end
                end

                RX_DONE: begin
                    // Return to idle. rx_valid_reg remains set until rx_clear.
                    rx_state <= RX_IDLE;
                end

                default: begin
                    rx_state <= RX_IDLE;
                end

            endcase
        end
    end

endmodule

/* verilator lint_on WIDTHEXPAND */

`default_nettype wire
