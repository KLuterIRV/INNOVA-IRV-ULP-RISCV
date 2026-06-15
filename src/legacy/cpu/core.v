// ============================================================
// Module: core
// ------------------------------------------------------------
// Núcleo RV32E simplificado.
//
// Bloques internos:
//   - PC y control de flujo
//   - IMEM
//   - Decoder
//   - Regfile
//   - ALU
//   - DMEM / periféricos
//
// Características:
//   - soporte RV32E simplificado
//   - arranque tras loader_done
//   - parada con ebreak
// ============================================================

module core (
    input  wire        clk,              // Reloj principal
    input  wire        rst,              // Reset
    input  wire        uart0_rx,         // Entrada UART RX hacia periféricos
    input  wire        boot_mode,        // 1 = modo carga
    input  wire        imem_prog_we,     // Programación externa de IMEM
    input  wire [7:0]  imem_prog_addr,   // Dirección a programar en IMEM
    input  wire [31:0] imem_prog_wdata,  // Dato a programar en IMEM
    input  wire        loader_done,      // El loader terminó

    output wire [31:0] pc_debug,         // PC para debug
    output wire [31:0] instr_debug,      // Instrucción actual para debug
    output wire [7:0]  out_reg,          // Salida física de periféricos
    output wire [7:0]  sevenseg_out,     // Patrón 7 segmentos
    output wire        halted_debug,     // Estado halted
    output wire        uart0_tx          // Salida UART TX
);

    // ------------------------------------------------------------
    // Registros de estado del core
    // ------------------------------------------------------------
    reg [31:0] pc;                       // Program counter
    reg halted;                          // Flag que detiene el core tras ebreak

    // ------------------------------------------------------------
    // Señales generales
    // ------------------------------------------------------------
    wire is_ebreak;                      // Detecta instrucción ebreak
    wire [31:0] instr;                   // Instrucción leída de IMEM

    // Campos de instrucción
    wire [6:0] opcode;                   // Opcode
    wire [2:0] funct3;                   // Funct3
    wire [6:0] funct7;                   // Funct7

    // Direcciones de registros
    wire [3:0] rs1;                      // Registro fuente 1
    wire [3:0] rs2;                      // Registro fuente 2
    wire [3:0] rd;                       // Registro destino

    // Inmediato decodificado
    wire [31:0] imm;                     // Inmediato de la instrucción

    // Señales de control desde decoder
    wire reg_write;                      // Habilita escritura en regfile
    wire mem_write;                      // Habilita store en dmem
    wire alu_src;                        // Selecciona inmediato o rs2 para ALU
    wire mem_to_reg;                     // Selecciona writeback desde dmem
    wire branch;                         // Instrucción branch
    wire jump;                           // Instrucción jump
    wire [3:0] alu_op;                   // Operación de la ALU

    // Datos del banco de registros
    wire [31:0] rv1;                     // Valor leído de rs1
    wire [31:0] rv2;                     // Valor leído de rs2

    // Señales ALU
    wire [31:0] alu_b;                   // Operando B real de la ALU
    wire [31:0] alu_y;                   // Resultado de la ALU
    wire        alu_zero;                // Flag zero de la ALU

    // Señales de memoria y writeback
    wire [31:0] mem_rdata;               // Dato leído desde dmem
    wire [31:0] wb_data;                 // Dato final de writeback

    // Señales auxiliares para branches
    wire take_branch;                    // Branch tomado
    wire signed_less;                    // Comparación signed rv1 < rv2
    wire unsigned_less;                  // Comparación unsigned rv1 < rv2

    // Cálculo de siguiente PC
    wire [31:0] pc_plus_4;               // PC + 4
    wire [31:0] pc_branch;               // PC + offset
    wire [31:0] pc_next;                 // Próximo PC

    // Señales especiales de salto
    wire is_jalr;                        // Detecta JALR
    wire [31:0] pc_jalr;                 // Dirección calculada de JALR

    // Señales especiales de instrucciones upper immediate
    wire is_lui;                         // Detecta LUI
    wire is_auipc;                       // Detecta AUIPC

    // Indica si el core puede correr
    wire core_run;                       // 1 = core liberado para ejecutar
    assign core_run = (!boot_mode) || loader_done; // Corre si no estamos en boot o si el loader ya terminó

    // ------------------------------------------------------------
    // Cálculo de direcciones y comparaciones
    // ------------------------------------------------------------
    assign pc_plus_4 = pc + 32'd4;                  // Siguiente instrucción secuencial
    assign pc_branch = pc + imm;                    // Destino branch / jal usando pc + imm

    assign signed_less   = ($signed(rv1) < $signed(rv2)); // Comparación signed
    assign unsigned_less = (rv1 < rv2);                    // Comparación unsigned

    assign is_jalr = (opcode == 7'b1100111);       // Detecta opcode JALR
    assign pc_jalr = (rv1 + imm) & 32'hFFFFFFFE;   // JALR fuerza bit 0 = 0
    assign is_lui = (opcode == 7'b0110111);        // Detecta LUI
    assign is_auipc = (opcode == 7'b0010111);      // Detecta AUIPC

    // ------------------------------------------------------------
    // Lógica de branch
    // ------------------------------------------------------------
    assign take_branch = branch && (
        (funct3 == 3'b000 &&  alu_zero)       ||   // beq
        (funct3 == 3'b001 && !alu_zero)       ||   // bne
        (funct3 == 3'b100 &&  signed_less)    ||   // blt
        (funct3 == 3'b101 && !signed_less)    ||   // bge
        (funct3 == 3'b110 &&  unsigned_less)  ||   // bltu
        (funct3 == 3'b111 && !unsigned_less)       // bgeu
    );

    // Selección del siguiente PC
    assign pc_next = is_jalr     ? pc_jalr   :  // JALR tiene prioridad
                     jump        ? pc_branch :  // JAL
                     take_branch ? pc_branch :  // Branch tomado
                                   pc_plus_4;   // Caso secuencial normal

    // Selección del operando B de la ALU
    assign alu_b = alu_src ? imm : rv2;         // Si alu_src=1 usa inmediato, si no usa rv2

    // Selección del dato de writeback
    assign wb_data = jump       ? pc_plus_4 :   // En saltos se guarda retorno
                     is_lui     ? imm       :   // LUI escribe inmediato
                     is_auipc   ? pc + imm  :   // AUIPC escribe PC + inmediato
                     mem_to_reg ? mem_rdata :   // En loads escribe dato de memoria
                                  alu_y;        // En el resto escribe resultado ALU

    // Señales de debug
    assign pc_debug    = pc;                    // Exporta PC
    assign instr_debug = instr;                 // Exporta instrucción actual

    // Mark intentionally unused decoder outputs for GDS flow to work correctly
    wire _unused_core;                          // define una señal para marcar outputs no usados
    assign _unused_core = &{funct7, 1'b0};      // Marca funct7 como no usado (en RV32E no se usa) y evita warnings

    // Detección de ebreak
    assign is_ebreak    = (instr == 32'h00100073); // EBREAK codificado completo
    assign halted_debug = halted;                  // Exporta flag halted

    // ------------------------------------------------------------
    // Registro de PC y control de parada
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin                           // En reset
            pc     <= 32'd0;                    // PC vuelve a 0
            halted <= 1'b0;                     // Core no queda parado
        end else begin                          // Funcionamiento normal
            if (!core_run) begin                // Si el core aún no debe correr
                pc     <= 32'd0;                // Mantiene PC en cero
                halted <= 1'b0;                 // Asegura que no queda halted
            end else begin                      // Core habilitado
                if (!halted) begin              // Solo avanza si no está parado
                    if (is_ebreak) begin        // Si ejecuta ebreak
                        halted <= 1'b1;         // Entra en estado halt
                        pc     <= pc;           // Mantiene el mismo PC
                    end else begin              // Instrucción normal
                        pc <= pc_next;          // Avanza al siguiente PC
                    end
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Instancia de memoria de instrucciones
    // ------------------------------------------------------------
    imem u_imem (
        .clk        (clk),              // Reloj de programación
        .addr       (pc),               // Dirección de lectura = PC
        .instr      (instr),            // Instrucción leída
        .prog_we    (imem_prog_we),     // Write enable del loader
        .prog_addr  (imem_prog_addr),   // Dirección de programación
        .prog_wdata (imem_prog_wdata)   // Dato de programación
    );

    // ------------------------------------------------------------
    // Instancia del decoder
    // ------------------------------------------------------------
    decoder u_decoder (
        .instr      (instr),            // Instrucción actual
        .opcode     (opcode),           // Campo opcode
        .funct3     (funct3),           // Campo funct3
        .funct7     (funct7),           // Campo funct7
        .rs1        (rs1),              // Registro fuente 1
        .rs2        (rs2),              // Registro fuente 2
        .rd         (rd),               // Registro destino
        .imm        (imm),              // Inmediato extendido
        .reg_write  (reg_write),        // Señal reg_write
        .mem_write  (mem_write),        // Señal mem_write
        .alu_src    (alu_src),          // Señal alu_src
        .mem_to_reg (mem_to_reg),       // Señal mem_to_reg
        .branch     (branch),           // Señal branch
        .jump       (jump),             // Señal jump
        .alu_op     (alu_op)            // Operación de ALU
    );

    // ------------------------------------------------------------
    // Instancia del banco de registros
    // ------------------------------------------------------------
    regfile u_regfile (
        .clk (clk),                     // Reloj
        .rst (rst),                     // Reset
        .rs1 (rs1),                     // Dirección rs1
        .rs2 (rs2),                     // Dirección rs2
        .rd  (rd),                      // Dirección rd
        .wd  (wb_data),                 // Dato a escribir
        .we  (reg_write),               // Habilita escritura
        .rv1 (rv1),                     // Dato leído de rs1
        .rv2 (rv2)                      // Dato leído de rs2
    );

    // ------------------------------------------------------------
    // Instancia de la ALU
    // ------------------------------------------------------------
    alu u_alu (
        .a      (rv1),                  // Operando A
        .b      (alu_b),                // Operando B
        .alu_op (alu_op),               // Operación
        .y      (alu_y),                // Resultado
        .zero   (alu_zero)              // Flag zero
    );

    // ------------------------------------------------------------
    // Instancia de memoria de datos y periféricos
    // ------------------------------------------------------------
    dmem u_dmem (
        .clk          (clk),            // Reloj
        .rst          (rst),            // Reset
        .addr         (alu_y),          // Dirección calculada por la ALU
        .wdata        (rv2),            // Dato de store
        .we           (mem_write),      // Activa escritura en store
        .rdata        (mem_rdata),      // Dato leído en load
        .uart0_rx     (uart0_rx),       // Entrada UART RX
        .out_reg      (out_reg),        // Salida física compartida
        .sevenseg_out (sevenseg_out),   // Salida debug del 7 segmentos
        .uart0_tx     (uart0_tx)        // Salida UART TX
    );

endmodule