`default_nettype none
`timescale 1ns / 1ps

module tb ();

    initial begin
        $dumpfile("tb.fst");
        $dumpvars(0, tb);
    end

    // Tiny Tapeout project interface
    reg clk;
    reg rst_n;
    reg ena;

    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

`ifdef GL_TEST

    // Gate-level netlist includes explicit power pins.
    supply1 VPWR;
    supply0 VGND;

    tt_um_kluterirv_rv32e_core user_project (
        .VPWR   (VPWR),
        .VGND   (VGND),
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

`else

    // RTL top does not include explicit power pins.
    tt_um_kluterirv_rv32e_core user_project (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

`endif

endmodule

`default_nettype wire