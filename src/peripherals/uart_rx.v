// ============================================================
// Module: uart_rx
// ------------------------------------------------------------
// Receptor UART 8N1.
//
// Formato esperado:
//   - línea idle = 1
//   - start bit = 0
//   - 8 data bits, LSB first
//   - stop bit = 1
//
// Estrategia:
//   - Detecta flanco/start cuando rx pasa a 0.
//   - Espera medio bit para confirmar start.
//   - Muestrea cada bit en el centro del periodo esperado.
//   - Valida que stop bit sea 1.
// ============================================================

module uart_rx #(
    parameter CLK_FREQ_HZ  = 20000000,                                // Frecuencia del reloj del sistema
    parameter BAUD_RATE    = 115200,                                  // Baudrate esperado
    parameter CLKS_PER_BIT = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE // Ciclos por bit con redondeo
)(
    input  wire       clk,          // Reloj principal
    input  wire       rst,          // Reset síncrono

    input  wire       rx,           // Línea UART RX

    output reg  [7:0] rx_data,      // Byte recibido
    output reg        rx_valid,     // Pulso de 1 ciclo cuando rx_data es válido
    output reg        busy,         // 1 mientras se recibe una trama
    output reg        framing_error // Pulso si el stop bit no es válido
);

    localparam ST_IDLE  = 3'd0;     // Espera start bit
    localparam ST_START = 3'd1;     // Confirma start bit
    localparam ST_DATA  = 3'd2;     // Recibe bits de datos
    localparam ST_STOP  = 3'd3;     // Verifica stop bit
    localparam ST_DONE  = 3'd4;     // Finaliza recepción

    localparam [31:0] CLKS_PER_BIT_32 = CLKS_PER_BIT; // Parámetro convertido a 32 bits
    localparam [31:0] HALF_BIT_32     = CLKS_PER_BIT / 2; // Medio periodo de bit

    reg [2:0]  state;               // Estado actual de la FSM
    reg [31:0] clk_count;           // Contador de ciclos dentro del bit
    reg [2:0]  bit_index;           // Índice del bit recibido
    reg [7:0]  data_reg;            // Registro temporal del byte recibido

    always @(posedge clk) begin     // FSM síncrona
        if (rst) begin              // Reset síncrono
            state         <= ST_IDLE; // Vuelve a reposo
            clk_count     <= 32'd0;  // Limpia contador
            bit_index     <= 3'd0;   // Limpia índice
            data_reg      <= 8'd0;   // Limpia buffer interno
            rx_data       <= 8'd0;   // Limpia salida de dato
            rx_valid      <= 1'b0;   // Limpia valid
            busy          <= 1'b0;   // No está recibiendo
            framing_error <= 1'b0;   // Limpia error

        end else begin              // Funcionamiento normal
            rx_valid      <= 1'b0;   // rx_valid es un pulso
            framing_error <= 1'b0;   // framing_error también es un pulso

            case (state)

                ST_IDLE: begin                      // Espera inicio de trama
                    busy      <= 1'b0;              // No ocupado
                    clk_count <= 32'd0;             // Contador limpio
                    bit_index <= 3'd0;              // Primer bit será 0

                    if (rx == 1'b0) begin           // Detecta start bit
                        busy  <= 1'b1;              // Marca ocupado
                        state <= ST_START;          // Pasa a confirmar start
                    end
                end

                ST_START: begin                     // Confirma start bit en el centro
                    if (clk_count == HALF_BIT_32) begin // Espera medio bit
                        if (rx == 1'b0) begin       // Si sigue bajo, es start válido
                            clk_count <= 32'd0;     // Reinicia contador
                            state     <= ST_DATA;   // Pasa a datos
                        end else begin              // Si volvió a alto
                            state <= ST_IDLE;       // Falso start, vuelve a idle
                        end
                    end else begin
                        clk_count <= clk_count + 32'd1; // Sigue contando
                    end
                end

                ST_DATA: begin                      // Recibe bits de datos
                    if (clk_count == CLKS_PER_BIT_32 - 32'd1) begin // Centro del siguiente bit
                        clk_count           <= 32'd0; // Reinicia contador
                        data_reg[bit_index] <= rx;    // Guarda bit recibido

                        if (bit_index == 3'd7) begin  // Si era el último bit
                            bit_index <= 3'd0;        // Limpia índice
                            state     <= ST_STOP;     // Pasa a stop bit
                        end else begin
                            bit_index <= bit_index + 3'd1; // Avanza al siguiente bit
                        end
                    end else begin
                        clk_count <= clk_count + 32'd1; // Sigue contando
                    end
                end

                ST_STOP: begin                      // Verifica stop bit
                    if (clk_count == CLKS_PER_BIT_32 - 32'd1) begin // Espera duración de stop
                        clk_count <= 32'd0;         // Reinicia contador

                        if (rx == 1'b1) begin       // Stop bit correcto
                            rx_data  <= data_reg;   // Publica dato recibido
                            rx_valid <= 1'b1;       // Pulso de dato válido
                        end else begin              // Stop bit incorrecto
                            framing_error <= 1'b1;  // Señaliza error de trama
                        end

                        state <= ST_DONE;           // Finaliza recepción
                    end else begin
                        clk_count <= clk_count + 32'd1; // Sigue contando
                    end
                end

                ST_DONE: begin                      // Estado final de un ciclo
                    busy  <= 1'b0;                  // Libera receptor
                    state <= ST_IDLE;               // Vuelve a idle
                end

                default: begin                      // Protección
                    state <= ST_IDLE;               // Vuelve a idle
                end

            endcase
        end
    end

endmodule