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
//   - SLT
//   - SLTU
//   - SLL
//   - SRL
//   - SRA
//
// Future operations:
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
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_AND  = 4'd2,
        ALU_OR   = 4'd3,
        ALU_XOR  = 4'd4,
        ALU_SLT  = 4'd5,
        ALU_SLTU = 4'd6,
        ALU_SLL  = 4'd7,
        ALU_SRL  = 4'd8,
        ALU_SRA  = 4'd9;

    assign eq = (a == b);

    always @(*) begin
        case (alu_op)
            ALU_ADD: y = a + b;
            ALU_SUB: y = a - b;
            ALU_AND:  y = a & b;
            ALU_OR:   y = a | b;
            ALU_XOR:  y = a ^ b;
            ALU_SLT:  y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: y = (a < b) ? 32'd1 : 32'd0;
            ALU_SLL:  y = a << b[4:0];
            ALU_SRL:  y = a >> b[4:0];
            ALU_SRA:  y = $signed(a) >>> b[4:0];
            default:  y = 32'd0;
        endcase
    end

endmodule

`default_nettype wire
