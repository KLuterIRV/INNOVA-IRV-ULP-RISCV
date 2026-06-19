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

    // ---------------------------------------------------------------------
    // Shared configurable barrel shifter
    // ---------------------------------------------------------------------
    //
    // A direct Verilog implementation using:
    //   a << shamt
    //   a >> shamt
    //   $signed(a) >>> shamt
    //
    // can infer three independent barrel shifter networks.
    //
    // This implementation uses one right-shift barrel network:
    //   - SRL: direct logical right shift
    //   - SRA: direct arithmetic right shift using sign fill
    //   - SLL: bit-reverse input, logical right shift, bit-reverse output
    //
    // This keeps SLL/SRL/SRA functionality but reduces routing pressure.

    function [31:0] reverse32;
        input [31:0] in;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                reverse32[i] = in[31 - i];
            end
        end
    endfunction

    wire        shift_left;
    wire        shift_arith;
    wire        shift_fill;
    wire [4:0]  shift_amt;

    wire [31:0] shift_input;
    wire [31:0] shift_s1;
    wire [31:0] shift_s2;
    wire [31:0] shift_s4;
    wire [31:0] shift_s8;
    wire [31:0] shift_s16;
    wire [31:0] shift_right_result;
    wire [31:0] shifter_y;

    assign shift_left  = (alu_op == ALU_SLL);
    assign shift_arith = (alu_op == ALU_SRA);
    assign shift_fill  = shift_arith & a[31];
    assign shift_amt   = b[4:0];

    assign shift_input = shift_left ? reverse32(a) : a;

    assign shift_s1  = shift_amt[0] ? {shift_fill, shift_input[31:1]}       : shift_input;
    assign shift_s2  = shift_amt[1] ? {{2{shift_fill}},  shift_s1[31:2]}    : shift_s1;
    assign shift_s4  = shift_amt[2] ? {{4{shift_fill}},  shift_s2[31:4]}    : shift_s2;
    assign shift_s8  = shift_amt[3] ? {{8{shift_fill}},  shift_s4[31:8]}    : shift_s4;
    assign shift_s16 = shift_amt[4] ? {{16{shift_fill}}, shift_s8[31:16]}   : shift_s8;

    assign shift_right_result = shift_s16;
    assign shifter_y = shift_left ? reverse32(shift_right_result) : shift_right_result;


    always @(*) begin
        case (alu_op)
            ALU_ADD: y = a + b;
            ALU_SUB: y = a - b;
            ALU_AND:  y = a & b;
            ALU_OR:   y = a | b;
            ALU_XOR:  y = a ^ b;
            ALU_SLT:  y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: y = (a < b) ? 32'd1 : 32'd0;
            ALU_SLL,
            ALU_SRL,
            ALU_SRA:  y = shifter_y;
            default:  y = 32'd0;
        endcase
    end

endmodule

`default_nettype wire
