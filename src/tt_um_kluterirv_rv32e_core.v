`default_nettype none

module tt_um_kluterirv_rv32e_core (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // Unified 64x16 SRAM + minimal RV32E core
    // ============================================================
    //
    // Physical SRAM:
    //   u_mem_b0: low byte  [7:0]
    //   u_mem_b1: high byte [15:8]
    //
    // Logical SRAM:
    //   64 x 16-bit halfwords = 128 bytes
    //
    // RV32 instruction fetch:
    //   each 32-bit instruction is fetched in two 16-bit reads:
    //     PC[6:1]     -> instr[15:0]
    //     PC[6:1] + 1 -> instr[31:16]
    //
    // Boot/programming mode:
    //   Hold rst_n = 0.
    //   ui_in[0]   = write enable
    //   ui_in[7:1] = byte address
    //   uio_in     = byte write data
    //
    // Run mode:
    //   Release rst_n = 1.
    //   Core starts at PC = 0.
    //
    // Output:
    //   uo_out = GPIO/debug output register in run mode.
    //   uo_out = selected SRAM byte in reset/programming mode.

    wire rst;
    assign rst = ~rst_n;

    // ============================================================
    // SRAM boot/write interface
    // ============================================================

    wire        boot_mode;
    wire        boot_we;
    wire [6:0]  boot_byte_addr;
    wire [5:0]  boot_half_addr;
    wire        boot_byte_sel;
    wire [7:0]  boot_wbyte;

    assign boot_mode      = rst;
    assign boot_we        = ui_in[0];
    assign boot_byte_addr = ui_in[7:1];
    assign boot_half_addr = boot_byte_addr[6:1];
    assign boot_byte_sel  = boot_byte_addr[0];
    assign boot_wbyte     = uio_in;

    // ============================================================
    // Minimal core state
    // ============================================================

    localparam [1:0] S_ADDR_LO = 2'd0;
    localparam [1:0] S_CAP_LO  = 2'd1;
    localparam [1:0] S_CAP_HI  = 2'd2;
    localparam [1:0] S_EXEC    = 2'd3;

    reg [1:0]  state;
    reg [31:0] pc;
    reg [15:0] instr_lo;
    reg [31:0] instr_reg;
    reg        halted;
    reg [7:0]  out_reg;

    // RV32E register file: x0..x15
    reg [31:0] rf [0:15];

    integer i;

    // ============================================================
    // Decode fields
    // ============================================================

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [3:0] rs1;
    wire [3:0] rs2;
    wire [3:0] rd;

    assign opcode = instr_reg[6:0];
    assign funct3 = instr_reg[14:12];
    assign funct7 = instr_reg[31:25];
    assign rd     = instr_reg[10:7];
    assign rs1    = instr_reg[18:15];
    assign rs2    = instr_reg[23:20];

    wire [31:0] rv1;
    wire [31:0] rv2;

    assign rv1 = (rs1 == 4'd0) ? 32'd0 : rf[rs1];
    assign rv2 = (rs2 == 4'd0) ? 32'd0 : rf[rs2];

    // Immediates
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_b;
    wire [31:0] imm_u;
    wire [31:0] imm_j;

    assign imm_i = {{20{instr_reg[31]}}, instr_reg[31:20]};
    assign imm_s = {{20{instr_reg[31]}}, instr_reg[31:25], instr_reg[11:7]};
    assign imm_b = {{19{instr_reg[31]}}, instr_reg[31], instr_reg[7],
                    instr_reg[30:25], instr_reg[11:8], 1'b0};
    assign imm_u = {instr_reg[31:12], 12'd0};
    assign imm_j = {{11{instr_reg[31]}}, instr_reg[31], instr_reg[19:12],
                    instr_reg[20], instr_reg[30:21], 1'b0};

    wire is_ebreak;
    assign is_ebreak = (instr_reg == 32'h00100073);

    // ============================================================
    // SRAM access mux
    // ============================================================

    wire [5:0] pc_half_addr;
    wire [5:0] pc_half_addr_hi;

    assign pc_half_addr    = pc[6:1];
    assign pc_half_addr_hi = pc[6:1] + 6'd1;

    wire [5:0] core_mem_addr;

    assign core_mem_addr =
        (state == S_ADDR_LO) ? pc_half_addr :
        (state == S_CAP_LO)  ? pc_half_addr_hi :
        (state == S_CAP_HI)  ? pc_half_addr_hi :
                               pc_half_addr;

    wire [5:0] sram_addr;
    assign sram_addr = boot_mode ? boot_half_addr : core_mem_addr;

    wire [7:0] q0;
    wire [7:0] q1;

    wire [15:0] mem_rdata16;
    assign mem_rdata16 = {q1, q0};

    wire [7:0] selected_boot_rbyte;
    assign selected_boot_rbyte = boot_byte_sel ? q1 : q0;

    // Active-low SRAM controls
    wire cen;
    assign cen = 1'b0;

    wire we_b0;
    wire we_b1;

    assign we_b0 = boot_mode && boot_we && (boot_byte_sel == 1'b0);
    assign we_b1 = boot_mode && boot_we && (boot_byte_sel == 1'b1);

    wire gwen_b0;
    wire gwen_b1;

    assign gwen_b0 = ~we_b0;
    assign gwen_b1 = ~we_b1;

    wire [7:0] wen_b0;
    wire [7:0] wen_b1;

    assign wen_b0 = we_b0 ? 8'h00 : 8'hFF;
    assign wen_b1 = we_b1 ? 8'h00 : 8'hFF;

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b0 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b0),
        .WEN  (wen_b0),
        .A    (sram_addr),
        .D    (boot_wbyte),
        .Q    (q0)
    );

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b1 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b1),
        .WEN  (wen_b1),
        .A    (sram_addr),
        .D    (boot_wbyte),
        .Q    (q1)
    );

    // ============================================================
    // Core execution
    // ============================================================

    always @(posedge clk) begin
        if (rst || !ena) begin
            pc        <= 32'd0;
            state     <= S_ADDR_LO;
            instr_lo  <= 16'd0;
            instr_reg <= 32'd0;
            halted    <= 1'b0;
            out_reg   <= 8'd0;

            for (i = 0; i < 16; i = i + 1) begin
                rf[i] <= 32'd0;
            end
        end else begin
            // x0 is always zero
            rf[0] <= 32'd0;

            if (!halted) begin
                case (state)
                    S_ADDR_LO: begin
                        state <= S_CAP_LO;
                    end

                    S_CAP_LO: begin
                        instr_lo <= mem_rdata16;
                        state    <= S_CAP_HI;
                    end

                    S_CAP_HI: begin
                        instr_reg <= {mem_rdata16, instr_lo};
                        state     <= S_EXEC;
                    end

                    S_EXEC: begin
                        if (is_ebreak) begin
                            halted <= 1'b1;
                            pc     <= pc;
                        end else begin
                            case (opcode)
                                // LUI
                                7'b0110111: begin
                                    if (rd != 4'd0) begin
                                        rf[rd] <= imm_u;
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // AUIPC
                                7'b0010111: begin
                                    if (rd != 4'd0) begin
                                        rf[rd] <= pc + imm_u;
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // JAL
                                7'b1101111: begin
                                    if (rd != 4'd0) begin
                                        rf[rd] <= pc + 32'd4;
                                    end
                                    pc <= pc + imm_j;
                                end

                                // JALR
                                7'b1100111: begin
                                    if (rd != 4'd0) begin
                                        rf[rd] <= pc + 32'd4;
                                    end
                                    pc <= (rv1 + imm_i) & 32'hFFFF_FFFE;
                                end

                                // BRANCH: BEQ/BNE/BLT/BGE/BLTU/BGEU
                                7'b1100011: begin
                                    case (funct3)
                                        3'b000: pc <= (rv1 == rv2) ? pc + imm_b : pc + 32'd4;
                                        3'b001: pc <= (rv1 != rv2) ? pc + imm_b : pc + 32'd4;
                                        3'b100: pc <= ($signed(rv1) < $signed(rv2)) ? pc + imm_b : pc + 32'd4;
                                        3'b101: pc <= ($signed(rv1) >= $signed(rv2)) ? pc + imm_b : pc + 32'd4;
                                        3'b110: pc <= (rv1 < rv2) ? pc + imm_b : pc + 32'd4;
                                        3'b111: pc <= (rv1 >= rv2) ? pc + imm_b : pc + 32'd4;
                                        default: pc <= pc + 32'd4;
                                    endcase
                                end

                                // OP-IMM
                                7'b0010011: begin
                                    if (rd != 4'd0) begin
                                        case (funct3)
                                            3'b000: rf[rd] <= rv1 + imm_i;                         // ADDI
                                            3'b100: rf[rd] <= rv1 ^ imm_i;                         // XORI
                                            3'b110: rf[rd] <= rv1 | imm_i;                         // ORI
                                            3'b111: rf[rd] <= rv1 & imm_i;                         // ANDI
                                            3'b001: rf[rd] <= rv1 << instr_reg[24:20];             // SLLI
                                            3'b101: begin
                                                if (instr_reg[30]) begin
                                                    rf[rd] <= $signed(rv1) >>> instr_reg[24:20];   // SRAI
                                                end else begin
                                                    rf[rd] <= rv1 >> instr_reg[24:20];             // SRLI
                                                end
                                            end
                                            default: rf[rd] <= 32'd0;
                                        endcase
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // OP
                                7'b0110011: begin
                                    if (rd != 4'd0) begin
                                        case (funct3)
                                            3'b000: begin
                                                if (funct7[5]) begin
                                                    rf[rd] <= rv1 - rv2;                           // SUB
                                                end else begin
                                                    rf[rd] <= rv1 + rv2;                           // ADD
                                                end
                                            end
                                            3'b100: rf[rd] <= rv1 ^ rv2;                           // XOR
                                            3'b110: rf[rd] <= rv1 | rv2;                           // OR
                                            3'b111: rf[rd] <= rv1 & rv2;                           // AND
                                            3'b001: rf[rd] <= rv1 << rv2[4:0];                     // SLL
                                            3'b101: begin
                                                if (funct7[5]) begin
                                                    rf[rd] <= $signed(rv1) >>> rv2[4:0];           // SRA
                                                end else begin
                                                    rf[rd] <= rv1 >> rv2[4:0];                     // SRL
                                                end
                                            end
                                            default: rf[rd] <= 32'd0;
                                        endcase
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // STORE
                                // Minimal memory-mapped peripheral:
                                //   0x1000_0000 -> out_reg[7:0]
                                7'b0100011: begin
                                    if ((rv1 + imm_s) == 32'h1000_0000) begin
                                        out_reg <= rv2[7:0];
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // LOAD
                                // Minimal implementation:
                                //   reads 0x1000_0000 as zero-extended out_reg.
                                7'b0000011: begin
                                    if (rd != 4'd0) begin
                                        if ((rv1 + imm_i) == 32'h1000_0000) begin
                                            rf[rd] <= {24'd0, out_reg};
                                        end else begin
                                            rf[rd] <= 32'd0;
                                        end
                                    end
                                    pc <= pc + 32'd4;
                                end

                                default: begin
                                    // Unsupported instruction = NOP
                                    pc <= pc + 32'd4;
                                end
                            endcase
                        end

                        state <= S_ADDR_LO;
                    end

                    default: begin
                        state <= S_ADDR_LO;
                    end
                endcase
            end
        end
    end

    // ============================================================
    // TinyTapeout outputs
    // ============================================================

    assign uo_out = boot_mode ? selected_boot_rbyte : out_reg;

    assign uio_out = 8'd0;
    assign uio_oe  = 8'd0;

    wire _unused;
    assign _unused = &{
        ui_in,
        uio_in,
        instr_reg,
        pc,
        state,
        halted,
        1'b0
    };

endmodule

`default_nettype wire
