`default_nettype none
`timescale 1ns/1ps

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
    gf180mcu_fd_sc_mcu7t5v0__latq_1 u_lat (
        .E   (en),
        .D   (d),
        .Q   (q),
        .VDD (1'b1),
        .VSS (1'b0),
        .VNW (1'b1),
        .VPW (1'b0)
    );
`endif

endmodule

`default_nettype wire