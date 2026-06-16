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

    // Register file writeback interface.
    reg        rd_we;
    reg [4:0]  rd_waddr;
    reg [31:0] rd_wdata;

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
    wire [31:0] imm_j;

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

    // J-type immediate for JAL:
    // imm[20|10:1|11|19:12|0] = instr[31|30:21|20|19:12|0]
    assign imm_j = {
        {11{instr_reg[31]}},
        instr_reg[31],
        instr_reg[19:12],
        instr_reg[20],
        instr_reg[30:21],
        1'b0
    };

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

    reg  [7:0] uart0_tx_data;
    reg        uart0_tx_start;
    wire       uart0_tx_busy;
    wire       uart0_tx;

    wire [7:0] uart0_rx_data;
    wire       uart0_rx_valid;
    reg        uart0_rx_clear;

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

    reg  [7:0] i2c0_ctrl_wr_data;
    reg        i2c0_ctrl_we;

    reg  [7:0] i2c0_data_wr_data;
    reg        i2c0_data_we;
    wire [7:0] i2c0_data_rd_data;

    reg  [7:0] i2c0_div_wr_data;
    reg        i2c0_div_we;

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
    // Peripheral automatic stall
    // ---------------------------------------------------------------------
    //
    // If the core writes to a slow peripheral while it is busy, the current
    // instruction is held in S_EXEC and PC is not advanced.

    wire [31:0] store_addr;
    wire        store_is_sw;
    wire        i2c0_busy;
    wire        peripheral_store_stall;

    assign store_addr  = rs1_val + imm_s;
    assign store_is_sw = (opcode == 7'b0100011) && (funct3 == 3'b010);
    assign i2c0_busy   = i2c0_status[0];

    assign peripheral_store_stall =
        store_is_sw &&
        (
            ((store_addr == 32'h1000_0004) && uart0_tx_busy) ||
            (((store_addr == 32'h1000_0010) ||
              (store_addr == 32'h1000_001C)) && i2c0_busy)
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
                    if (rd != 5'd0) begin
                        case (funct3)
                            3'b000: begin
                                rd_we    = 1'b1;
                                rd_wdata = rs1_val + imm_i;
                            end

                            3'b100: begin
                                rd_we    = 1'b1;
                                rd_wdata = rs1_val ^ imm_i;
                            end

                            3'b110: begin
                                rd_we    = 1'b1;
                                rd_wdata = rs1_val | imm_i;
                            end

                            3'b111: begin
                                rd_we    = 1'b1;
                                rd_wdata = rs1_val & imm_i;
                            end

                            default: begin
                                rd_we    = 1'b0;
                                rd_wdata = 32'd0;
                            end
                        endcase
                    end
                end

                // LOAD: minimal memory-mapped peripheral reads
                7'b0000011: begin
                    if ((funct3 == 3'b010) && (rd != 5'd0)) begin
                        if ((rs1_val + imm_i) == 32'h1000_0008) begin
                            rd_we    = 1'b1;
                            rd_wdata = {30'd0, uart0_rx_valid, uart0_tx_busy};
                        end else if ((rs1_val + imm_i) == 32'h1000_000C) begin
                            rd_we    = 1'b1;
                            rd_wdata = {24'd0, uart0_rx_data};
                        end else if ((rs1_val + imm_i) == 32'h1000_0014) begin
                            rd_we    = 1'b1;
                            rd_wdata = {24'd0, i2c0_data_rd_data};
                        end else if ((rs1_val + imm_i) == 32'h1000_0018) begin
                            rd_we    = 1'b1;
                            rd_wdata = {24'd0, i2c0_status};
                        end
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
            out_reg         <= 8'd0;
            halted          <= 1'b0;
            uart0_tx_data   <= 8'd0;
            uart0_tx_start  <= 1'b0;

            i2c0_ctrl_wr_data <= 8'd0;
            i2c0_ctrl_we      <= 1'b0;
            i2c0_data_wr_data <= 8'd0;
            i2c0_data_we      <= 1'b0;
            i2c0_div_wr_data  <= 8'd0;
            i2c0_div_we       <= 1'b0;
            uart0_rx_clear  <= 1'b0;
        end else begin
            // Default pulse value for UART0 TX.
            uart0_tx_start <= 1'b0;
            uart0_rx_clear <= 1'b0;
            i2c0_ctrl_we <= 1'b0;
            i2c0_data_we <= 1'b0;
            i2c0_div_we  <= 1'b0;

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

                                if (funct3 == 3'b010) begin
                                    if ((rs1_val + imm_i) == 32'h1000_000C) begin
                                        // Reading UART0 RX data consumes the byte.
                                        uart0_rx_clear <= 1'b1;
                                    end
                                end
                            end

                            // STORE: SW to memory-mapped GPIO only
                            7'b0100011: begin
                                pc <= pc + 32'd4;

                                if (funct3 == 3'b010) begin
                                    if ((rs1_val + imm_s) == 32'h1000_0000) begin
                                        out_reg <= rs2_val[7:0];
                                    end else if ((rs1_val + imm_s) == 32'h1000_0004) begin
                                        if (!uart0_tx_busy) begin
                                            uart0_tx_data  <= rs2_val[7:0];
                                            uart0_tx_start <= 1'b1;
                                        end
                                    end else if ((rs1_val + imm_s) == 32'h1000_0010) begin
                                        i2c0_ctrl_wr_data <= rs2_val[7:0];
                                        i2c0_ctrl_we      <= 1'b1;
                                    end else if ((rs1_val + imm_s) == 32'h1000_0014) begin
                                        i2c0_data_wr_data <= rs2_val[7:0];
                                        i2c0_data_we      <= 1'b1;
                                    end else if ((rs1_val + imm_s) == 32'h1000_001C) begin
                                        i2c0_div_wr_data  <= rs2_val[7:0];
                                        i2c0_div_we       <= 1'b1;
                                    end
                                end
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
           : (boot_mode ? boot_debug_byte : out_reg))
        : 8'd0;

    assign uio_out = {4'd0, i2c0_sda_out, i2c0_scl_out, 1'b0, uart0_tx};
    assign uio_oe  = {4'd0, i2c0_sda_oe,  i2c0_scl_oe,  1'b0, 1'b1};

endmodule

`default_nettype wire
