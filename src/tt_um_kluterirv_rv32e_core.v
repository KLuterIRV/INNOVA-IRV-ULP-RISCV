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

    // ---------------------------------------------------------------------
    // Reset / boot mode
    // ---------------------------------------------------------------------

    wire rst;
    assign rst = ~rst_n;

    wire boot_mode;
    assign boot_mode = rst;

    // Boot/programming interface while rst_n = 0:
    //   ui_in[0]   = write enable
    //   ui_in[7:1] = byte address 0..127
    //   uio_in     = byte data
    wire        boot_we;
    wire [6:0]  boot_byte_addr;
    wire [5:0]  boot_half_addr;
    wire        boot_byte_sel;

    assign boot_we        = ui_in[0];
    assign boot_byte_addr = ui_in[7:1];
    assign boot_half_addr = boot_byte_addr[6:1];
    assign boot_byte_sel  = boot_byte_addr[0];

    // ---------------------------------------------------------------------
    // CPU state
    // ---------------------------------------------------------------------

    localparam [2:0]
        S_ADDR_LO = 3'd0,
        S_CAP_LO  = 3'd1,
        S_CAP_HI  = 3'd2,
        S_EXEC    = 3'd3,
        S_HALT    = 3'd4;

    reg [2:0] state;

    reg [31:0] pc;
    reg [15:0] instr_lo;
    reg [31:0] instr_reg;

    reg [7:0] out_reg;
    reg       halted;

    // Minimal physical registers.
    reg [31:0] x1;
    reg [31:0] x2;
    reg [31:0] x3;
    reg [31:0] x4;

    // ---------------------------------------------------------------------
    // Decode helpers
    // ---------------------------------------------------------------------

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
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
    wire [31:0] imm_b;

    assign imm_i = {{20{instr_reg[31]}}, instr_reg[31:20]};
    assign imm_s = {{20{instr_reg[31]}}, instr_reg[31:25], instr_reg[11:7]};
    assign imm_u = {instr_reg[31:12], 12'b0};

    // B-type immediate:
    // imm[12|10:5|4:1|11|0] = instr[31|30:25|11:8|7|0]
    assign imm_b = {
        {19{instr_reg[31]}},
        instr_reg[31],
        instr_reg[7],
        instr_reg[30:25],
        instr_reg[11:8],
        1'b0
    };

    function [31:0] read_reg;
        input [4:0] r;
        begin
            case (r)
                5'd0: read_reg = 32'd0;
                5'd1: read_reg = x1;
                5'd2: read_reg = x2;
                5'd3: read_reg = x3;
                5'd4: read_reg = x4;
                default: read_reg = 32'd0;
            endcase
        end
    endfunction

    wire [31:0] rs1_val;
    wire [31:0] rs2_val;

    assign rs1_val = read_reg(rs1);
    assign rs2_val = read_reg(rs2);

    wire branch_eq;
    wire branch_taken;

    assign branch_eq = (rs1_val == rs2_val);

    assign branch_taken =
        (opcode == 7'b1100011) &&
        (
            ((funct3 == 3'b000) && branch_eq)  || // BEQ
            ((funct3 == 3'b001) && !branch_eq)    // BNE
        );

    // ---------------------------------------------------------------------
    // Unified 64x16 SRAM memory
    // ---------------------------------------------------------------------

    wire [5:0] pc_half_addr;
    wire [5:0] pc_half_addr_hi;

    assign pc_half_addr    = pc[6:1];
    assign pc_half_addr_hi = pc[6:1] + 6'd1;

    reg [5:0] run_sram_addr;

    always @(*) begin
        case (state)
            S_ADDR_LO: run_sram_addr = pc_half_addr;
            S_CAP_LO:  run_sram_addr = pc_half_addr_hi;
            default:   run_sram_addr = pc_half_addr;
        endcase
    end

    wire [5:0] sram_addr;
    assign sram_addr = boot_mode ? boot_half_addr : run_sram_addr;

    wire        cen;
    wire        we_b0;
    wire        we_b1;
    wire        gwen_b0;
    wire        gwen_b1;
    wire [7:0]  wen_b0;
    wire [7:0]  wen_b1;

    assign cen = 1'b0;

    assign we_b0 = boot_mode && boot_we && (boot_byte_sel == 1'b0);
    assign we_b1 = boot_mode && boot_we && (boot_byte_sel == 1'b1);

    assign gwen_b0 = ~we_b0;
    assign gwen_b1 = ~we_b1;

    assign wen_b0 = we_b0 ? 8'h00 : 8'hFF;
    assign wen_b1 = we_b1 ? 8'h00 : 8'hFF;

    wire [7:0] q0;
    wire [7:0] q1;

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b0 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b0),
        .WEN  (wen_b0),
        .A    (sram_addr),
        .D    (uio_in),
        .Q    (q0)
    );

    gf180mcu_fd_ip_sram__sram64x8m8wm1 u_mem_b1 (
        .CLK  (clk),
        .CEN  (cen),
        .GWEN (gwen_b1),
        .WEN  (wen_b1),
        .A    (sram_addr),
        .D    (uio_in),
        .Q    (q1)
    );

    wire [15:0] sram_rhalf;
    assign sram_rhalf = {q1, q0};

    // ---------------------------------------------------------------------
    // CPU FSM
    // ---------------------------------------------------------------------

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_ADDR_LO;
            pc        <= 32'd0;
            instr_lo  <= 16'd0;
            instr_reg <= 32'd0;
            out_reg   <= 8'd0;
            halted    <= 1'b0;
            x1        <= 32'd0;
            x2        <= 32'd0;
            x3        <= 32'd0;
            x4        <= 32'd0;
        end else begin
            case (state)

                S_ADDR_LO: begin
                    if (halted) begin
                        state <= S_HALT;
                    end else begin
                        state <= S_CAP_LO;
                    end
                end

                S_CAP_LO: begin
                    instr_lo <= sram_rhalf;
                    state    <= S_CAP_HI;
                end

                S_CAP_HI: begin
                    instr_reg <= {sram_rhalf, instr_lo};
                    state     <= S_EXEC;
                end

                S_EXEC: begin
                    if (instr_reg == 32'h0010_0073) begin
                        halted <= 1'b1;
                        state  <= S_HALT;
                    end else begin

                        case (opcode)

                            // LUI
                            7'b0110111: begin
                                pc <= pc + 32'd4;

                                case (rd)
                                    5'd1: x1 <= imm_u;
                                    5'd2: x2 <= imm_u;
                                    5'd3: x3 <= imm_u;
                                    5'd4: x4 <= imm_u;
                                    default: begin end
                                endcase
                            end

                            // OP-IMM: ADDI only
                            7'b0010011: begin
                                pc <= pc + 32'd4;

                                if (funct3 == 3'b000) begin
                                    case (rd)
                                        5'd1: x1 <= rs1_val + imm_i;
                                        5'd2: x2 <= rs1_val + imm_i;
                                        5'd3: x3 <= rs1_val + imm_i;
                                        5'd4: x4 <= rs1_val + imm_i;
                                        default: begin end
                                    endcase
                                end
                            end

                            // STORE: SW to memory-mapped GPIO only
                            7'b0100011: begin
                                pc <= pc + 32'd4;

                                if (funct3 == 3'b010) begin
                                    if ((rs1_val + imm_s) == 32'h1000_0000) begin
                                        out_reg <= rs2_val[7:0];
                                    end
                                end
                            end

                            // BRANCH: BEQ / BNE
                            7'b1100011: begin
                                if (branch_taken) begin
                                    pc <= pc + imm_b;
                                end else begin
                                    pc <= pc + 32'd4;
                                end
                            end

                            default: begin
                                // Unsupported instruction = NOP.
                                pc <= pc + 32'd4;
                            end

                        endcase

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

    // ---------------------------------------------------------------------
    // Tiny Tapeout outputs
    // ---------------------------------------------------------------------

    wire [7:0] boot_debug_byte;
    assign boot_debug_byte = boot_byte_sel ? q1 : q0;

    assign uo_out = ena ? (boot_mode ? boot_debug_byte : out_reg) : 8'd0;

    assign uio_out = 8'd0;
    assign uio_oe  = 8'd0;

endmodule

`default_nettype wire
