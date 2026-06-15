// ============================================================
// Module: uart_tx
// ------------------------------------------------------------
// Transmisor UART 8N1.
//
// Formato de trama:
//   - línea idle = 1
//   - 1 start bit = 0
//   - 8 data bits, LSB first
//   - 1 stop bit = 1
//
// Parámetros:
//   CLK_FREQ_HZ  : frecuencia del reloj del sistema
//   BAUD_RATE    : velocidad UART
//   CLKS_PER_BIT : ciclos de reloj por bit UART
// ============================================================

module uart_tx #(
    parameter CLK_FREQ_HZ  = 20000000,                                // Frecuencia por defecto: 60 MHz
    parameter BAUD_RATE    = 115200,                                  // Baudrate por defecto: 115200
    parameter CLKS_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE // División redondeada
)(
    input  wire       clk,        // Reloj principal
    input  wire       rst,        // Reset síncrono

    input  wire       tx_start,   // Pulso de inicio de transmisión
    input  wire [7:0] tx_data,    // Byte a transmitir

    output reg        tx,         // Línea UART TX
    output reg        busy,       // 1 mientras se está transmitiendo
    output reg        done        // Pulso de 1 ciclo al terminar transmisión
);

    localparam ST_IDLE  = 3'd0;   // Estado de reposo
    localparam ST_START = 3'd1;   // Estado de start bit
    localparam ST_DATA  = 3'd2;   // Estado de bits de datos
    localparam ST_STOP  = 3'd3;   // Estado de stop bit
    localparam ST_DONE  = 3'd4;   // Estado de finalización

    localparam [31:0] CLKS_PER_BIT_32 = CLKS_PER_BIT; // Versión 32-bit para evitar warnings de anchura

    reg [2:0]  state;             // Estado actual de la FSM
    reg [31:0] clk_count;         // Contador de ciclos dentro de cada bit UART
    reg [2:0]  bit_index;         // Índice del bit de dato transmitido
    reg [7:0]  data_reg;          // Copia estable del dato a transmitir

    always @(posedge clk) begin   // FSM síncrona
        if (rst) begin            // Reset síncrono
            state     <= ST_IDLE; // Vuelve a IDLE
            tx        <= 1'b1;    // UART idle es alto
            busy      <= 1'b0;    // No está ocupada
            done      <= 1'b0;    // No hay done
            clk_count <= 32'd0;   // Limpia contador
            bit_index <= 3'd0;    // Limpia índice de bit
            data_reg  <= 8'd0;    // Limpia registro de dato

        end else begin            // Funcionamiento normal
            done <= 1'b0;         // done es un pulso, se limpia por defecto

            case (state)

                ST_IDLE: begin                         // Estado de reposo
                    tx        <= 1'b1;                 // Línea TX en alto
                    busy      <= 1'b0;                 // Transmisor libre
                    clk_count <= 32'd0;                // Contador a cero
                    bit_index <= 3'd0;                 // Primer bit será bit 0

                    if (tx_start) begin                // Si llega orden de transmisión
                        busy     <= 1'b1;              // Marca ocupado
                        data_reg <= tx_data;           // Captura dato de entrada
                        state    <= ST_START;          // Pasa a enviar start bit
                    end
                end

                ST_START: begin                        // Envío del start bit
                    tx <= 1'b0;                        // Start bit UART es cero

                    if (clk_count == CLKS_PER_BIT_32 - 32'd1) begin // Si se completó duración de bit
                        clk_count <= 32'd0;            // Reinicia contador
                        state     <= ST_DATA;          // Pasa a bits de datos
                    end else begin
                        clk_count <= clk_count + 32'd1;// Sigue contando
                    end
                end

                ST_DATA: begin                         // Envío de los 8 bits de datos
                    tx <= data_reg[bit_index];         // UART envía LSB first

                    if (clk_count == CLKS_PER_BIT_32 - 32'd1) begin // Si terminó el bit actual
                        clk_count <= 32'd0;            // Reinicia contador

                        if (bit_index == 3'd7) begin   // Si era el último bit
                            bit_index <= 3'd0;         // Limpia índice
                            state     <= ST_STOP;      // Pasa al stop bit
                        end else begin
                            bit_index <= bit_index + 3'd1; // Avanza al siguiente bit
                        end
                    end else begin
                        clk_count <= clk_count + 32'd1;// Sigue contando
                    end
                end

                ST_STOP: begin                         // Envío del stop bit
                    tx <= 1'b1;                        // Stop bit UART es alto

                    if (clk_count == CLKS_PER_BIT_32 - 32'd1) begin // Si terminó stop bit
                        clk_count <= 32'd0;            // Reinicia contador
                        state     <= ST_DONE;          // Pasa a done
                    end else begin
                        clk_count <= clk_count + 32'd1;// Sigue contando
                    end
                end

                ST_DONE: begin                         // Final de transmisión
                    done  <= 1'b1;                     // Pulso de done
                    busy  <= 1'b0;                     // Libera transmisor
                    tx    <= 1'b1;                     // Mantiene TX idle
                    state <= ST_IDLE;                  // Vuelve a reposo
                end

                default: begin                         // Protección ante estado inválido
                    state <= ST_IDLE;                  // Vuelve a IDLE
                end

            endcase
        end
    end

endmodule