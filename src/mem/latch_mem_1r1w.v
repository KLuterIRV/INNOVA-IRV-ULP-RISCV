`default_nettype none

module latch_mem_1r1w #(
    parameter ADDR_BITS  = 5,
    parameter DATA_WIDTH = 32
) (
    input  wire                  wr_en,
    input  wire [ADDR_BITS-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,

    input  wire [ADDR_BITS-1:0]  rd_addr,
    output wire [DATA_WIDTH-1:0] rd_data
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

    assign rd_data = mem_q[rd_addr];

endmodule

`default_nettype wire