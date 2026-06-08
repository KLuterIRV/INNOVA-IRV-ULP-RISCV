`default_nettype none

module tb;

  // ============================================================
  // Tiny Tapeout testbench signals
  // ============================================================

  reg         clk;
  reg         rst_n;
  reg         ena;

  reg  [7:0]  ui_in;
  wire [7:0]  uo_out;

  reg  [7:0]  uio_in;
  wire [7:0]  uio_out;
  wire [7:0]  uio_oe;

  // ============================================================
  // Device under test
  // ============================================================

  tt_um_kluterirv_rv32e_core user_project (
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (uio_in),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (ena),
    .clk     (clk),
    .rst_n   (rst_n)
  );

  // ============================================================
  // Initial values
  // ============================================================

  initial begin
    clk    = 1'b0;
    rst_n  = 1'b0;
    ena    = 1'b1;
    ui_in  = 8'd0;
    uio_in = 8'd0;
  end

  // ============================================================
  // Waveform dump
  // ============================================================

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end

endmodule