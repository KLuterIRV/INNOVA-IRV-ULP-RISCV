`default_nettype none

module latch_regfile_2r1w #(
    parameter DATA_WIDTH = 32
) (
    input  wire        wr_en,
    input  wire [3:0]  wr_addr,
    input  wire [31:0] wr_data,

    input  wire [3:0]  rd_addr_a,
    output wire [31:0] rd_data_a,

    input  wire [3:0]  rd_addr_b,
    output wire [31:0] rd_data_b
);

    wire [DATA_WIDTH-1:0] reg_q [0:15];

    assign reg_q[0] = 32'd0;

    genvar i;
    genvar j;

    generate
        for (i = 1; i < 16; i = i + 1) begin : gen_reg
            localparam [3:0] REG_ADDR = i[3:0];

            wire reg_sel;
            assign reg_sel = wr_en && (wr_addr == REG_ADDR);

            for (j = 0; j < DATA_WIDTH; j = j + 1) begin : gen_bit
                gf180_latch_bit u_latch_bit (
                    .en (reg_sel),
                    .d  (wr_data[j]),
                    .q  (reg_q[i][j])
                );
            end
        end
    endgenerate

    assign rd_data_a = (rd_addr_a == 4'd0) ? 32'd0 : reg_q[rd_addr_a];
    assign rd_data_b = (rd_addr_b == 4'd0) ? 32'd0 : reg_q[rd_addr_b];

endmodule

`default_nettype wire