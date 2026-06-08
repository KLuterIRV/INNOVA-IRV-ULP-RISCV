// ============================================================
// Tiny Tapeout wrapper for Minimal RV32E SoC
// ------------------------------------------------------------
// Maps the Tiny Tapeout fixed IO interface to the internal SoC.
// ============================================================

module tt_um_kluterirv_rv32e_core (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // Bidirectional IO input path
    output wire [7:0] uio_out,  // Bidirectional IO output path
    output wire [7:0] uio_oe,   // Bidirectional IO output enable
    input  wire       ena,      // Design enable
    input  wire       clk,      // Clock
    input  wire       rst_n     // Active-low reset
);

    // ------------------------------------------------------------
    // Tiny Tapeout input mapping
    // ------------------------------------------------------------

    wire rst;                   // Internal active-high reset
    wire boot_mode;             // Boot-loader enable
    wire uart0_rx;              // UART RX input
    wire uart0_tx;              // UART TX output

    wire [7:0] gpio_out;        // Shared GPIO / seven-segment output
    wire [7:0] sevenseg_out;    // Internal seven-segment decoded output

    wire [31:0] pc_debug;       // Internal debug only
    wire [31:0] instr_debug;    // Internal debug only
    wire halted_debug;          // Core halted status
    wire loader_done_debug;     // Loader done status
    wire loader_error_debug;    // Loader error status

    assign rst       = ~rst_n;  // Convert Tiny Tapeout active-low reset to active-high
    assign boot_mode = ui_in[0];// ui_in[0] selects boot-loader mode
    assign uart0_rx  = ui_in[1];// ui_in[1] is UART RX

    // ------------------------------------------------------------
    // Internal SoC
    // ------------------------------------------------------------

    soc_top u_soc_top (
        .clk                (clk),
        .rst                (rst),
        .boot_mode          (boot_mode),
        .uart0_rx           (uart0_rx),
        .gpio_out           (gpio_out),
        .sevenseg_out       (sevenseg_out),
        .uart0_tx           (uart0_tx),
        .pc_debug           (pc_debug),
        .instr_debug        (instr_debug),
        .halted_debug       (halted_debug),
        .loader_done_debug  (loader_done_debug),
        .loader_error_debug (loader_error_debug)
    );

    // ------------------------------------------------------------
    // Output mapping
    // ------------------------------------------------------------

    assign uo_out = ena ? gpio_out : 8'd0;

    assign uio_out[0]   = uart0_tx;
    assign uio_out[1]   = halted_debug;
    assign uio_out[2]   = loader_done_debug;
    assign uio_out[3]   = loader_error_debug;
    assign uio_out[7:4] = 4'd0;

    assign uio_oe[0]   = ena;      // uart0_tx output
    assign uio_oe[1]   = ena;      // halted_debug output
    assign uio_oe[2]   = ena;      // loader_done_debug output
    assign uio_oe[3]   = ena;      // loader_error_debug output
    assign uio_oe[7:4] = 4'b0000;  // unused bidirectional pins set as inputs

    // ------------------------------------------------------------
    // Mark unused inputs/signals to avoid synthesis/lint warnings
    // ------------------------------------------------------------

    wire _unused;
    assign _unused = &{
        uio_in,
        ui_in[7:2],
        sevenseg_out,
        pc_debug,
        instr_debug,
        1'b0
    };

endmodule