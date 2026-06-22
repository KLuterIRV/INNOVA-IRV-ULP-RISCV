`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_pc_ctrl
// -----------------------------------------------------------------------------
// Description:
//   Program counter next-address control for the INNOVA IRV RV32E core.
//
// ULP/area note:
//   The sequential, branch and JAL paths share one PC adder:
//
//       pc_next = pc + selected_offset
//
//   JALR reuses the main ALU result from the core:
//
//       jalr_target = rs1 + imm_i
//
//   This avoids instantiating extra 32-bit adders.
// -----------------------------------------------------------------------------

module irv_pc_ctrl #(
    parameter integer PC_WIDTH = 8
) (
    input  wire [PC_WIDTH-1:0] pc,

    input  wire [31:0] imm_b,
    input  wire [31:0] imm_j,
    input  wire [31:0] jalr_target,

    input  wire        is_ebreak,
    input  wire        is_jal,
    input  wire        is_jalr,
    input  wire        is_branch,
    input  wire        branch_taken,
    input  wire        stall,

    output reg  [PC_WIDTH-1:0] pc_next,
    output wire                pc_we,
    output wire                halt_req
);

    assign halt_req = is_ebreak;

    // JALR clears target bit 0 by definition. Keep this bit visible to lint.
    wire unused_jalr_target_lsb;
    assign unused_jalr_target_lsb = jalr_target[0];

    // The physical PC only implements the low PC_WIDTH bits.
    // The high architectural bits are intentionally ignored and wrap inside
    // the implemented program memory.
    wire unused_pcctrl_high_bits;
    assign unused_pcctrl_high_bits = |{
        imm_b[31:8],
        imm_j[31:8],
        jalr_target[31:8]
    };

    // PC updates only when the instruction is not halted and not stalled.
    assign pc_we = !is_ebreak && !stall;

    wire branch_selected;
    assign branch_selected = is_branch && branch_taken;

    wire [PC_WIDTH-1:0] pc_plus4_offset;
    wire [PC_WIDTH-1:0] pc_offset;
    wire [PC_WIDTH-1:0] pc_plus_offset;

    assign pc_plus4_offset = {{(PC_WIDTH-3){1'b0}}, 3'b100};

    assign pc_offset = is_jal          ? imm_j[PC_WIDTH-1:0] :
                       branch_selected ? imm_b[PC_WIDTH-1:0] :
                                         pc_plus4_offset;

    assign pc_plus_offset = pc + pc_offset;

    always @(*) begin
        if (is_jalr) begin
            pc_next = {jalr_target[PC_WIDTH-1:1], 1'b0};
        end else begin
            pc_next = pc_plus_offset;
        end
    end

endmodule

`default_nettype wire
