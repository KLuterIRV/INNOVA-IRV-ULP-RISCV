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
    assign instr = mem[addr[9:2]];          // Usa addr alineada a palabra

endmodule