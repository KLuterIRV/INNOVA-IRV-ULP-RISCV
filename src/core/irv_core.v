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

    // Minimal interrupt inputs:
    //   irq_pending[0] = UART RX valid
    //   irq_pending[1] = UART RX overrun
    //   irq_pending[2] = I2C done
    input  wire [2:0]  irq_pending,

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
        S_HALT    = 3'd4,
        S_SLEEP   = 3'd5;

    localparam integer PC_WIDTH = 7;

    reg [2:0]            state;
    reg [PC_WIDTH-1:0]   pc;
    reg                  halted_r;

    wire [31:0] instr_reg;
    wire [31:0] pc_ext;

    assign pc_ext      = {{(32-PC_WIDTH){1'b0}}, pc};
    assign halted      = halted_r;
    assign pc_debug    = pc_ext;
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
    wire is_auipc;
    wire is_op_imm;
    wire is_op;
    wire is_load;
    wire is_store;
    wire is_branch;
    wire is_jal;
    wire is_jalr;
    wire is_wfi;
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
        .is_auipc  (is_auipc),
        .is_op_imm (is_op_imm),
        .is_op     (is_op),
        .is_load   (is_load),
        .is_store  (is_store),
        .is_branch (is_branch),
        .is_jal    (is_jal),
        .is_jalr   (is_jalr),
        .is_wfi    (is_wfi),
        .is_ebreak (is_ebreak)
    );

    wire unused_decoder_fields;
    assign unused_decoder_fields = is_lui | is_auipc | is_op_imm | is_op | is_load |
                                   is_store | is_branch | is_jal | is_jalr |
                                   is_wfi | (|funct7);

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
        IRV_ALU_ADD  = 4'd0,
        IRV_ALU_SUB  = 4'd1,
        IRV_ALU_AND  = 4'd2,
        IRV_ALU_OR   = 4'd3,
        IRV_ALU_XOR  = 4'd4,
        IRV_ALU_SLT  = 4'd5,
        IRV_ALU_SLTU = 4'd6,
        IRV_ALU_SLL  = 4'd7,
        IRV_ALU_SRL  = 4'd8,
        IRV_ALU_SRA  = 4'd9;

    reg  [3:0]  alu_op;
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_y;
    wire        alu_eq_unused;

    // AUIPC uses PC as ALU input A.
    // All other current ALU users use rs1.
    assign alu_a = (opcode == 7'b0010111) ? pc_ext : rs1_val;

    // OP-IMM/LOAD/JALR use imm_i.
    // STORE uses imm_s.
    // AUIPC uses imm_u.
    // R-type OP and BRANCH comparisons use rs2.
    //
    // This lets the ALU ADD path generate:
    //   - OP-IMM results
    //   - JALR target
    //   - LW/SW MMIO addresses
    //   - AUIPC result
    // without adding extra 32-bit adders.
    wire [31:0] alu_imm_b;
    assign alu_imm_b = (opcode == 7'b0100011) ? imm_s :
                       (opcode == 7'b0010111) ? imm_u :
                                                imm_i;

    assign alu_b = ((opcode == 7'b0110011) ||
                    (opcode == 7'b1100011)) ? rs2_val : alu_imm_b;

    always @(*) begin
        alu_op = IRV_ALU_ADD;

        case (opcode)

            // OP-IMM: ADDI / SLLI / SLTI / SLTIU / XORI / SRLI / SRAI / ORI / ANDI
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_op = IRV_ALU_ADD;  // ADDI
                    3'b001: alu_op = IRV_ALU_SLL;  // SLLI
                    3'b010: alu_op = IRV_ALU_SLT;  // SLTI
                    3'b011: alu_op = IRV_ALU_SLTU; // SLTIU
                    3'b100: alu_op = IRV_ALU_XOR;  // XORI
                    3'b101: begin
                        if (funct7 == 7'b0100000) begin
                            alu_op = IRV_ALU_SRA;  // SRAI
                        end else begin
                            alu_op = IRV_ALU_SRL;  // SRLI
                        end
                    end
                    3'b110: alu_op = IRV_ALU_OR;   // ORI
                    3'b111: alu_op = IRV_ALU_AND;  // ANDI
                    default: alu_op = IRV_ALU_ADD;
                endcase
            end

            // BRANCH: use ALU compare paths for all branch conditions.
            7'b1100011: begin
                case (funct3)
                    3'b000,
                    3'b001: alu_op = IRV_ALU_SUB;  // BEQ / BNE
                    3'b100,
                    3'b101: alu_op = IRV_ALU_SLT;  // BLT / BGE
                    3'b110,
                    3'b111: alu_op = IRV_ALU_SLTU; // BLTU / BGEU
                    default: alu_op = IRV_ALU_SUB;
                endcase
            end

            // OP: ADD / SUB / SLL / SLT / SLTU / XOR / SRL / SRA / OR / AND
            7'b0110011: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000) begin
                            alu_op = IRV_ALU_SUB; // SUB
                        end else begin
                            alu_op = IRV_ALU_ADD; // ADD
                        end
                    end

                    3'b001: alu_op = IRV_ALU_SLL;  // SLL
                    3'b010: alu_op = IRV_ALU_SLT;  // SLT
                    3'b011: alu_op = IRV_ALU_SLTU; // SLTU
                    3'b100: alu_op = IRV_ALU_XOR;  // XOR
                    3'b101: begin
                        if (funct7 == 7'b0100000) begin
                            alu_op = IRV_ALU_SRA;  // SRA
                        end else begin
                            alu_op = IRV_ALU_SRL;  // SRL
                        end
                    end
                    3'b110: alu_op = IRV_ALU_OR;   // OR
                    3'b111: alu_op = IRV_ALU_AND;  // AND
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
        .a      (alu_a),
        .b      (alu_b),
        .y      (alu_y),
        .eq     (alu_eq_unused)
    );

    // ---------------------------------------------------------------------
    // Branch and PC control
    // ---------------------------------------------------------------------

    wire branch_eq;
    wire branch_lt;
    wire branch_taken;

    // Reuse ALU comparison outputs for branch decisions.
    assign branch_eq = alu_eq_unused;
    assign branch_lt = alu_y[0];

    assign branch_taken =
        (opcode == 7'b1100011) &&
        (
            ((funct3 == 3'b000) && branch_eq)  || // BEQ
            ((funct3 == 3'b001) && !branch_eq) || // BNE
            ((funct3 == 3'b100) && branch_lt)  || // BLT
            ((funct3 == 3'b101) && !branch_lt) || // BGE
            ((funct3 == 3'b110) && branch_lt)  || // BLTU
            ((funct3 == 3'b111) && !branch_lt)    // BGEU
        );

    wire [PC_WIDTH-1:0] pc_next;
    wire        pc_we;
    wire        pc_halt_req;

    wire [31:0] jalr_target;
    // Reuse ALU ADD path for JALR target instead of instantiating
    // an extra 32-bit adder: JALR target = rs1 + imm_i.
    assign jalr_target = alu_y;

    irv_pc_ctrl #(
        .PC_WIDTH    (PC_WIDTH)
    ) u_pc_ctrl (
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
    // Minimal interrupt / sleep control
    // ---------------------------------------------------------------------

    localparam [31:0] IRQ_VECTOR = 32'h0000_0040;

    wire irq_any;
    assign irq_any = |irq_pending;

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

    wire valid_load_funct3;
    wire valid_store_funct3;

    assign valid_load_funct3 =
        (funct3 == 3'b000) || // LB
        (funct3 == 3'b001) || // LH
        (funct3 == 3'b010) || // LW
        (funct3 == 3'b100) || // LBU
        (funct3 == 3'b101);   // LHU

    assign valid_store_funct3 =
        (funct3 == 3'b000) || // SB
        (funct3 == 3'b001) || // SH
        (funct3 == 3'b010);   // SW

    assign periph_store_en = (state == S_EXEC) &&
                             (opcode == 7'b0100011) &&
                             valid_store_funct3;

    assign periph_load_en  = (state == S_EXEC) &&
                             (opcode == 7'b0000011) &&
                             valid_load_funct3;

    // ULP/area optimization:
    // Reuse the ALU ADD path for load/store MMIO address generation.
    // For LOAD, alu_b = imm_i. For STORE, alu_b = imm_s.
    assign periph_addr  = alu_y;

    // Current MMIO peripherals consume the low byte. Keeping the full rs2 value
    // allows SB/SH/SW to share the same bus path without extra byte-lane logic.
    assign periph_wdata = rs2_val;

    // ---------------------------------------------------------------------
    // Load data formatting
    // ---------------------------------------------------------------------
    //
    // The current SoC exposes MMIO registers through a 32-bit read bus.
    // Byte/halfword loads select the requested lane from periph_rdata and
    // apply RV32I sign/zero extension rules.
    //
    // Misaligned accesses are not trapped in this minimal core.

    wire [7:0]  load_byte;
    wire [15:0] load_half;
    reg  [31:0] load_rdata;

    assign load_byte =
        (periph_addr[1:0] == 2'b00) ? periph_rdata[7:0]   :
        (periph_addr[1:0] == 2'b01) ? periph_rdata[15:8]  :
        (periph_addr[1:0] == 2'b10) ? periph_rdata[23:16] :
                                      periph_rdata[31:24];

    assign load_half = periph_addr[1] ? periph_rdata[31:16] :
                                        periph_rdata[15:0];

    always @(*) begin
        case (funct3)
            3'b000: load_rdata = {{24{load_byte[7]}}, load_byte};   // LB
            3'b001: load_rdata = {{16{load_half[15]}}, load_half};  // LH
            3'b010: load_rdata = periph_rdata;                      // LW
            3'b100: load_rdata = {24'd0, load_byte};                // LBU
            3'b101: load_rdata = {16'd0, load_half};                // LHU
            default: load_rdata = 32'd0;
        endcase
    end

    // ---------------------------------------------------------------------
    // Register file writeback generation
    // ---------------------------------------------------------------------

    always @(*) begin
        rd_we    = 1'b0;
        rd_waddr = rd;
        rd_wdata = 32'd0;

        // IRQ wake return address.
        // When the core wakes from WFI, store PC+4 in x1.
        // The IRQ handler can return with: JALR x0, x1, 0.
        if ((state == S_SLEEP) && irq_any) begin
            rd_we    = 1'b1;
            rd_waddr = 5'd1;
            rd_wdata = pc_ext + 32'd4;
        end else if ((state == S_EXEC) &&
            !is_ebreak &&
            !is_wfi &&
            !periph_stall) begin

            case (opcode)

                // LUI
                7'b0110111: begin
                    if (rd != 5'd0) begin
                        rd_we    = 1'b1;
                        rd_wdata = imm_u;
                    end
                end

                // AUIPC: rd = PC + imm_u.
                // Reuses the main ALU ADD path.
                7'b0010111: begin
                    if (rd != 5'd0) begin
                        rd_we    = 1'b1;
                        rd_wdata = alu_y;
                    end
                end

                // OP-IMM: ADDI / SLLI / SLTI / SLTIU / XORI / SRLI / SRAI / ORI / ANDI
                7'b0010011: begin
                    if ((rd != 5'd0) &&
                        (
                         (funct3 == 3'b000) ||
                         ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
                         (funct3 == 3'b010) ||
                         (funct3 == 3'b011) ||
                         (funct3 == 3'b100) ||
                         ((funct3 == 3'b101) &&
                          ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
                         (funct3 == 3'b110) ||
                         (funct3 == 3'b111))) begin
                        rd_we    = 1'b1;
                        rd_wdata = alu_y;
                    end
                end

                // OP: ADD / SUB / SLL / SLT / SLTU / XOR / SRL / SRA / OR / AND
                7'b0110011: begin
                    if ((rd != 5'd0) &&
                        (
                            ((funct3 == 3'b000) &&
                             ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) || // ADD/SUB
                            ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||       // SLL
                            ((funct3 == 3'b010) && (funct7 == 7'b0000000)) ||       // SLT
                            ((funct3 == 3'b011) && (funct7 == 7'b0000000)) ||       // SLTU
                            ((funct3 == 3'b100) && (funct7 == 7'b0000000)) ||       // XOR
                            ((funct3 == 3'b101) &&
                             ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) || // SRL/SRA
                            ((funct3 == 3'b110) && (funct7 == 7'b0000000)) ||       // OR
                            ((funct3 == 3'b111) && (funct7 == 7'b0000000))          // AND
                        )) begin
                        rd_we    = 1'b1;
                        rd_wdata = alu_y;
                    end
                end

                // LOAD: LB / LH / LW / LBU / LHU
                7'b0000011: begin
                    if (valid_load_funct3 && (rd != 5'd0)) begin
                        rd_we    = 1'b1;
                        rd_wdata = load_rdata;
                    end
                end

                // JAL
                7'b1101111: begin
                    if (rd != 5'd0) begin
                        rd_we    = 1'b1;
                        rd_wdata = pc_ext + 32'd4;
                    end
                end

                // JALR
                7'b1100111: begin
                    if ((funct3 == 3'b000) && (rd != 5'd0)) begin
                        rd_we    = 1'b1;
                        rd_wdata = pc_ext + 32'd4;
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
            pc       <= {PC_WIDTH{1'b0}};
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
                    end else if (is_wfi) begin
                        // WFI enters low-activity sleep state.
                        // The PC is not advanced. On IRQ wake, PC jumps to IRQ_VECTOR.
                        state <= S_SLEEP;
                    end else if (!pc_we) begin
                        // Wait here until the selected peripheral is ready.
                        // PC is not advanced, so the same instruction is retried.
                        state <= S_EXEC;
                    end else begin
                        pc    <= pc_next;
                        state <= S_ADDR_LO;
                    end
                end

                S_SLEEP: begin
                    if (irq_any) begin
                        pc    <= IRQ_VECTOR[PC_WIDTH-1:0];
                        state <= S_ADDR_LO;
                    end else begin
                        state <= S_SLEEP;
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
