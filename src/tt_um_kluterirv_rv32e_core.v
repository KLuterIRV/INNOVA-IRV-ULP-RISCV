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

    // ------------------------------------------------------------
    // Unified 64x16 SRAM memory smoke test
    // ------------------------------------------------------------
    //
    // Physical memory:
    //   2 x gf180mcu_fd_ip_sram__sram64x8m8wm1
    //
    // Logical memory:
    //   64 words x 16 bits
    //
    // TinyTapeout pin test interface:
    //   ui_in[0]    = write enable
    //   ui_in[6:1]  = address[5:0]
    //   uio_in[0]   = byte lane select
    //                  0 -> low byte  [7:0]
    //                  1 -> high byte [15:8]
    //   uio_in[7:0] = byte write data
    //   uo_out[7:0] = selected byte read data
    //
    // Future CPU integration:
    //   RV32 instruction fetch will use two 16-bit reads:
    //     fetch_lo -> instr[15:0]
    //     fetch_hi -> instr[31:16]

    wire        mem_we;
    wire [5:0]  mem_addr;
    wire        byte_sel;
    wire [7:0]  mem_wbyte;

    assign mem_we    = ui_in[0];
    assign mem_addr  = ui_in[6:1];
    assign byte_sel  = uio_in[0];
    assign mem_wbyte = uio_in[7:0];

    wire [7:0] q0;
    wire [7:0] q1;

    wire [15:0] mem_rdata;
    assign mem_rdata = {q1, q0};

    wire [7:0] selected_rbyte;
    assign selected_rbyte = byte_sel ? q1 : q0;

    // GF180 SRAM control pins are active-low.
    wire cen;
    assign cen = 1'b0;

    wire we_b0;
    wire we_b1;

    assign we_b0 = mem_we && (byte_sel == 1'b0);
    assign we_b1 = mem_we && (byte_sel == 1'b1);

    wire gwen_b0;
    wire gwen_b1;

    assign gwen_b0 = ~we_b0;
    assign gwen_b1 = ~we_b1;

    wire [7:0] wen_b0;
    wire [7:0] wen_b1;

    assign wen_b0 = we_b0 ? 8'h00 : 8'hFF;
    assign wen_b1 = we_b1 ? 8'h00 : 8'hFF;

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b0 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b0),
        .WEN  (wen_b0),
        .A    (mem_addr),
        .D    (mem_wbyte),
        .Q    (q0)
    );

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b1 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b1),
        .WEN  (wen_b1),
        .A    (mem_addr),
        .D    (mem_wbyte),
        .Q    (q1)
    );

    assign uo_out = ena ? selected_rbyte : 8'd0;

    assign uio_out = 8'd0;
    assign uio_oe  = 8'd0;

    wire _unused;
    assign _unused = &{rst, mem_rdata, uio_in[7:1], 1'b0};

endmodule

`default_nettype wire