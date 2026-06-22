`default_nettype none

module tt_um_kluterirv_rv32e_core (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ---------------------------------------------------------------------
    // Reset / boot mode
    // ---------------------------------------------------------------------

    wire rst;
    assign rst = ~rst_n;

    wire boot_mode;
    assign boot_mode = rst;

    // Boot/programming interface while rst_n = 0:
    //
    // The 128x16 SRAM stores 256 bytes, so byte addressing requires 8 bits.
    // TinyTapeout exposes ui_in[7:1] plus uio_in[7:0] during reset. To keep
    // an 8-bit data path and a write-enable, the boot address MSB is latched
    // in a non-write phase:
    //
    //   phase A, latch addr[7]:
    //     ui_in[0]   = 0
    //     ui_in[7:1] = addr[6:0]
    //     uio_in[0]  = addr[7]
    //     clk pulse
    //
    //   phase B, write byte:
    //     ui_in[0]   = 1
    //     ui_in[7:1] = addr[6:0]
    //     uio_in     = byte data
    //     clk pulse
    //
    // Normal reset keeps ui_in[0] = 0, so SRAM is preserved.
    wire       boot_we;
    reg        boot_addr_msb;
    wire [7:0] boot_byte_addr;

    assign boot_we        = ui_in[0];
    assign boot_byte_addr = {boot_addr_msb, ui_in[7:1]};

    always @(posedge clk) begin
        if (!boot_mode) begin
            boot_addr_msb <= 1'b0;
        end else if (!boot_we) begin
            boot_addr_msb <= uio_in[0];
        end
    end

    // ---------------------------------------------------------------------
    // Core <-> instruction memory interface
    // ---------------------------------------------------------------------

    wire [6:0]  imem_addr;
    wire [15:0] imem_rdata;

    // ---------------------------------------------------------------------
    // Core <-> peripheral bus interface
    // ---------------------------------------------------------------------

    wire        periph_load_en;
    wire        periph_store_en;
    wire [7:0]  periph_addr;
    wire [7:0]  periph_wdata;
    wire [7:0]  periph_rdata;
    wire        periph_stall;

    wire        core_halted;

    // ---------------------------------------------------------------------
    // Peripheral wires
    // ---------------------------------------------------------------------

    wire       gpio0_we;
    wire [7:0] gpio0_wdata;
    wire [7:0] gpio0_out;

    wire [7:0] uart0_tx_data;
    wire       uart0_tx_start;
    wire       uart0_tx_busy;
    wire       uart0_tx;

    wire [7:0] uart0_rx_data;
    wire       uart0_rx_valid;
    wire       uart0_rx_overrun;
    wire       uart0_rx_clear;

    wire uart0_rx_debug_mode;
    assign uart0_rx_debug_mode = rst_n && ui_in[2];

    wire [7:0] i2c0_ctrl_wr_data;
    wire       i2c0_ctrl_we;

    wire [7:0] i2c0_data_wr_data;
    wire       i2c0_data_we;
    wire [7:0] i2c0_data_rd_data;

    wire [7:0] i2c0_div_wr_data;
    wire       i2c0_div_we;

    wire [7:0] i2c0_status;

    wire i2c0_scl_out;
    wire i2c0_scl_oe;
    wire i2c0_sda_out;
    wire i2c0_sda_oe;

    wire [7:0] boot_debug_byte;

    // ---------------------------------------------------------------------
    // SRAM wrapper
    // ---------------------------------------------------------------------

    sram128x16 u_sram128x16 (
        .clk             (clk),

        .boot_mode       (boot_mode),
        .boot_we         (boot_we),
        .boot_byte_addr  (boot_byte_addr),
        .boot_wdata      (uio_in),

        .run_addr        (imem_addr),
        .run_rdata       (imem_rdata),

        .boot_debug_byte (boot_debug_byte)
    );

    // ---------------------------------------------------------------------
    // Minimal interrupt sources
    // ---------------------------------------------------------------------

    wire [2:0] irq_status;
    wire [2:0] irq_enable;
    wire [2:0] irq_pending;

    assign irq_status[0] = uart0_rx_valid;
    assign irq_status[1] = uart0_rx_overrun;
    assign irq_status[2] = i2c0_status[1]; // I2C done

    assign irq_pending = irq_status & irq_enable;

    // ---------------------------------------------------------------------
    // CPU core
    // ---------------------------------------------------------------------

    irv_core u_core (
        .clk              (clk),
        .rst              (rst),

        .imem_addr        (imem_addr),
        .imem_rdata       (imem_rdata),

        .periph_load_en   (periph_load_en),
        .periph_store_en  (periph_store_en),
        .periph_addr      (periph_addr),
        .periph_wdata     (periph_wdata),
        .periph_rdata     (periph_rdata),
        .periph_stall     (periph_stall),

        .irq_pending      (irq_pending),

        .halted           (core_halted)
    );

    // ---------------------------------------------------------------------
    // GPIO0 peripheral
    // ---------------------------------------------------------------------

    gpio0 u_gpio0 (
        .clk      (clk),
        .rst      (rst),
        .we       (gpio0_we),
        .wdata    (gpio0_wdata),
        .gpio_out (gpio0_out)
    );

    // ---------------------------------------------------------------------
    // UART0 peripheral
    // ---------------------------------------------------------------------

    uart0 #(
        .CLKS_PER_BIT(8)
    ) u_uart0 (
        .clk      (clk),
        .rst      (rst),

        .tx_data  (uart0_tx_data),
        .tx_start (uart0_tx_start),
        .tx_busy  (uart0_tx_busy),
        .tx       (uart0_tx),

        .rx       (uio_in[1]),
        .rx_clear   (uart0_rx_clear),
        .rx_data    (uart0_rx_data),
        .rx_valid   (uart0_rx_valid),
        .rx_overrun (uart0_rx_overrun)
    );

    // ---------------------------------------------------------------------
    // I2C0 peripheral
    // ---------------------------------------------------------------------

    i2c0 u_i2c0 (
        .clk          (clk),
        .rst          (rst),

        .ctrl_wr_data (i2c0_ctrl_wr_data),
        .ctrl_we      (i2c0_ctrl_we),

        .data_wr_data (i2c0_data_wr_data),
        .data_we      (i2c0_data_we),
        .data_rd_data (i2c0_data_rd_data),

        .div_wr_data  (i2c0_div_wr_data),
        .div_we       (i2c0_div_we),

        .status       (i2c0_status),

        .scl_in       (uio_in[2]),
        .sda_in       (uio_in[3]),

        .scl_out      (i2c0_scl_out),
        .scl_oe       (i2c0_scl_oe),

        .sda_out      (i2c0_sda_out),
        .sda_oe       (i2c0_sda_oe)
    );

    // ---------------------------------------------------------------------
    // Peripheral bus / MMIO handler
    // ---------------------------------------------------------------------

    irv_peripheral_bus u_peripheral_bus (
        .clk                 (clk),
        .rst                 (rst),

        .load_en             (periph_load_en),
        .store_en            (periph_store_en),
        .addr                (periph_addr),
        .wdata               (periph_wdata),

        .rdata               (periph_rdata),
        .stall               (periph_stall),

        .irq_status          (irq_status),
        .irq_enable          (irq_enable),

        .gpio0_we            (gpio0_we),
        .gpio0_wdata         (gpio0_wdata),

        .uart0_tx_busy       (uart0_tx_busy),
        .uart0_rx_valid      (uart0_rx_valid),
        .uart0_rx_overrun    (uart0_rx_overrun),
        .uart0_rx_data       (uart0_rx_data),
        .uart0_tx_data       (uart0_tx_data),
        .uart0_tx_start      (uart0_tx_start),
        .uart0_rx_clear      (uart0_rx_clear),

        .i2c0_status         (i2c0_status),
        .i2c0_data_rd_data   (i2c0_data_rd_data),

        .i2c0_ctrl_wr_data   (i2c0_ctrl_wr_data),
        .i2c0_ctrl_we        (i2c0_ctrl_we),

        .i2c0_data_wr_data   (i2c0_data_wr_data),
        .i2c0_data_we        (i2c0_data_we),

        .i2c0_div_wr_data    (i2c0_div_wr_data),
        .i2c0_div_we         (i2c0_div_we)
    );

    // ---------------------------------------------------------------------
    // Tiny Tapeout outputs
    // ---------------------------------------------------------------------

    assign uo_out = ena
        ? (uart0_rx_debug_mode ? (uart0_rx_valid ? uart0_rx_data : 8'd0)
           : (boot_mode ? boot_debug_byte : gpio0_out))
        : 8'd0;

    // Bidirectional pin use:
    //   rst_n = 0 -> SRAM boot loader drives uio_in[7:0]
    //   rst_n = 1 -> UART/I2C communication mode
    //
    // High impedance is controlled only through uio_oe.
    // uio_out does not need a boot mux because uio_oe=0 releases the pins.
    assign uio_out = {4'd0, i2c0_sda_out, i2c0_scl_out, 1'b0, uart0_tx};

    assign uio_oe = {
        4'b0000,              // uio[7:4] unused / boot inputs
        rst_n & i2c0_sda_oe,  // uio[3] I2C SDA output-enable only in run mode
        rst_n & i2c0_scl_oe,  // uio[2] I2C SCL output-enable only in run mode
        1'b0,                 // uio[1] UART RX input
        rst_n                 // uio[0] UART TX output-enable only in run mode
    };

    // Keep halted visible to lint even when not externally muxed.
    wire unused_top_halted;
    assign unused_top_halted = core_halted;

endmodule

`default_nettype wire
