// ============================================================
// Module: uart_loader
// ------------------------------------------------------------
// Loader hardware mínimo por UART.
//
// Función:
//   - Recibe un stream de bytes por UART.
//   - Detecta un byte de sincronización.
//   - Recibe número de palabras de programa.
//   - Recibe palabras de 32 bits en formato little-endian.
//   - Genera escrituras hacia IMEM.
//   - Activa done cuando termina.
//
// Protocolo actual:
//   Byte 0      : 0x55 sync
//   Byte 1      : número de palabras N
//   Bytes 2..   : N palabras de 32 bits little-endian
//
// Ejemplo:
//   0x100000B7 se transmite como:
//      B7 00 00 10
// ============================================================

module uart_loader #(
    parameter CLK_FREQ_HZ = 60000000, // Frecuencia de reloj del sistema
    parameter BAUD_RATE   = 115200    // Baudrate UART
)(
    input  wire       clk,            // Reloj principal
    input  wire       rst,            // Reset síncrono
    input  wire       enable,         // Habilita el loader

    input  wire       uart_rx_i,      // Entrada UART RX dedicada al loader

    output reg        prog_we,        // Pulso de escritura hacia IMEM
    output reg  [7:0] prog_addr,      // Dirección de palabra en IMEM
    output reg [31:0] prog_wdata,     // Palabra de 32 bits a escribir

    output reg        done,           // 1 cuando la carga ha terminado
    output reg        error           // 1 si ocurrió un error
);

    localparam ST_WAIT_SYNC = 3'd0;   // Espera byte 0x55
    localparam ST_WAIT_N    = 3'd1;   // Espera número de palabras
    localparam ST_RECV_DATA = 3'd2;   // Recibe bytes de datos
    localparam ST_DONE      = 3'd3;   // Carga completada
    localparam ST_ERROR     = 3'd4;   // Error de carga

    localparam SYNC_BYTE = 8'h55;     // Byte de sincronización

    reg [2:0] state;                  // Estado actual de la FSM

    wire [7:0] rx_data;               // Byte recibido desde uart_rx
    wire       rx_valid;              // Pulso de byte válido
    wire       rx_busy;               // UART RX ocupada
    wire       rx_framing_error;      // Error de framing desde UART RX

    reg [7:0] words_total;            // Número total de palabras a cargar
    reg [7:0] word_index;             // Índice de palabra actual
    reg [1:0] byte_index;             // Índice de byte dentro de la palabra
    reg [31:0] word_buf;              // Buffer temporal de palabra little-endian

    // ------------------------------------------------------------
    // UART RX interna del loader
    // ------------------------------------------------------------
    uart_rx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),    // Propaga frecuencia al receptor
        .BAUD_RATE  (BAUD_RATE)       // Propaga baudrate al receptor
    ) u_loader_uart_rx (
        .clk           (clk),         // Reloj
        .rst           (rst),         // Reset
        .rx            (uart_rx_i),   // Línea RX
        .rx_data       (rx_data),     // Byte recibido
        .rx_valid      (rx_valid),    // Byte válido
        .busy          (rx_busy),     // Estado busy
        .framing_error (rx_framing_error) // Error de trama
    );

    // ------------------------------------------------------------
    // FSM principal del loader
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin                         // Reset síncrono
            state       <= ST_WAIT_SYNC;       // Vuelve a esperar sync
            prog_we     <= 1'b0;               // No escribir IMEM
            prog_addr   <= 8'd0;               // Dirección de programación cero
            prog_wdata  <= 32'd0;              // Dato de programación cero
            done        <= 1'b0;               // No terminado
            error       <= 1'b0;               // Sin error
            words_total <= 8'd0;               // Limpia número de palabras
            word_index  <= 8'd0;               // Limpia índice de palabra
            byte_index  <= 2'd0;               // Limpia índice de byte
            word_buf    <= 32'd0;              // Limpia buffer

        end else begin                         // Funcionamiento normal
            prog_we <= 1'b0;                   // prog_we es un pulso de un ciclo

            if (!enable) begin                 // Si el loader está deshabilitado
                state       <= ST_WAIT_SYNC;   // Reinicia FSM
                done        <= 1'b0;           // Limpia done
                error       <= 1'b0;           // Limpia error
                words_total <= 8'd0;           // Limpia contador total
                word_index  <= 8'd0;           // Limpia índice de palabra
                byte_index  <= 2'd0;           // Limpia índice de byte
                word_buf    <= 32'd0;          // Limpia palabra parcial

            end else begin                     // Loader habilitado

                if (rx_framing_error) begin    // Si UART detecta error de trama
                    state <= ST_ERROR;         // Entra en error
                    error <= 1'b1;             // Marca error
                    done  <= 1'b0;             // No se considera terminado

                end else begin                 // Si no hay error UART
                    case (state)

                        ST_WAIT_SYNC: begin             // Espera byte de sync
                            done       <= 1'b0;         // Asegura done bajo
                            error      <= 1'b0;         // Asegura error bajo
                            word_index <= 8'd0;         // Reinicia índice de palabra
                            byte_index <= 2'd0;         // Reinicia índice de byte

                            if (rx_valid) begin         // Si llegó un byte
                                if (rx_data == SYNC_BYTE) begin // Si es 0x55
                                    state <= ST_WAIT_N;  // Pasa a recibir N
                                end
                            end
                        end

                        ST_WAIT_N: begin                // Espera número de palabras
                            if (rx_valid) begin         // Si llegó byte N
                                words_total <= rx_data; // Guarda número total
                                word_index  <= 8'd0;    // Empieza en palabra 0
                                byte_index  <= 2'd0;    // Empieza en byte 0
                                word_buf    <= 32'd0;   // Limpia buffer

                                if (rx_data == 8'd0) begin // Si N=0
                                    state <= ST_DONE;   // Termina inmediatamente
                                    done  <= 1'b1;      // Señaliza done
                                end else begin
                                    state <= ST_RECV_DATA; // Si N>0, recibe datos
                                end
                            end
                        end

                        ST_RECV_DATA: begin             // Recibe bytes de programa
                            if (rx_valid) begin         // Solo actúa con byte válido
                                case (byte_index)

                                    2'd0: begin         // Primer byte de palabra
                                        word_buf[7:0] <= rx_data; // Guarda bits 7:0
                                        byte_index    <= 2'd1;    // Siguiente byte
                                    end

                                    2'd1: begin         // Segundo byte de palabra
                                        word_buf[15:8] <= rx_data; // Guarda bits 15:8
                                        byte_index     <= 2'd2;    // Siguiente byte
                                    end

                                    2'd2: begin         // Tercer byte de palabra
                                        word_buf[23:16] <= rx_data; // Guarda bits 23:16
                                        byte_index      <= 2'd3;    // Siguiente byte
                                    end

                                    2'd3: begin         // Cuarto byte de palabra
                                        prog_addr  <= word_index; // Dirección de palabra en IMEM
                                        prog_wdata <= {rx_data, word_buf[23:0]}; // Forma palabra completa
                                        prog_we    <= 1'b1;       // Pulso de escritura

                                        byte_index <= 2'd0;       // Reinicia byte_index
                                        word_buf   <= 32'd0;      // Limpia buffer temporal

                                        if (word_index == words_total - 8'd1) begin // Si era la última palabra
                                            state <= ST_DONE;     // Termina carga
                                            done  <= 1'b1;        // Señaliza done
                                        end else begin
                                            word_index <= word_index + 8'd1; // Avanza palabra
                                        end
                                    end

                                    default: begin       // Protección
                                        byte_index <= 2'd0; // Reinicia byte index
                                    end
                                endcase
                            end
                        end

                        ST_DONE: begin                  // Estado final correcto
                            done <= 1'b1;               // Mantiene done activo
                        end

                        ST_ERROR: begin                 // Estado de error
                            error <= 1'b1;              // Mantiene error activo
                            done  <= 1'b0;              // No permite arranque correcto
                        end

                        default: begin                  // Protección ante estado inválido
                            state <= ST_WAIT_SYNC;      // Vuelve al inicio
                        end

                    endcase
                end
            end
        end
    end

endmodule