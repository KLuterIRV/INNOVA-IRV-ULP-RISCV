`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_decoder
// -----------------------------------------------------------------------------
// Description:
//   Instruction field extractor and immediate generator for the progressive
//   TinyTapeout RISC-V core.
//
// Current scope:
//   - Extracts opcode, rd, funct3, funct7, rs1 and rs2.
//   - Generates I, S, B, U and J immediates.
//   - Provides simple instruction-class flags.
//
// Notes:
//   This module does not execute instructions.
//   It only decodes the current 32-bit instruction.
// -----------------------------------------------------------------------------

module irv_decoder (
    input  wire [31:0] instr,

    output wire [6:0]  opcode,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output wire [6:0]  funct7,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,

    output wire [31:0] imm_i,
    output wire [31:0] imm_s,
    output wire [31:0] imm_b,
    output wire [31:0] imm_u,
    output wire [31:0] imm_j,

    output wire        is_lui,
    output wire        is_auipc,
    output wire        is_op_imm,
    output wire        is_op,
    output wire        is_load,
    output wire        is_store,
    output wire        is_branch,
    output wire        is_jal,
    output wire        is_jalr,
    output wire        is_wfi,
    output wire        is_ebreak
);

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // I-type immediate: ADDI, ANDI, ORI, XORI, LW, future JALR.
    assign imm_i = {{20{instr[31]}}, instr[31:20]};

    // S-type immediate: stores.
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};

    // B-type immediate:
    // imm[12|10:5|4:1|11|0] = instr[31|30:25|11:8|7|0]
    assign imm_b = {
        {19{instr[31]}},
        instr[31],
        instr[7],
        instr[30:25],
        instr[11:8],
        1'b0
    };

    // U-type immediate: LUI / AUIPC.
    assign imm_u = {instr[31:12], 12'b0};

    // J-type immediate:
    // imm[20|10:1|11|19:12|0] = instr[31|30:21|20|19:12|0]
    assign imm_j = {
        {11{instr[31]}},
        instr[31],
        instr[19:12],
        instr[20],
        instr[30:21],
        1'b0
    };

    assign is_lui    = (opcode == 7'b0110111);
    assign is_auipc  = (opcode == 7'b0010111);
    assign is_op_imm = (opcode == 7'b0010011);
    assign is_op     = (opcode == 7'b0110011);
    assign is_load   = (opcode == 7'b0000011);
    assign is_store  = (opcode == 7'b0100011);
    assign is_branch = (opcode == 7'b1100011);
    assign is_jal    = (opcode == 7'b1101111);
    assign is_jalr   = (opcode == 7'b1100111) && (funct3 == 3'b000);

    // WFI encoding from RISC-V privileged spec.
    // In this minimal core it is used as sleep-until-interrupt.
    assign is_wfi    = (instr == 32'h1050_0073);

    // Minimal system trap handling.
    // ECALL and EBREAK both request halt in this tiny core.
    assign is_ebreak =
        (instr == 32'h0000_0073) || // ECALL
        (instr == 32'h0010_0073);   // EBREAK

endmodule

`default_nettype wire
