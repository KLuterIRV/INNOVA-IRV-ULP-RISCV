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
    // Phase 1 minimal RV32E demo core + unified 64x16 SRAM
    // ============================================================
    //
    // Physical SRAM:
    //   u_mem_b0: low byte  [7:0]
    //   u_mem_b1: high byte [15:8]
    //
    // Logical SRAM:
    //   64 x 16-bit halfwords = 128 bytes
    //
    // Instruction memory capacity:
    //   32 RV32 instructions maximum.
    //
    // Supported instructions for phase 1:
    //   ADDI
    //   LUI
    //   SW to memory-mapped GPIO at 0x1000_0000
    //   EBREAK
    //
    // Test program:
    //   addi x1, x0, 0x55
    //   lui  x2, 0x10000
    //   sw   x1, 0(x2)
    //   ebreak
    //
    // Expected:
    //   uo_out = 0x55
    //
    // Boot/programming mode:
    //   Hold rst_n = 0.
    //   ui_in[0]   = write enable
    //   ui_in[7:1] = byte address 0..127
    //   uio_in     = byte write data
    //
    // Run mode:
    //   Release rst_n = 1.
    //   Core starts at PC = 0.

    wire rst;
    assign rst = ~rst_n;

    // ============================================================
    // Boot/programming interface
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

    // Phase-1 minimal register file:
    // Only x1 and x2 are physically implemented.
    // x0 is hardwired to zero.
    //
    // This avoids the large 16x32 DFF register file that made
    // the previous core too large for 4x2 with 2 SRAM macros.
    reg [31:0] x1;
    reg [31:0] x2;

    // ============================================================
    // Instruction decode
    // ============================================================

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;

    assign opcode = instr_reg[6:0];
    assign rd     = instr_reg[11:7];
    assign funct3 = instr_reg[14:12];
    assign rs1    = instr_reg[19:15];
    assign rs2    = instr_reg[24:20];

    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_u;

    assign imm_i = {{20{instr_reg[31]}}, instr_reg[31:20]};
    assign imm_s = {{20{instr_reg[31]}}, instr_reg[31:25], instr_reg[11:7]};
    assign imm_u = {instr_reg[31:12], 12'd0};

    wire [31:0] rs1_val;
    wire [31:0] rs2_val;

    assign rs1_val =
        (rs1 == 5'd1) ? x1 :
        (rs1 == 5'd2) ? x2 :
                         32'd0;

    assign rs2_val =
        (rs2 == 5'd1) ? x1 :
        (rs2 == 5'd2) ? x2 :
                         32'd0;

    wire is_ebreak;
    assign is_ebreak = (instr_reg == 32'h0010_0073);

    // ============================================================
    // SRAM address mux
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

    // GF180 SRAM control pins are active-low.
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
    // Minimal execution engine
    // ============================================================

    always @(posedge clk) begin
        if (rst || !ena) begin
            pc        <= 32'd0;
            state     <= S_ADDR_LO;
            instr_lo  <= 16'd0;
            instr_reg <= 32'd0;
            halted    <= 1'b0;
            out_reg   <= 8'd0;
            x1        <= 32'd0;
            x2        <= 32'd0;
        end else begin
            if (!halted) begin
                case (state)
                    // Present low halfword address to SRAM.
                    S_ADDR_LO: begin
                        state <= S_CAP_LO;
                    end

                    // Capture low halfword and present high halfword address.
                    S_CAP_LO: begin
                        instr_lo <= mem_rdata16;
                        state    <= S_CAP_HI;
                    end

                    // Capture high halfword and build full instruction.
                    S_CAP_HI: begin
                        instr_reg <= {mem_rdata16, instr_lo};
                        state     <= S_EXEC;
                    end

                    // Execute minimal instruction subset.
                    S_EXEC: begin
                        if (is_ebreak) begin
                            halted <= 1'b1;
                            pc     <= pc;
                        end else begin
                            case (opcode)
                                // LUI
                                7'b0110111: begin
                                    if (rd == 5'd1) begin
                                        x1 <= imm_u;
                                    end else if (rd == 5'd2) begin
                                        x2 <= imm_u;
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // OP-IMM: only ADDI in phase 1
                                7'b0010011: begin
                                    if (funct3 == 3'b000) begin
                                        if (rd == 5'd1) begin
                                            x1 <= rs1_val + imm_i;
                                        end else if (rd == 5'd2) begin
                                            x2 <= rs1_val + imm_i;
                                        end
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // STORE: only SW to memory-mapped GPIO
                                // Address 0x1000_0000 -> out_reg[7:0]
                                7'b0100011: begin
                                    if (funct3 == 3'b010) begin
                                        if ((rs1_val + imm_s) == 32'h1000_0000) begin
                                            out_reg <= rs2_val[7:0];
                                        end
                                    end
                                    pc <= pc + 32'd4;
                                end

                                // Unsupported instruction = NOP
                                default: begin
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
