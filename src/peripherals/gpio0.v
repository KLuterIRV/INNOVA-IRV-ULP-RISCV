`default_nettype none

// -----------------------------------------------------------------------------
// Module: gpio0
// -----------------------------------------------------------------------------
// Description:
//   Minimal memory-mapped GPIO output peripheral.
//
// Current functionality:
//   - One 8-bit output register.
//   - Updated by a write-enable pulse from the MMIO/peripheral bus.
//
// Memory map connection:
//   - 0x1000_0000 -> GPIO output register
//
// Future growth:
//   - GPIO input register.
//   - GPIO output-enable register.
//   - GPIO interrupt/wake flags.
// -----------------------------------------------------------------------------

module gpio0 (
    input  wire       clk,
    input  wire       rst,

    input  wire       we,
    input  wire [7:0] wdata,

    output reg  [7:0] gpio_out
);

    always @(posedge clk) begin
        if (rst) begin
            gpio_out <= 8'd0;
        end else if (we) begin
            gpio_out <= wdata;
        end
    end

endmodule

`default_nettype wire
