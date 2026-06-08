// ============================================================
// Module: regfile
// ------------------------------------------------------------
// Banco de registros RV32E.
//
// Características:
//   - 16 registros de 32 bits
//   - x0 siempre vale 0
//   - dos puertos de lectura
//   - un puerto de escritura
// ============================================================

module regfile (
    input  wire        clk,      // Reloj
    input  wire        rst,      // Reset

    input  wire [3:0]  rs1,      // Dirección de lectura 1
    input  wire [3:0]  rs2,      // Dirección de lectura 2
    input  wire [3:0]  rd,       // Dirección de escritura

    input  wire [31:0] wd,       // Dato de escritura
    input  wire        we,       // Write enable

    output wire [31:0] rv1,      // Dato leído desde rs1
    output wire [31:0] rv2       // Dato leído desde rs2
);

    reg [31:0] regs [0:15];      // Array de 16 registros de 32 bits

    integer i;                   // Variable auxiliar para reset

    // Escritura síncrona
    always @(posedge clk) begin
        if (rst) begin                               // En reset
            for (i = 0; i < 16; i = i + 1) begin    // Recorre todos los registros
                regs[i] <= 32'd0;                   // Los pone a cero
            end
        end else begin                              // Funcionamiento normal
            if (we && rd != 4'd0) begin             // Solo escribe si we=1 y rd != x0
                regs[rd] <= wd;                     // Escribe wd en el registro rd
            end
        end
    end

    // Lecturas combinacionales
    assign rv1 = (rs1 == 4'd0) ? 32'd0 : regs[rs1]; // x0 siempre vale 0
    assign rv2 = (rs2 == 4'd0) ? 32'd0 : regs[rs2]; // x0 siempre vale 0

endmodule