`default_nettype none

module sram_macro_smoke_test (
    input  wire       clk,
    input  wire       rst,
    input  wire       we,
    input  wire [5:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata
);

    wire cen;
    wire gwen;
    wire [7:0] wen;

    assign cen  = 1'b0;               // Active-low chip enable
    assign gwen = ~we;                // Active-low global write enable
    assign wen  = we ? 8'h00 : 8'hFF; // Active-low write mask

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_sram (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen),
        .WEN  (wen),
        .A    (addr),
        .D    (wdata),
        .Q    (rdata)
    );

    wire _unused;
    assign _unused = &{rst, 1'b0};

endmodule

`default_nettype wire