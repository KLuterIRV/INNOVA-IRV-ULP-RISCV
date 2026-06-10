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

    wire rst;
    assign rst = ~rst_n;

    wire        sram_we;
    wire [5:0]  sram_addr;
    wire [7:0]  sram_wdata;
    wire [7:0]  sram_rdata;

    wire        cen;
    wire        gwen;
    wire [7:0]  wen;

    // Minimal pin mapping for single SRAM smoke test
    assign sram_we    = ui_in[0];
    assign sram_addr  = ui_in[6:1];
    assign sram_wdata = {uio_in[6:0], ui_in[7]};

    // GF180 SRAM control pins are active-low
    assign cen  = 1'b0;
    assign gwen = ~sram_we;
    assign wen  = sram_we ? 8'h00 : 8'hFF;

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_sram (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen),
        .WEN  (wen),
        .A    (sram_addr),
        .D    (sram_wdata),
        .Q    (sram_rdata)
    );

    assign uo_out = ena ? sram_rdata : 8'd0;

    assign uio_out = 8'd0;
    assign uio_oe  = 8'd0;

    wire _unused;
    assign _unused = &{rst, uio_in[7], 1'b0};

endmodule

`default_nettype wire