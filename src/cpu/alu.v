// ============================================================
// Module: alu
// ------------------------------------------------------------
// Unidad Aritmético-Lógica del core.
//
// Entradas:
//   - a      : operando 1
//   - b      : operando 2
//   - alu_op : código de operación
//
// Salidas:
//   - y    : resultado
//   - zero : 1 si el resultado es cero
// ============================================================

module alu (
    input  wire [31:0] a,        // Primer operando
    input  wire [31:0] b,        // Segundo operando
    input  wire [3:0]  alu_op,   // Operación a realizar
    output reg  [31:0] y,        // Resultado
    output wire        zero      // Flag de cero
);

    // Códigos internos de operación de la ALU
    localparam ALU_ADD  = 4'b0000; // Suma
    localparam ALU_SUB  = 4'b0001; // Resta
    localparam ALU_AND  = 4'b0010; // AND
    localparam ALU_OR   = 4'b0011; // OR
    localparam ALU_XOR  = 4'b0100; // XOR
    localparam ALU_SLT  = 4'b0101; // Set Less Than con signo
    localparam ALU_SLL  = 4'b0110; // Shift Left Logical
    localparam ALU_SRL  = 4'b0111; // Shift Right Logical
    localparam ALU_SLTU = 4'b1000; // Set Less Than sin signo
    localparam ALU_SRA  = 4'b1001; // Shift Right Arithmetic

    // Lógica combinacional de la ALU
    always @(*) begin
        case (alu_op)
            ALU_ADD:  y = a + b;                                // Suma
            ALU_SUB:  y = a - b;                                // Resta
            ALU_AND:  y = a & b;                                // AND bit a bit
            ALU_OR:   y = a | b;                                // OR bit a bit
            ALU_XOR:  y = a ^ b;                                // XOR bit a bit
            ALU_SLT:  y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // Comparación signed
            ALU_SLL:  y = a << b[4:0];                          // Desplazamiento lógico izq
            ALU_SRL:  y = a >> b[4:0];                          // Desplazamiento lógico der
            ALU_SLTU: y = (a < b) ? 32'd1 : 32'd0;              // Comparación unsigned
            ALU_SRA:  y = $signed(a) >>> b[4:0];                // Desplazamiento aritmético der
            default:  y = 32'd0;                                // Valor por defecto
        endcase
    end

    // Flag zero = 1 cuando el resultado es 0
    assign zero = (y == 32'd0);

endmodule