`default_nettype none

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

    // RX reserved interface, not fully implemented yet
    input  wire       rx,
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
    // UART RX placeholder
    // ---------------------------------------------------------------------
    //
    // RX is intentionally kept as a reserved interface for now.
    // We keep a small synchronizer so the rx input is not completely unused,
    // but we do not expose received bytes yet.

    reg rx_meta;
    reg rx_sync;

    always @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    assign rx_data  = 8'd0;
    assign rx_valid = 1'b0;

endmodule

`default_nettype wire
