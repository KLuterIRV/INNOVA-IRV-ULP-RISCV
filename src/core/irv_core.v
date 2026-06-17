`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_core
// -----------------------------------------------------------------------------
// Description:
//   Minimal RV32E-like CPU core for the INNOVA IRV TinyTapeout SoC.
//
// Responsibilities:
//   - Program counter and fetch FSM.
//   - Instruction fetch through 16-bit halfword instruction-memory interface.
//   - Decode.
//   - Register file.
//   - ALU.
//   - PC control.
//   - Register writeback.
//   - Peripheral/MMIO load/store request generation.
//
// Not included:
//   - TinyTapeout pins.
//   - Boot/programming interface.
//   - Physical SRAM macro wrapper.
//   - Peripheral implementations.
// -----------------------------------------------------------------------------

module irv_core (
    input  wire        clk,
    input  wire        rst,

    // Instruction memory, 16-bit halfword interface.
    output wire [5:0]  imem_addr,
    input  wire [15:0] imem_rdata,

    // Peripheral/MMIO bus.
    output wire        periph_load_en,
    output wire        periph_store_en,
    output wire [31:0] periph_addr,
    output wire [31:0] periph_wdata,
    input  wire [31:0] periph_rdata,
    input  wire        periph_stall,

    // Debug/status.
    output wire [31:0] pc_debug,
    output wire [31:0] instr_debug,
    output wire        halted
);

    // ---------------------------------------------------------------------
    // CPU state
    // ---------------------------------------------------------------------

    localparam [2:0]
        S_ADDR_LO = 3'd0,
        S_CAP_LO  = 3'd1,
        S_CAP_HI  = 3'd2,
        S_EXEC    = 3'd3,
        S_HALT    = 3'd4;

    reg [2:0]  state;
    reg [31:0] pc;
    reg        halted_r;

    wire [31:0] instr_reg;

    assign halted      = halted_r;
    assign pc_debug    = pc;
    assign instr_debug = instr_reg;

    // ---------------------------------------------------------------------
    // Decode
    // ---------------------------------------------------------------------

    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [4:0]  rs1;
    wire [4:0]  rs2;

    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_u;
    wire [31:0] imm_b;
    wire [31:0] imm_j;

    wire is_lui;
    wire is_op_imm;
    wire is_op;
    wire is_load;
    wire is_store;
    wire is_branch;
    wire is_jal;
    wire is_jalr;
    wire is_ebreak;

    irv_decoder u_decoder (
        .instr     (instr_reg),

        .opcode    (opcode),
        .rd        (rd),
        .funct3    (funct3),
        .funct7    (funct7),
        .rs1       (rs1),
        .rs2       (rs2),

        .imm_i     (imm_i),
        .imm_s     (imm_s),
        .imm_b     (imm_b),
        .imm_u     (imm_u),
        .imm_j     (imm_j),

        .is_lui    (is_lui),
        .is_op_imm (is_op_imm),
        .is_op     (is_op),
        .is_load   (is_load),
        .is_store  (is_store),
        .is_branch (is_branch),
        .is_jal    (is_jal),
        .is_jalr   (is_jalr),
        .is_ebreak (is_ebreak)
    );

    wire unused_decoder_fields;
    assign unused_decoder_fields = is_lui | is_op_imm | is_op | is_load |
                                   is_store | is_branch | is_jal | is_jalr |
                                   (|funct7);

    // ---------------------------------------------------------------------
    // Register file
    // ---------------------------------------------------------------------

    wire [31:0] rs1_val;
    wire [31:0] rs2_val;

    reg        rd_we;
    reg [4:0]  rd_waddr;
    reg [31:0] rd_wdata;

    irv_regfile u_regfile (
        .clk      (clk),
        .rst      (rst),

        .rs1      (rs1),
        .rs2      (rs2),
        .rs1_val  (rs1_val),
        .rs2_val  (rs2_val),

        .rd_we    (rd_we),
        .rd       (rd_waddr),
        .rd_wdata (rd_wdata)
    );

    // ---------------------------------------------------------------------
    // ALU
    // ---------------------------------------------------------------------

    localparam [3:0]
        IRV_ALU_ADD = 4'd0,
        IRV_ALU_SUB = 4'd1,
        IRV_ALU_AND = 4'd2,
        IRV_ALU_OR  = 4'd3,
        IRV_ALU_XOR = 4'd4;

    reg  [3:0]  alu_op;
    wire [31:0] alu_b;
    wire [31:0] alu_y;
    wire        alu_eq_unused;

    // OP-IMM uses the sign-extended immediate.
    // R-type OP uses rs2.
    assign alu_b = (opcode == 7'b0110011) ? rs2_val : imm_i;

    always @(*) begin
        alu_op = IRV_ALU_ADD;

        case (opcode)

            // OP-IMM: ADDI / XORI / ORI / ANDI
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_op = IRV_ALU_ADD; // ADDI
                    3'b100: alu_op = IRV_ALU_XOR; // XORI
                    3'b110: alu_op = IRV_ALU_OR;  // ORI
                    3'b111: alu_op = IRV_ALU_AND; // ANDI
                    default: alu_op = IRV_ALU_ADD;
                endcase
            end

            // OP: ADD / SUB / XOR / OR / AND
            7'b0110011: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000) begin
                            alu_op = IRV_ALU_SUB; // SUB
                        end else begin
                            alu_op = IRV_ALU_ADD; // ADD
                        end
                    end

                    3'b100: alu_op = IRV_ALU_XOR; // XOR
                    3'b110: alu_op = IRV_ALU_OR;  // OR
                    3'b111: alu_op = IRV_ALU_AND; // AND
                    default: alu_op = IRV_ALU_ADD;
                endcase
            end

            default: begin
                alu_op = IRV_ALU_ADD;
            end

        endcase
    end

    irv_alu u_alu (
        .alu_op (alu_op),
        .a      (rs1_val),
        .b      (alu_b),
        .y      (alu_y),
        .eq     (alu_eq_unused)
    );

    wire unused_alu_eq_sink;
    assign unused_alu_eq_sink = alu_eq_unused;

    // ---------------------------------------------------------------------
    // Branch and PC control
    // ---------------------------------------------------------------------

    wire branch_eq;
    wire branch_taken;

    assign branch_eq = (rs1_val == rs2_val);

    assign branch_taken =
        (opcode == 7'b1100011) &&
        (
            ((funct3 == 3'b000) && branch_eq)  || // BEQ
            ((funct3 == 3'b001) && !branch_eq)    // BNE
        );

    wire [31:0] pc_next;
    wire        pc_we;
    wire        pc_halt_req;

    wire [31:0] jalr_target;
    // Reuse ALU ADD path for JALR target instead of instantiating
    // an extra 32-bit adder: JALR target = rs1 + imm_i.
    assign jalr_target = alu_y;

    irv_pc_ctrl u_pc_ctrl (
        .pc           (pc),

        .imm_b        (imm_b),
        .imm_j        (imm_j),
        .jalr_target  (jalr_target),

        .is_ebreak    (is_ebreak),
        .is_jal       (is_jal),
        .is_jalr      (is_jalr),
        .is_branch    (is_branch),
        .branch_taken (branch_taken),
        .stall        (periph_stall),

        .pc_next      (pc_next),
        .pc_we        (pc_we),
        .halt_req     (pc_halt_req)
    );

    // ---------------------------------------------------------------------
    // Instruction fetch
    // ---------------------------------------------------------------------

    wire fetch_addr_lo;
    wire fetch_cap_lo;
    wire fetch_cap_hi;

    assign fetch_addr_lo = (state == S_ADDR_LO);
    assign fetch_cap_lo  = (state == S_CAP_LO);
    assign fetch_cap_hi  = (state == S_CAP_HI);

    irv_fetch u_fetch (
        .clk           (clk),
        .rst           (rst),

        .pc            (pc),

        .fetch_addr_lo (fetch_addr_lo),
        .fetch_cap_lo  (fetch_cap_lo),
        .fetch_cap_hi  (fetch_cap_hi),

        .sram_rhalf    (imem_rdata),

        .sram_addr     (imem_addr),
        .instr         (instr_reg)
    );

    // ---------------------------------------------------------------------
    // Peripheral/MMIO request generation
    // ---------------------------------------------------------------------

    assign periph_store_en = (state == S_EXEC) &&
                             (opcode == 7'b0100011) &&
                             (funct3 == 3'b010);

    assign periph_load_en  = (state == S_EXEC) &&
                             (opcode == 7'b0000011) &&
                             (funct3 == 3'b010);

    // ULP/area optimization:
    // Use one address adder for both LW and SW MMIO accesses.
    wire [31:0] periph_addr_imm;
    assign periph_addr_imm = periph_store_en ? imm_s : imm_i;

    assign periph_addr  = rs1_val + periph_addr_imm;
    assign periph_wdata = rs2_val;

    // ---------------------------------------------------------------------
    // Register file writeback generation
    // ---------------------------------------------------------------------

    always @(*) begin
        rd_we    = 1'b0;
        rd_waddr = rd;
        rd_wdata = 32'd0;

        if ((state == S_EXEC) &&
            !is_ebreak &&
            !periph_stall) begin

            case (opcode)

                // LUI
                7'b0110111: begin
                    if (rd != 5'd0) begin
                        rd_we    = 1'b1;
                        rd_wdata = imm_u;
                    end
                end

                // OP-IMM: ADDI / XORI / ORI / ANDI
                7'b0010011: begin
                    if ((rd != 5'd0) &&
                        ((funct3 == 3'b000) ||
                         (funct3 == 3'b100) ||
                         (funct3 == 3'b110) ||
                         (funct3 == 3'b111))) begin
                        rd_we    = 1'b1;
                        rd_wdata = alu_y;
                    end
                end

                // OP: ADD / SUB / XOR / OR / AND
                7'b0110011: begin
                    if ((rd != 5'd0) &&
                        (
                            ((funct3 == 3'b000) &&
                             ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
                            ((funct3 == 3'b100) && (funct7 == 7'b0000000)) ||
                            ((funct3 == 3'b110) && (funct7 == 7'b0000000)) ||
                            ((funct3 == 3'b111) && (funct7 == 7'b0000000))
                        )) begin
                        rd_we    = 1'b1;
                        rd_wdata = alu_y;
                    end
                end

                // LOAD: minimal memory-mapped peripheral reads
                7'b0000011: begin
                    if ((funct3 == 3'b010) && (rd != 5'd0)) begin
                        rd_we    = 1'b1;
                        rd_wdata = periph_rdata;
                    end
                end

                // JAL
                7'b1101111: begin
                    if (rd != 5'd0) begin
                        rd_we    = 1'b1;
                        rd_wdata = pc + 32'd4;
                    end
                end

                // JALR
                7'b1100111: begin
                    if ((funct3 == 3'b000) && (rd != 5'd0)) begin
                        rd_we    = 1'b1;
                        rd_wdata = pc + 32'd4;
                    end
                end

                default: begin
                    rd_we    = 1'b0;
                    rd_wdata = 32'd0;
                end

            endcase
        end
    end

    // ---------------------------------------------------------------------
    // CPU FSM
    // ---------------------------------------------------------------------

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_ADDR_LO;
            pc       <= 32'd0;
            halted_r <= 1'b0;
        end else begin
            case (state)

                S_ADDR_LO: begin
                    if (halted_r) begin
                        state <= S_HALT;
                    end else begin
                        state <= S_CAP_LO;
                    end
                end

                S_CAP_LO: begin
                    state <= S_CAP_HI;
                end

                S_CAP_HI: begin
                    state <= S_EXEC;
                end

                S_EXEC: begin
                    if (pc_halt_req) begin
                        halted_r <= 1'b1;
                        state    <= S_HALT;
                    end else if (!pc_we) begin
                        // Wait here until the selected peripheral is ready.
                        // PC is not advanced, so the same instruction is retried.
                        state <= S_EXEC;
                    end else begin
                        pc    <= pc_next;
                        state <= S_ADDR_LO;
                    end
                end

                S_HALT: begin
                    state <= S_HALT;
                end

                default: begin
                    state <= S_ADDR_LO;
                end

            endcase
        end
    end

endmodule

`default_nettype wire
