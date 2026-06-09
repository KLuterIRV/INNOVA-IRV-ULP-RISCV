`default_nettype none

module gf180_latch_bit (
    input  wire en,
    input  wire d,
    output wire q
);

`ifdef SIM
    /* verilator lint_off LATCH */
    reg q_reg;
    assign q = q_reg;

    always @(*) begin
        if (en) begin
            q_reg = d;
        end
    end
    /* verilator lint_on LATCH */
`else
    /*
     * GF180 latch cell.
     *
     * Do not connect VDD/VSS/VNW/VPW explicitly here.
     * In the Tiny Tapeout / LibreLane GF180 flow, these power pins
     * are handled by the PDK/netlist/power insertion flow.
     */
    /* verilator lint_off PINMISSING */
    gf180mcu_fd_sc_mcu7t5v0__latq_1 u_lat (
        .E (en),
        .D (d),
        .Q (q)
    );
    /* verilator lint_on PINMISSING */
`endif

endmodule

`default_nettype wire