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

    assign sram_we    = ui_in[0];
    assign sram_addr  = {uio_in[5:1], ui_in[1]};
    assign sram_wdata = {ui_in[7:2], uio_in[1:0]};

    sram_macro_smoke_test u_sram_test (
        .clk   (clk),
        .rst   (rst),
        .we    (sram_we),
        .addr  (sram_addr),
        .wdata (sram_wdata),
        .rdata (sram_rdata)
    );

    assign uo_out = ena ? sram_rdata : 8'd0;

    assign uio_out = 8'd0;
    assign uio_oe  = 8'd0;

    wire _unused;
    assign _unused = &{uio_in[7:6], 1'b0};

endmodule

`default_nettype wire