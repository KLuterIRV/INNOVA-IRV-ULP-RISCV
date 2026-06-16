`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_peripheral_bus
// -----------------------------------------------------------------------------
// Description:
//   Memory-mapped peripheral handler for the INNOVA IRV TinyTapeout SoC.
//
// Responsibilities:
//   - Decode MMIO addresses.
//   - Generate write pulses for GPIO0, UART0 and I2C0.
//   - Return read data for UART0 and I2C0.
//   - Generate automatic stall for slow peripherals.
//
// Memory map:
//   0x1000_0000 -> GPIO0 output
//   0x1000_0004 -> UART0 TX data
//   0x1000_0008 -> UART0 status
//   0x1000_000C -> UART0 RX data
//
//   0x1000_0010 -> I2C0 control
//   0x1000_0014 -> I2C0 data
//   0x1000_0018 -> I2C0 status
//   0x1000_001C -> I2C0 divider
//
// Notes:
//   - UART0 TX write stalls while UART0 is busy.
//   - I2C0 CTRL/DIV writes stall while I2C0 is busy.
//   - I2C0 DATA write does not stall, so software can preload the next byte.
// -----------------------------------------------------------------------------

module irv_peripheral_bus (
    input  wire        load_en,
    input  wire        store_en,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,

    output reg  [31:0] rdata,
    output wire        stall,

    // GPIO0
    output wire        gpio0_we,
    output wire [7:0]  gpio0_wdata,

    // UART0
    input  wire        uart0_tx_busy,
    input  wire        uart0_rx_valid,
    input  wire [7:0]  uart0_rx_data,
    output wire [7:0]  uart0_tx_data,
    output wire        uart0_tx_start,
    output wire        uart0_rx_clear,

    // I2C0
    input  wire [7:0]  i2c0_status,
    input  wire [7:0]  i2c0_data_rd_data,

    output wire [7:0]  i2c0_ctrl_wr_data,
    output wire        i2c0_ctrl_we,

    output wire [7:0]  i2c0_data_wr_data,
    output wire        i2c0_data_we,

    output wire [7:0]  i2c0_div_wr_data,
    output wire        i2c0_div_we
);

    localparam [31:0] ADDR_GPIO0_OUT    = 32'h1000_0000;
    localparam [31:0] ADDR_UART0_TX     = 32'h1000_0004;
    localparam [31:0] ADDR_UART0_STATUS = 32'h1000_0008;
    localparam [31:0] ADDR_UART0_RX     = 32'h1000_000C;

    localparam [31:0] ADDR_I2C0_CTRL    = 32'h1000_0010;
    localparam [31:0] ADDR_I2C0_DATA    = 32'h1000_0014;
    localparam [31:0] ADDR_I2C0_STATUS  = 32'h1000_0018;
    localparam [31:0] ADDR_I2C0_DIV     = 32'h1000_001C;

    wire i2c0_busy;
    assign i2c0_busy = i2c0_status[0];

    // Upper write-data bits are intentionally unused for current 8-bit
    // peripherals. They are kept in the bus interface for future 32-bit
    // peripherals or wider MMIO registers.
    wire unused_wdata_upper;
    assign unused_wdata_upper = |wdata[31:8];

    // ---------------------------------------------------------------------
    // Automatic stall generation
    // ---------------------------------------------------------------------

    assign stall =
        store_en &&
        (
            ((addr == ADDR_UART0_TX) && uart0_tx_busy) ||
            (((addr == ADDR_I2C0_CTRL) ||
              (addr == ADDR_I2C0_DIV)) && i2c0_busy)
        );

    // ---------------------------------------------------------------------
    // Write decode
    // ---------------------------------------------------------------------

    assign gpio0_we    = store_en && !stall && (addr == ADDR_GPIO0_OUT);
    assign gpio0_wdata = wdata[7:0];

    assign uart0_tx_start = store_en && !stall && (addr == ADDR_UART0_TX);
    assign uart0_tx_data  = wdata[7:0];

    assign i2c0_ctrl_we      = store_en && !stall && (addr == ADDR_I2C0_CTRL);
    assign i2c0_ctrl_wr_data = wdata[7:0];

    assign i2c0_data_we      = store_en && !stall && (addr == ADDR_I2C0_DATA);
    assign i2c0_data_wr_data = wdata[7:0];

    assign i2c0_div_we       = store_en && !stall && (addr == ADDR_I2C0_DIV);
    assign i2c0_div_wr_data  = wdata[7:0];

    // Reading UART0 RX data consumes the byte.
    assign uart0_rx_clear = load_en && (addr == ADDR_UART0_RX);

    // ---------------------------------------------------------------------
    // Read decode
    // ---------------------------------------------------------------------

    always @(*) begin
        case (addr)
            ADDR_UART0_STATUS: begin
                rdata = {30'd0, uart0_rx_valid, uart0_tx_busy};
            end

            ADDR_UART0_RX: begin
                rdata = {24'd0, uart0_rx_data};
            end

            ADDR_I2C0_DATA: begin
                rdata = {24'd0, i2c0_data_rd_data};
            end

            ADDR_I2C0_STATUS: begin
                rdata = {24'd0, i2c0_status};
            end

            default: begin
                rdata = 32'd0;
            end
        endcase
    end

    // Keep load_en visible to lint; read mux is address-based by design.
    wire unused_load_en;
    assign unused_load_en = load_en;

endmodule

`default_nettype wire
