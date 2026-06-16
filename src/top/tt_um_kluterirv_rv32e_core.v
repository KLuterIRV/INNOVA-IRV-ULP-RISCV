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

    reg       halted;

    // GPIO0 peripheral interface.
    wire       gpio0_we;
    wire [7:0] gpio0_wdata;
    wire [7:0] gpio0_out;

    // Register file writeback interface.
    reg        rd_we;
    reg [4:0]  rd_waddr;
    reg [31:0] rd_wdata;

    // ---------------------------------------------------------------------
    // Decode helpers
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
        .is_ebreak (is_ebreak)
    );

    // Some decoded fields are reserved for the next core steps.
    // They are intentionally exposed now to make R-type and interrupt work
    // easier to add later.
    wire unused_decoder_fields;
    assign unused_decoder_fields = is_lui | is_op_imm | is_op | is_load |
                                   is_store | is_branch | is_jal | (|funct7);

    wire [31:0] rs1_val;
    wire [31:0] rs2_val;

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
    //
    // The ALU is currently used for OP-IMM instructions:
    //   ADDI, XORI, ORI, ANDI.
    //
    // In the next step it will also be used for R-type operations:
    //   ADD, SUB, AND, OR, XOR.

    localparam [3:0]
        IRV_ALU_ADD = 4'd0,
        IRV_ALU_AND = 4'd2,
        IRV_ALU_OR  = 4'd3,
        IRV_ALU_XOR = 4'd4;

    reg  [3:0]  alu_op;
    wire [31:0] alu_y;
    wire        alu_eq_unused;

    always @(*) begin
        case (funct3)
            3'b000: alu_op = IRV_ALU_ADD; // ADDI
            3'b100: alu_op = IRV_ALU_XOR; // XORI
            3'b110: alu_op = IRV_ALU_OR;  // ORI
            3'b111: alu_op = IRV_ALU_AND; // ANDI
            default: alu_op = IRV_ALU_ADD;
        endcase
    end

    irv_alu u_alu (
        .alu_op (alu_op),
        .a      (rs1_val),
        .b      (imm_i),
        .y      (alu_y),
        .eq     (alu_eq_unused)
    );

    // Reserved for future branch/compare integration.
    wire unused_alu_eq_sink;
    assign unused_alu_eq_sink = alu_eq_unused;

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
    // GPIO0 peripheral
    // ---------------------------------------------------------------------
    //
    // Memory map:
    //   0x1000_0000 -> GPIO0 output register

    gpio0 u_gpio0 (
        .clk      (clk),
        .rst      (rst),
        .we       (gpio0_we),
        .wdata    (gpio0_wdata),
        .gpio_out (gpio0_out)
    );

    // ---------------------------------------------------------------------
    // UART0 peripheral
    // ---------------------------------------------------------------------
    //
    // Current use:
    //   uio_out[0] -> UART0 TX
    //   uio_in[1]  -> UART0 RX
    //
    // Debug mode:
    //   ui_in[2] = 1 exposes UART0 RX data on uo_out.
    // This is only for verification until the core has a clean LW path.

    wire [7:0] uart0_tx_data;
    wire       uart0_tx_start;
    wire       uart0_tx_busy;
    wire       uart0_tx;

    wire [7:0] uart0_rx_data;
    wire       uart0_rx_valid;
    wire       uart0_rx_clear;

    wire uart0_rx_debug_mode;
    assign uart0_rx_debug_mode = rst_n && ui_in[2];

    uart0 #(
        .CLKS_PER_BIT(8)
    ) u_uart0 (
        .clk      (clk),
        .rst      (rst),
        .tx_data  (uart0_tx_data),
        .tx_start (uart0_tx_start),
        .tx_busy  (uart0_tx_busy),
        .tx       (uart0_tx),
        .rx       (uio_in[1]),
        .rx_clear (uart0_rx_clear),
        .rx_data  (uart0_rx_data),
        .rx_valid (uart0_rx_valid)
    );

    // ---------------------------------------------------------------------
    // I2C0 minimal open-drain peripheral
    // ---------------------------------------------------------------------
    //
    // Memory map:
    //   0x1000_0010 -> I2C0 control
    //                  bit 0 = drive SCL low
    //                  bit 1 = drive SDA low
    //   0x1000_0018 -> I2C0 status
    //                  bit 0 = SCL input
    //                  bit 1 = SDA input
    //                  bit 2 = SCL drive-low state
    //                  bit 3 = SDA drive-low state

    wire [7:0] i2c0_ctrl_wr_data;
    wire       i2c0_ctrl_we;

    wire [7:0] i2c0_data_wr_data;
    wire       i2c0_data_we;
    wire [7:0] i2c0_data_rd_data;

    wire [7:0] i2c0_div_wr_data;
    wire       i2c0_div_we;

    wire [7:0] i2c0_status;

    wire i2c0_scl_out;
    wire i2c0_scl_oe;
    wire i2c0_sda_out;
    wire i2c0_sda_oe;

    i2c0 u_i2c0 (
        .clk          (clk),
        .rst          (rst),

        .ctrl_wr_data (i2c0_ctrl_wr_data),
        .ctrl_we      (i2c0_ctrl_we),

        .data_wr_data (i2c0_data_wr_data),
        .data_we      (i2c0_data_we),
        .data_rd_data (i2c0_data_rd_data),

        .div_wr_data  (i2c0_div_wr_data),
        .div_we       (i2c0_div_we),

        .status       (i2c0_status),

        .scl_in       (uio_in[2]),
        .sda_in       (uio_in[3]),

        .scl_out      (i2c0_scl_out),
        .scl_oe       (i2c0_scl_oe),

        .sda_out      (i2c0_sda_out),
        .sda_oe       (i2c0_sda_oe)
    );

    // ---------------------------------------------------------------------
    // Peripheral bus / MMIO handler
    // ---------------------------------------------------------------------

    wire [31:0] periph_store_addr;
    wire [31:0] periph_load_addr;
    wire [31:0] periph_addr;
    wire        periph_store_en;
    wire        periph_load_en;
    wire [31:0] periph_rdata;
    wire        peripheral_store_stall;

    assign periph_store_addr = rs1_val + imm_s;
    assign periph_load_addr  = rs1_val + imm_i;

    assign periph_store_en = (state == S_EXEC) &&
                             (opcode == 7'b0100011) &&
                             (funct3 == 3'b010);

    assign periph_load_en  = (state == S_EXEC) &&
                             (opcode == 7'b0000011) &&
                             (funct3 == 3'b010);

    assign periph_addr = periph_store_en ? periph_store_addr : periph_load_addr;

    irv_peripheral_bus u_peripheral_bus (
        .load_en             (periph_load_en),
        .store_en            (periph_store_en),
        .addr                (periph_addr),
        .wdata               (rs2_val),

        .rdata               (periph_rdata),
        .stall               (peripheral_store_stall),

        .gpio0_we            (gpio0_we),
        .gpio0_wdata         (gpio0_wdata),

        .uart0_tx_busy       (uart0_tx_busy),
        .uart0_rx_valid      (uart0_rx_valid),
        .uart0_rx_data       (uart0_rx_data),
        .uart0_tx_data       (uart0_tx_data),
        .uart0_tx_start      (uart0_tx_start),
        .uart0_rx_clear      (uart0_rx_clear),

        .i2c0_status         (i2c0_status),
        .i2c0_data_rd_data   (i2c0_data_rd_data),

        .i2c0_ctrl_wr_data   (i2c0_ctrl_wr_data),
        .i2c0_ctrl_we        (i2c0_ctrl_we),

        .i2c0_data_wr_data   (i2c0_data_wr_data),
        .i2c0_data_we        (i2c0_data_we),

        .i2c0_div_wr_data    (i2c0_div_wr_data),
        .i2c0_div_we         (i2c0_div_we)
    );

    // ---------------------------------------------------------------------
    // Register file writeback generation
    // ---------------------------------------------------------------------
    //
    // Writeback is generated combinationally from the current instruction.
    // The regfile captures rd_wdata on the same clock edge used by S_EXEC.
    //
    // This avoids one-cycle-late writes and keeps the execute FSM simple.

    always @(*) begin
        rd_we    = 1'b0;
        rd_waddr = rd;
        rd_wdata = 32'd0;

        if ((state == S_EXEC) &&
            (instr_reg != 32'h0010_0073) &&
            !peripheral_store_stall) begin

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

                default: begin
                    rd_we    = 1'b0;
                    rd_wdata = 32'd0;
                end

            endcase
        end
    end

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
            halted          <= 1'b0;

        end else begin
            // Default pulse value for UART0 TX.

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
                    if (is_ebreak) begin
                        halted <= 1'b1;
                        state  <= S_HALT;
                    end else if (peripheral_store_stall) begin
                        // Wait here until the selected peripheral is ready.
                        // PC is not advanced, so the same SW instruction is retried.
                        state <= S_EXEC;
                    end else begin

                        case (opcode)

                            // LUI
                            7'b0110111: begin
                                pc <= pc + 32'd4;
                            end

                            // OP-IMM: ADDI / XORI / ORI / ANDI
                            7'b0010011: begin
                                pc <= pc + 32'd4;
                            end

                            // LOAD: minimal memory-mapped peripheral reads
                            7'b0000011: begin
                                pc <= pc + 32'd4;
                            end

                            // STORE: memory-mapped peripheral writes
                            7'b0100011: begin
                                pc <= pc + 32'd4;
                            end

                            // JAL: jump and link
                            7'b1101111: begin
                                pc <= pc + imm_j;
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

    assign uo_out = ena
        ? (uart0_rx_debug_mode ? (uart0_rx_valid ? uart0_rx_data : 8'd0)
           : (boot_mode ? boot_debug_byte : gpio0_out))
        : 8'd0;

    assign uio_out = {4'd0, i2c0_sda_out, i2c0_scl_out, 1'b0, uart0_tx};
    assign uio_oe  = {4'd0, i2c0_sda_oe,  i2c0_scl_oe,  1'b0, 1'b1};

endmodule

`default_nettype wire
