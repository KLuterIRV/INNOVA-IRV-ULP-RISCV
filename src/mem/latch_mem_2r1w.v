`default_nettype none

module latch_mem_2r1w #(
    parameter ADDR_BITS  = 6,
    parameter DATA_WIDTH = 8
) (
    input  wire                  wr_en,
    input  wire [ADDR_BITS-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,

    input  wire [ADDR_BITS-1:0]  rd_addr_a,
    output wire [DATA_WIDTH-1:0] rd_data_a,

    input  wire [ADDR_BITS-1:0]  rd_addr_b,
    output wire [DATA_WIDTH-1:0] rd_data_b
);

    localparam DEPTH = (1 << ADDR_BITS);

    wire [DATA_WIDTH-1:0] mem_q [0:DEPTH-1];

    genvar i;
    genvar j;

    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : gen_word
            localparam [ADDR_BITS-1:0] WORD_ADDR = i[ADDR_BITS-1:0];

            wire word_sel;
            assign word_sel = wr_en && (wr_addr == WORD_ADDR);

            for (j = 0; j < DATA_WIDTH; j = j + 1) begin : gen_bit
                gf180_latch_bit u_latch_bit (
                    .en (word_sel),
                    .d  (wr_data[j]),
                    .q  (mem_q[i][j])
                );
            end
        end
    endgenerate

    assign rd_data_a = mem_q[rd_addr_a];
    assign rd_data_b = mem_q[rd_addr_b];

endmodule

`default_nettype wire