// ============================================================
// Module: sevenseg
// ------------------------------------------------------------
// Periférico combinacional para convertir un valor de entrada
// en un patrón de 7 segmentos.
//
// Modos soportados:
//   - HEX mode   : value[3:0] representa 0-F
//   - ASCII mode : value[7:0] representa código ASCII
//   - RAW mode   : value[7:0] se usa directamente como patrón
//
// Formato de salida:
//   seg_out[7]   = decimal point
//   seg_out[6:0] = {g, f, e, d, c, b, a}
//
// active_low:
//   - 0 = salida active-high
//   - 1 = salida invertida para displays active-low
// ============================================================

module sevenseg (
    input  wire [7:0] value,       // Valor de entrada: HEX, ASCII o RAW
    input  wire       ascii_mode,  // 1 = interpretar value como código ASCII
    input  wire       raw_mode,    // 1 = usar value directamente como patrón
    input  wire       active_low,  // 1 = invertir salida para display active-low
    output wire [7:0] seg_out      // Patrón final hacia el display
);

    reg [7:0] seg_decoded;         // Patrón interno antes de aplicar active_low

    always @(*) begin              // Lógica puramente combinacional

        if (raw_mode) begin        // Si RAW mode está activo
            seg_decoded = value;   // Usa directamente el patrón escrito por software

        end else if (ascii_mode) begin // Si ASCII mode está activo
            case (value)           // Decodifica el carácter ASCII

                // ------------------------------------------------
                // Símbolos básicos
                // ------------------------------------------------
                8'h20: seg_decoded = 8'h00; // Espacio
                8'h2D: seg_decoded = 8'h40; // Guion '-'
                8'h5F: seg_decoded = 8'h08; // Guion bajo '_'

                // ------------------------------------------------
                // Dígitos ASCII '0' - '9'
                // ------------------------------------------------
                8'h30: seg_decoded = 8'h3F; // '0'
                8'h31: seg_decoded = 8'h06; // '1'
                8'h32: seg_decoded = 8'h5B; // '2'
                8'h33: seg_decoded = 8'h4F; // '3'
                8'h34: seg_decoded = 8'h66; // '4'
                8'h35: seg_decoded = 8'h6D; // '5'
                8'h36: seg_decoded = 8'h7D; // '6'
                8'h37: seg_decoded = 8'h07; // '7'
                8'h38: seg_decoded = 8'h7F; // '8'
                8'h39: seg_decoded = 8'h6F; // '9'

                // ------------------------------------------------
                // Letras mayúsculas ASCII 'A' - 'Z'
                // Algunas letras son aproximadas por limitación
                // física del display de 7 segmentos.
                // ------------------------------------------------
                8'h41: seg_decoded = 8'h77; // 'A'
                8'h42: seg_decoded = 8'h7C; // 'B' representada como 'b'
                8'h43: seg_decoded = 8'h39; // 'C'
                8'h44: seg_decoded = 8'h5E; // 'D' representada como 'd'
                8'h45: seg_decoded = 8'h79; // 'E'
                8'h46: seg_decoded = 8'h71; // 'F'
                8'h47: seg_decoded = 8'h3D; // 'G' aproximada
                8'h48: seg_decoded = 8'h76; // 'H'
                8'h49: seg_decoded = 8'h30; // 'I' aproximada
                8'h4A: seg_decoded = 8'h1E; // 'J'
                8'h4B: seg_decoded = 8'h75; // 'K' aproximada
                8'h4C: seg_decoded = 8'h38; // 'L'
                8'h4D: seg_decoded = 8'h37; // 'M' aproximada
                8'h4E: seg_decoded = 8'h54; // 'N' representada como 'n'
                8'h4F: seg_decoded = 8'h3F; // 'O' representada como '0'
                8'h50: seg_decoded = 8'h73; // 'P'
                8'h51: seg_decoded = 8'h67; // 'Q' aproximada
                8'h52: seg_decoded = 8'h50; // 'R' representada como 'r'
                8'h53: seg_decoded = 8'h6D; // 'S' representada como '5'
                8'h54: seg_decoded = 8'h78; // 'T' aproximada
                8'h55: seg_decoded = 8'h3E; // 'U'
                8'h56: seg_decoded = 8'h3E; // 'V' aproximada como 'U'
                8'h57: seg_decoded = 8'h2A; // 'W' muy aproximada
                8'h58: seg_decoded = 8'h76; // 'X' aproximada como 'H'
                8'h59: seg_decoded = 8'h6E; // 'Y'
                8'h5A: seg_decoded = 8'h5B; // 'Z' representada como '2'

                // ------------------------------------------------
                // Letras minúsculas comunes
                // ------------------------------------------------
                8'h61: seg_decoded = 8'h77; // 'a'
                8'h62: seg_decoded = 8'h7C; // 'b'
                8'h63: seg_decoded = 8'h58; // 'c'
                8'h64: seg_decoded = 8'h5E; // 'd'
                8'h65: seg_decoded = 8'h79; // 'e'
                8'h66: seg_decoded = 8'h71; // 'f'
                8'h67: seg_decoded = 8'h6F; // 'g' aproximada
                8'h68: seg_decoded = 8'h74; // 'h'
                8'h69: seg_decoded = 8'h10; // 'i'
                8'h6A: seg_decoded = 8'h0E; // 'j'
                8'h6C: seg_decoded = 8'h30; // 'l'
                8'h6E: seg_decoded = 8'h54; // 'n'
                8'h6F: seg_decoded = 8'h5C; // 'o'
                8'h72: seg_decoded = 8'h50; // 'r'
                8'h74: seg_decoded = 8'h78; // 't'
                8'h75: seg_decoded = 8'h1C; // 'u'
                8'h79: seg_decoded = 8'h6E; // 'y'

                default: seg_decoded = 8'h00; // Cualquier carácter no soportado se muestra en blanco
            endcase

        end else begin                         // Si no es RAW ni ASCII, usa modo HEX
            case (value[3:0])                  // Solo se usan los 4 bits bajos
                4'h0: seg_decoded = 8'h3F;     // 0
                4'h1: seg_decoded = 8'h06;     // 1
                4'h2: seg_decoded = 8'h5B;     // 2
                4'h3: seg_decoded = 8'h4F;     // 3
                4'h4: seg_decoded = 8'h66;     // 4
                4'h5: seg_decoded = 8'h6D;     // 5
                4'h6: seg_decoded = 8'h7D;     // 6
                4'h7: seg_decoded = 8'h07;     // 7
                4'h8: seg_decoded = 8'h7F;     // 8
                4'h9: seg_decoded = 8'h6F;     // 9
                4'hA: seg_decoded = 8'h77;     // A
                4'hB: seg_decoded = 8'h7C;     // b
                4'hC: seg_decoded = 8'h39;     // C
                4'hD: seg_decoded = 8'h5E;     // d
                4'hE: seg_decoded = 8'h79;     // E
                4'hF: seg_decoded = 8'h71;     // F
                default: seg_decoded = 8'h00;  // Caso imposible, pero seguro
            endcase
        end
    end

    assign seg_out = active_low ? ~seg_decoded : seg_decoded; // Invierte salida si el display es active-low

endmodule