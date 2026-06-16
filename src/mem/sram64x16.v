`default_nettype none

// -----------------------------------------------------------------------------
// Module: sram64x16
// -----------------------------------------------------------------------------
// Description:
//   Wrapper around two GF180 64x8 SRAM macros to form one 64x16 memory.
//
// Physical implementation:
//   - u_mem_b0 stores bits [7:0]
//   - u_mem_b1 stores bits [15:8]
//
// Capacity:
//   - 64 halfwords
//   - 128 bytes
//   - 32 RV32 instructions when used as instruction memory
//
// Boot mode:
//   - Writes one byte at a time using boot_byte_addr[6:0].
//   - boot_byte_addr[0] selects low/high byte.
//   - boot_byte_addr[6:1] selects halfword address.
//
// Run mode:
//   - Reads one 16-bit halfword per access.
// -----------------------------------------------------------------------------

module sram64x16 (
    input  wire        clk,

    // Boot/write interface
    input  wire        boot_mode,
    input  wire        boot_we,
    input  wire [6:0]  boot_byte_addr,
    input  wire [7:0]  boot_wdata,

    // Run/read interface
    input  wire [5:0]  run_addr,
    output wire [15:0] run_rdata,

    // Boot debug byte readback
    output wire [7:0]  boot_debug_byte
);

    wire [5:0] boot_half_addr;
    wire       boot_byte_sel;

    assign boot_half_addr = boot_byte_addr[6:1];
    assign boot_byte_sel  = boot_byte_addr[0];

    wire [5:0] sram_addr;
    assign sram_addr = boot_mode ? boot_half_addr : run_addr;

    wire we_b0;
    wire we_b1;

    assign we_b0 = boot_mode && boot_we && (boot_byte_sel == 1'b0);
    assign we_b1 = boot_mode && boot_we && (boot_byte_sel == 1'b1);

    wire gwen_b0;
    wire gwen_b1;

    assign gwen_b0 = ~we_b0;
    assign gwen_b1 = ~we_b1;

    wire [7:0] wen_b0;
    wire [7:0] wen_b1;

    assign wen_b0 = we_b0 ? 8'h00 : 8'hFF;
    assign wen_b1 = we_b1 ? 8'h00 : 8'hFF;

    wire [7:0] q0;
    wire [7:0] q1;

    // SRAM macro enable is active-low.
    wire cen;
    assign cen = 1'b0;

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b0 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b0),
        .WEN  (wen_b0),
        .A    (sram_addr),
        .D    (boot_wdata),
        .Q    (q0)
    );

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b1 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b1),
        .WEN  (wen_b1),
        .A    (sram_addr),
        .D    (boot_wdata),
        .Q    (q1)
    );

    assign run_rdata       = {q1, q0};
    assign boot_debug_byte = boot_byte_sel ? q1 : q0;

endmodule

`default_nettype wire
