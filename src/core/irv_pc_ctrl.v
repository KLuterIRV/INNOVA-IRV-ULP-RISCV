`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_pc_ctrl
// -----------------------------------------------------------------------------
// Description:
//   Program counter next-address control for the INNOVA IRV RV32E core.
//
// Current supported control flow:
//   - Sequential execution: PC + 4
//   - Branch taken:        PC + imm_b
//   - JAL:                 PC + imm_j
//   - JALR:                (rs1 + imm_i) & ~1
//   - EBREAK:              request halt
//   - Peripheral stall:    hold PC
//
// Notes:
//   This module does not store the PC register.
//   It only computes the next PC and control enables.
// -----------------------------------------------------------------------------

module irv_pc_ctrl (
    input  wire [31:0] pc,

    input  wire [31:0] imm_b,
    input  wire [31:0] imm_j,
    input  wire [31:0] jalr_target,

    input  wire        is_ebreak,
    input  wire        is_jal,
    input  wire        is_jalr,
    input  wire        is_branch,
    input  wire        branch_taken,
    input  wire        stall,

    output reg  [31:0] pc_next,
    output wire        pc_we,
    output wire        halt_req
);

    assign halt_req = is_ebreak;

    // PC updates only when the instruction is not halted and not stalled.
    assign pc_we = !is_ebreak && !stall;

    always @(*) begin
        pc_next = pc + 32'd4;

        if (is_jal) begin
            pc_next = pc + imm_j;
        end else if (is_jalr) begin
            pc_next = {jalr_target[31:1], 1'b0};
        end else if (is_branch && branch_taken) begin
            pc_next = pc + imm_b;
        end
    end

endmodule

`default_nettype wire
