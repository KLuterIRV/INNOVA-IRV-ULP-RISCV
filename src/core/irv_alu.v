`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_alu
// -----------------------------------------------------------------------------
// Description:
//   Minimal combinational ALU for the progressive TinyTapeout RISC-V core.
//
// Current supported operations:
//   - ADD
//   - SUB
//   - AND
//   - OR
//   - XOR
//
// Future operations:
//   - SLT
//   - SLTU
//   - SLL
//   - SRL
//   - SRA
//
// Notes:
//   The ALU is purely combinational. Register writeback is handled outside
//   this block by the core/regfile.
// -----------------------------------------------------------------------------

module irv_alu (
    input  wire [3:0]  alu_op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y,
    output wire        eq
);

    localparam [3:0]
        ALU_ADD = 4'd0,
        ALU_SUB = 4'd1,
        ALU_AND = 4'd2,
        ALU_OR  = 4'd3,
        ALU_XOR = 4'd4;

    assign eq = (a == b);

    always @(*) begin
        case (alu_op)
            ALU_ADD: y = a + b;
            ALU_SUB: y = a - b;
            ALU_AND: y = a & b;
            ALU_OR:  y = a | b;
            ALU_XOR: y = a ^ b;
            default: y = 32'd0;
        endcase
    end

endmodule

`default_nettype wire
