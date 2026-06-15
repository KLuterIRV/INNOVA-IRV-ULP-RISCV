// ============================================================
// Module: decoder
// ------------------------------------------------------------
// Decodificador de instrucciones RV32E.
//
// Este bloque:
//   - separa campos de la instrucción
//   - genera el inmediato
//   - genera señales de control
//   - genera el código de operación de la ALU
// ============================================================

module decoder (
    input  wire [31:0] instr,      // Instrucción de 32 bits

    output wire [6:0]  opcode,     // Campo opcode
    output wire [2:0]  funct3,     // Campo funct3
    output wire [6:0]  funct7,     // Campo funct7

    output wire [3:0]  rs1,        // Registro fuente 1 (RV32E = 4 bits)
    output wire [3:0]  rs2,        // Registro fuente 2 (RV32E = 4 bits)
    output wire [3:0]  rd,         // Registro destino   (RV32E = 4 bits)

    output reg  [31:0] imm,        // Inmediato extendido a 32 bits

    output reg         reg_write,  // Habilita escritura en banco de registros
    output reg         mem_write,  // Habilita escritura en dmem
    output reg         alu_src,    // Selecciona operando B de ALU: 0=rv2, 1=imm
    output reg         mem_to_reg, // Selecciona writeback desde memoria
    output reg         branch,     // Indica instrucción branch
    output reg         jump,       // Indica salto
    output reg  [3:0]  alu_op      // Código de operación de la ALU
);

    // Extracción directa de campos de la instrucción
    assign opcode = instr[6:0];     // Bits 6:0 = opcode
    assign rd     = instr[10:7];    // Bits 11:7 recortados a 4 bits para RV32E
    assign funct3 = instr[14:12];   // Bits 14:12 = funct3
    assign rs1    = instr[18:15];   // Bits 19:15 recortados a 4 bits para RV32E
    assign rs2    = instr[23:20];   // Bits 24:20 recortados a 4 bits para RV32E
    assign funct7 = instr[31:25];   // Bits 31:25 = funct7

    // Opcodes principales soportados
    localparam OPCODE_R      = 7'b0110011; // Instrucciones tipo R
    localparam OPCODE_I      = 7'b0010011; // Instrucciones tipo I aritméticas
    localparam OPCODE_LOAD   = 7'b0000011; // Loads
    localparam OPCODE_STORE  = 7'b0100011; // Stores
    localparam OPCODE_BRANCH = 7'b1100011; // Branches
    localparam OPCODE_JAL    = 7'b1101111; // JAL
    localparam OPCODE_JALR   = 7'b1100111; // JALR
    localparam OPCODE_LUI    = 7'b0110111; // LUI
    localparam OPCODE_AUIPC  = 7'b0010111; // AUIPC

    // Operaciones internas de la ALU
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLL  = 4'b0110;
    localparam ALU_SRL  = 4'b0111;
    localparam ALU_SLTU = 4'b1000;
    localparam ALU_SRA  = 4'b1001;

    // Lógica combinacional principal del decodificador
    always @(*) begin
        // Valores por defecto para evitar latches
        imm        = 32'd0;      // Inmediato por defecto
        reg_write  = 1'b0;       // No escribir registros por defecto
        mem_write  = 1'b0;       // No escribir memoria por defecto
        alu_src    = 1'b0;       // Por defecto ALU usa rv2
        mem_to_reg = 1'b0;       // Por defecto writeback desde ALU
        branch     = 1'b0;       // Por defecto no branch
        jump       = 1'b0;       // Por defecto no jump
        alu_op     = ALU_ADD;    // Por defecto suma

        case (opcode)

            // ----------------------------------------------------
            // Tipo R
            // ----------------------------------------------------
            OPCODE_R: begin
                reg_write = 1'b1; // Resultado se escribe en rd
                alu_src   = 1'b0; // Operando B viene de rs2

                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_op = ALU_ADD;  // add
                    {7'b0100000, 3'b000}: alu_op = ALU_SUB;  // sub
                    {7'b0000000, 3'b111}: alu_op = ALU_AND;  // and
                    {7'b0000000, 3'b110}: alu_op = ALU_OR;   // or
                    {7'b0000000, 3'b100}: alu_op = ALU_XOR;  // xor
                    {7'b0000000, 3'b010}: alu_op = ALU_SLT;  // slt
                    {7'b0000000, 3'b011}: alu_op = ALU_SLTU; // sltu
                    {7'b0000000, 3'b001}: alu_op = ALU_SLL;  // sll
                    {7'b0000000, 3'b101}: alu_op = ALU_SRL;  // srl
                    {7'b0100000, 3'b101}: alu_op = ALU_SRA;  // sra
                    default:              alu_op = ALU_ADD;  // fallback
                endcase
            end

            // ----------------------------------------------------
            // Tipo I aritmético
            // ----------------------------------------------------
            OPCODE_I: begin
                reg_write = 1'b1;                         // Escribe en rd
                alu_src   = 1'b1;                         // Operando B = inmediato
                imm       = {{20{instr[31]}}, instr[31:20]}; // Sign-extend del inmediato

                case (funct3)
                    3'b000: alu_op = ALU_ADD;   // addi
                    3'b111: alu_op = ALU_AND;   // andi
                    3'b110: alu_op = ALU_OR;    // ori
                    3'b100: alu_op = ALU_XOR;   // xori
                    3'b010: alu_op = ALU_SLT;   // slti
                    3'b011: alu_op = ALU_SLTU;  // sltiu
                    3'b001: alu_op = ALU_SLL;   // slli
                    3'b101: begin                // srli / srai
                        if (instr[31:25] == 7'b0100000)
                            alu_op = ALU_SRA;    // srai
                        else
                            alu_op = ALU_SRL;    // srli
                    end
                    default: alu_op = ALU_ADD;   // Por defecto
                endcase
            end

            // ----------------------------------------------------
            // Load
            // ----------------------------------------------------
            OPCODE_LOAD: begin
                reg_write  = 1'b1;                         // Se escribe en rd
                alu_src    = 1'b1;                         // Dirección = rs1 + imm
                mem_to_reg = 1'b1;                         // Writeback desde memoria
                alu_op     = ALU_ADD;                      // ALU suma base + offset
                imm        = {{20{instr[31]}}, instr[31:20]}; // Inmediato tipo I
            end

            // ----------------------------------------------------
            // Store
            // ----------------------------------------------------
            OPCODE_STORE: begin
                mem_write = 1'b1;                          // Activa escritura en memoria
                alu_src   = 1'b1;                          // Dirección = rs1 + imm
                alu_op    = ALU_ADD;                       // ALU suma base + offset
                imm       = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // Inmediato tipo S
            end

            // ----------------------------------------------------
            // Branch
            // ----------------------------------------------------
            OPCODE_BRANCH: begin
                branch = 1'b1;                             // Marca branch
                alu_op = ALU_SUB;                          // ALU compara usando resta
                imm    = {{19{instr[31]}}, instr[31], instr[7],
                          instr[30:25], instr[11:8], 1'b0}; // Inmediato tipo B
            end

            // ----------------------------------------------------
            // JAL
            // ----------------------------------------------------
            OPCODE_JAL: begin
                reg_write = 1'b1;                          // Guarda retorno en rd
                jump      = 1'b1;                          // Es un salto
                imm       = {{11{instr[31]}}, instr[31], instr[19:12],
                             instr[20], instr[30:21], 1'b0}; // Inmediato tipo J
            end

            // ----------------------------------------------------
            // JALR
            // ----------------------------------------------------
            OPCODE_JALR: begin
                reg_write = 1'b1;                          // Guarda retorno en rd
                jump      = 1'b1;                          // Es un salto
                alu_src   = 1'b1;                          // Usa inmediato
                alu_op    = ALU_ADD;                       // Base + offset
                imm       = {{20{instr[31]}}, instr[31:20]}; // Inmediato tipo I
            end

            // ----------------------------------------------------
            // LUI
            // ----------------------------------------------------
            OPCODE_LUI: begin
                reg_write = 1'b1;                          // Escribe en rd
                alu_src   = 1'b1;                          // No es crítico aquí, pero mantenido
                imm       = {instr[31:12], 12'd0};        // Inmediato upper
            end

            // ----------------------------------------------------
            // AUIPC
            // ----------------------------------------------------
            OPCODE_AUIPC: begin
                reg_write = 1'b1;                          // Escribe en rd
                imm       = {instr[31:12], 12'd0};        // Inmediato upper
            end

            // ----------------------------------------------------
            // Default
            // ----------------------------------------------------
            default: begin
                imm        = 32'd0;      // Inmediato nulo
                reg_write  = 1'b0;       // No escribe registros
                mem_write  = 1'b0;       // No escribe memoria
                alu_src    = 1'b0;       // Valor por defecto
                mem_to_reg = 1'b0;       // Valor por defecto
                branch     = 1'b0;       // No branch
                jump       = 1'b0;       // No jump
                alu_op     = ALU_ADD;    // ALU en suma por defecto
            end

        endcase
    end

endmodule