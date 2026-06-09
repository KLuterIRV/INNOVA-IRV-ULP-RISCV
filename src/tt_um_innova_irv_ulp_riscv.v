`default_nettype none

module tt_um_innova_irv_ulp_riscv (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    localparam CMD_SET_RA = 2'b00;
    localparam CMD_SET_RB = 2'b01;
    localparam CMD_SET_WA = 2'b10;
    localparam CMD_WRITE  = 2'b11;

    wire [1:0] cmd;
    wire [5:0] payload;

    assign cmd     = ui_in[7:6];
    assign payload = ui_in[5:0];

    reg [5:0] rd_addr_a;
    reg [5:0] rd_addr_b;
    reg [5:0] wr_addr;

    reg       wr_en;
    reg [7:0] wr_data;

    wire [7:0] rd_data_a;
    wire [7:0] rd_data_b;

    always @(posedge clk) begin
        if (!rst_n) begin
            rd_addr_a <= 6'd0;
            rd_addr_b <= 6'd1;
            wr_addr   <= 6'd0;
            wr_en     <= 1'b0;
            wr_data   <= 8'd0;
        end else begin
            wr_en <= 1'b0;

            case (cmd)
                CMD_SET_RA: begin
                    rd_addr_a <= payload;
                end

                CMD_SET_RB: begin
                    rd_addr_b <= payload;
                end

                CMD_SET_WA: begin
                    wr_addr <= payload;
                end

                CMD_WRITE: begin
                    wr_data <= uio_in;
                    wr_en   <= 1'b1;
                end

                default: begin
                    wr_en <= 1'b0;
                end
            endcase
        end
    end

    latch_mem_2r1w #(
        .ADDR_BITS  (6),
        .DATA_WIDTH (8)
    ) u_latch_mem (
        .wr_en     (wr_en),
        .wr_addr   (wr_addr),
        .wr_data   (wr_data),

        .rd_addr_a (rd_addr_a),
        .rd_data_a (rd_data_a),

        .rd_addr_b (rd_addr_b),
        .rd_data_b (rd_data_b)
    );

    assign uo_out  = ena ? rd_data_a : 8'd0;
    assign uio_out = ena ? rd_data_b : 8'd0;

    // During WRITE command, uio pins are inputs for write data.
    // Otherwise, uio pins expose read port B.
    assign uio_oe = (cmd == CMD_WRITE) ? 8'h00 : 8'hFF;

endmodule

`default_nettype wire