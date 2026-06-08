// ============================================================
// Module: imem
// ------------------------------------------------------------
// Memoria de instrucciones.
//
// Funciones:
//   - lectura por dirección PC
//   - programación externa desde el uart_loader
//   - carga inicial desde mem/program.hex
// ============================================================

module imem (
    input  wire        clk,         // Reloj para programación de memoria

    input  wire [31:0] addr,        // Dirección de lectura (PC)
    output wire [31:0] instr,       // Instrucción leída

    input  wire        prog_we,     // Write enable del loader
    input  wire [7:0]  prog_addr,   // Dirección de palabra a programar
    input  wire [31:0] prog_wdata   // Dato a escribir
);

    reg [31:0] mem [0:255];         // Memoria de 256 palabras de 32 bits
    // Dirección de palabra (8 bits) para acceso a memoria, ignorando los bits de byte
    wire [7:0] word_addr;                                        // Solo se usan los bits [9:2] de addr para indexar palabras (256 palabras = 8 bits de dirección)
    assign word_addr = addr[9:2];                                // Alineación a palabra: se ignoran los bits [1:0] de addr

    wire _unused_imem_addr;                                      // Señal dummy para evitar advertencias de señales no conectadas
    assign _unused_imem_addr = &{addr[31:10], addr[1:0], 1'b0};  // Evita advertencia de bits de dirección no usados en word_addr, aunque no se usen en la lógica de lectura

    assign instr = mem[word_addr];                                // Lectura combinacional de instrucción usando word_addr

    // Inicializar el codigo como 0
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    // Programación por UART loader
    always @(posedge clk) begin
        if (prog_we) begin                  // Si el loader quiere escribir
            mem[prog_addr] <= prog_wdata;   // Escribe la palabra en la dirección indicada
        end
    end

    // Lectura combinacional de instrucción

    assign instr = mem[word_addr];                                      // Lectura combinacional de instrucción usando word_addr

endmodule