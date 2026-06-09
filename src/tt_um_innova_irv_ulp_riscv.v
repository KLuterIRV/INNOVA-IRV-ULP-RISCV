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

    /*
     * Memory subsystem test wrapper.
     *
     * cmd = ui_in[7:5]
     * payload = ui_in[4:0]
     *
     * Commands:
     * 000: set address low bits
     * 001: set control bits
     *      payload[1:0] = byte_sel
     *      payload[3:2] = imem_addr[6:5]
     *      payload[4]   = output select
     * 010: write selected byte to IMEM
     * 011: write selected byte to DMEM
     * 100: write selected byte to REGFILE
     * 101: set regfile rs1 address
     * 110: set regfile rs2 address
     * 111: set regfile rd/write address
     *
     * uio_in is write byte during write commands.
     *
     * uo_out:
     *   output_select = 0 -> selected byte from IMEM
     *   output_select = 1 -> selected byte from REGFILE rs1
     *
     * uio_out:
     *   output_select = 0 -> selected byte from DMEM
     *   output_select = 1 -> selected byte from REGFILE rs2
     */

    localparam CMD_SET_ADDR_LO = 3'b000;
    localparam CMD_SET_CTRL    = 3'b001;
    localparam CMD_WR_IMEM     = 3'b010;
    localparam CMD_WR_DMEM     = 3'b011;
    localparam CMD_WR_REG      = 3'b100;
    localparam CMD_SET_RS1     = 3'b101;
    localparam CMD_SET_RS2     = 3'b110;
    localparam CMD_SET_RD      = 3'b111;

    wire [2:0] cmd;
    wire [4:0] payload;

    assign cmd     = ui_in[7:5];
    assign payload = ui_in[4:0];

    reg [4:0] addr_lo;
    reg [1:0] imem_addr_hi;
    reg [1:0] byte_sel;
    reg       output_select;

    reg [3:0] rs1_addr;
    reg [3:0] rs2_addr;
    reg [3:0] rd_addr;

    reg imem_wr_en;
    reg dmem_wr_en;
    reg reg_wr_en;

    wire [6:0] imem_addr;
    wire [4:0] dmem_addr;

    assign imem_addr = {imem_addr_hi, addr_lo};
    assign dmem_addr = addr_lo;

    wire [31:0] imem_rdata;
    wire [31:0] dmem_rdata;
    wire [31:0] rs1_rdata;
    wire [31:0] rs2_rdata;

    reg [31:0] imem_wdata;
    reg [31:0] dmem_wdata;
    reg [31:0] reg_wdata;

    wire [7:0] imem_byte;
    wire [7:0] dmem_byte;
    wire [7:0] rs1_byte;
    wire [7:0] rs2_byte;

    assign imem_byte = (byte_sel == 2'd0) ? imem_rdata[7:0]   :
                       (byte_sel == 2'd1) ? imem_rdata[15:8]  :
                       (byte_sel == 2'd2) ? imem_rdata[23:16] :
                                            imem_rdata[31:24];

    assign dmem_byte = (byte_sel == 2'd0) ? dmem_rdata[7:0]   :
                       (byte_sel == 2'd1) ? dmem_rdata[15:8]  :
                       (byte_sel == 2'd2) ? dmem_rdata[23:16] :
                                            dmem_rdata[31:24];

    assign rs1_byte = (byte_sel == 2'd0) ? rs1_rdata[7:0]   :
                      (byte_sel == 2'd1) ? rs1_rdata[15:8]  :
                      (byte_sel == 2'd2) ? rs1_rdata[23:16] :
                                           rs1_rdata[31:24];

    assign rs2_byte = (byte_sel == 2'd0) ? rs2_rdata[7:0]   :
                      (byte_sel == 2'd1) ? rs2_rdata[15:8]  :
                      (byte_sel == 2'd2) ? rs2_rdata[23:16] :
                                           rs2_rdata[31:24];

    always @(*) begin
        imem_wdata = imem_rdata;
        dmem_wdata = dmem_rdata;
        reg_wdata  = rs1_rdata;

        case (byte_sel)
            2'd0: begin
                imem_wdata[7:0]   = uio_in;
                dmem_wdata[7:0]   = uio_in;
                reg_wdata[7:0]    = uio_in;
            end

            2'd1: begin
                imem_wdata[15:8]  = uio_in;
                dmem_wdata[15:8]  = uio_in;
                reg_wdata[15:8]   = uio_in;
            end

            2'd2: begin
                imem_wdata[23:16] = uio_in;
                dmem_wdata[23:16] = uio_in;
                reg_wdata[23:16]  = uio_in;
            end

            default: begin
                imem_wdata[31:24] = uio_in;
                dmem_wdata[31:24] = uio_in;
                reg_wdata[31:24]  = uio_in;
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            addr_lo        <= 5'd0;
            imem_addr_hi   <= 2'd0;
            byte_sel       <= 2'd0;
            output_select  <= 1'b0;

            rs1_addr       <= 4'd0;
            rs2_addr       <= 4'd1;
            rd_addr        <= 4'd1;

            imem_wr_en     <= 1'b0;
            dmem_wr_en     <= 1'b0;
            reg_wr_en      <= 1'b0;
        end else begin
            imem_wr_en <= 1'b0;
            dmem_wr_en <= 1'b0;
            reg_wr_en  <= 1'b0;

            case (cmd)
                CMD_SET_ADDR_LO: begin
                    addr_lo <= payload;
                end

                CMD_SET_CTRL: begin
                    byte_sel      <= payload[1:0];
                    imem_addr_hi  <= payload[3:2];
                    output_select <= payload[4];
                end

                CMD_WR_IMEM: begin
                    imem_wr_en <= 1'b1;
                end

                CMD_WR_DMEM: begin
                    dmem_wr_en <= 1'b1;
                end

                CMD_WR_REG: begin
                    reg_wr_en <= 1'b1;
                end

                CMD_SET_RS1: begin
                    rs1_addr <= payload[3:0];
                end

                CMD_SET_RS2: begin
                    rs2_addr <= payload[3:0];
                end

                CMD_SET_RD: begin
                    rd_addr <= payload[3:0];
                end

                default: begin
                    imem_wr_en <= 1'b0;
                    dmem_wr_en <= 1'b0;
                    reg_wr_en  <= 1'b0;
                end
            endcase
        end
    end

    latch_mem_1r1w #(
        .ADDR_BITS  (7),
        .DATA_WIDTH (32)
    ) u_imem (
        .wr_en   (imem_wr_en),
        .wr_addr (imem_addr),
        .wr_data (imem_wdata),
        .rd_addr (imem_addr),
        .rd_data (imem_rdata)
    );

    latch_mem_1r1w #(
        .ADDR_BITS  (5),
        .DATA_WIDTH (32)
    ) u_dmem (
        .wr_en   (dmem_wr_en),
        .wr_addr (dmem_addr),
        .wr_data (dmem_wdata),
        .rd_addr (dmem_addr),
        .rd_data (dmem_rdata)
    );

    latch_regfile_2r1w u_regfile (
        .wr_en     (reg_wr_en),
        .wr_addr   (rd_addr),
        .wr_data   (reg_wdata),

        .rd_addr_a (rs1_addr),
        .rd_data_a (rs1_rdata),

        .rd_addr_b (rs2_addr),
        .rd_data_b (rs2_rdata)
    );

    assign uo_out  = ena ? (output_select ? rs1_byte  : imem_byte) : 8'd0;
    assign uio_out = ena ? (output_select ? rs2_byte  : dmem_byte) : 8'd0;

    assign uio_oe = ((cmd == CMD_WR_IMEM) ||
                     (cmd == CMD_WR_DMEM) ||
                     (cmd == CMD_WR_REG)) ? 8'h00 : 8'hFF;

endmodule

`default_nettype wire