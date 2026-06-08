module dmem (                                      // Módulo de memoria de datos + periféricos memory-mapped
    input  wire        clk,                        // Reloj principal del sistema
    input  wire        rst,                        // Reset síncrono activo a nivel alto

    input  wire [31:0] addr,                       // Dirección calculada por la ALU para load/store
    input  wire [31:0] wdata,                      // Dato de escritura desde el core
    input  wire        we,                         // Write enable: 1 = store, 0 = load/read

    output wire [31:0] rdata,                      // Dato leído hacia el core

    input  wire        uart0_rx,                   // Entrada física UART RX
    output wire [7:0]  out_reg,                    // Salida física compartida: GPIO o 7 segmentos
    output wire [7:0]  sevenseg_out,               // Salida decodificada del 7 segmentos para debug/observación
    output wire        uart0_tx                    // Salida física UART TX
);

    // ============================================================
    // MEMORY MAP
    // ============================================================

    localparam GPIO_OUT_ADDR      = 32'h1000_0000; // Registro GPIO de salida normal
    localparam SEVENSEG_DATA_ADDR = 32'h1000_0004; // Registro de dato para 7 segmentos
    localparam SEVENSEG_CTRL_ADDR = 32'h1000_0008; // Registro de control del 7 segmentos
    localparam UART0_DATA_ADDR    = 32'h1000_0100; // Registro UART TX data
    localparam UART0_STATUS_ADDR  = 32'h1000_0104; // Registro UART status
    localparam UART0_RXDATA_ADDR  = 32'h1000_010C; // Registro UART RX data

    // ============================================================
    // INTERNAL DATA MEMORY
    // ============================================================

    reg [31:0] mem [0:255];                        // Memoria de datos interna: 256 words x 32 bits
    integer i;                                     // Variable auxiliar para inicialización/reset

    initial begin                                  // Inicialización de la memoria a cero
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    // ============================================================
    // GPIO + SEVEN SEGMENT SHARED OUTPUT
    // ============================================================

    reg [7:0] gpio_out_reg;                        // Registro GPIO normal de 8 bits
    reg [7:0] sevenseg_data;                       // Registro de dato enviado al decodificador 7 segmentos
    reg [7:0] sevenseg_ctrl;                       // Registro de control del periférico 7 segmentos

    wire [7:0] sevenseg_decoded;                   // Patrón ya decodificado para el 7 segmentos

    wire sevenseg_enable;                          // Enable del periférico 7 segmentos
    wire sevenseg_ascii_mode;                      // Modo ASCII: convierte códigos ASCII a 7 segmentos
    wire sevenseg_raw_mode;                        // Modo RAW: usa el patrón escrito directamente
    wire sevenseg_active_low;                      // Invierte la salida para displays active-low

    assign sevenseg_enable     = sevenseg_ctrl[0]; // CTRL bit 0: 1 = 7 segmentos toma la salida física
    assign sevenseg_ascii_mode = sevenseg_ctrl[1]; // CTRL bit 1: 1 = modo ASCII
    assign sevenseg_raw_mode   = sevenseg_ctrl[2]; // CTRL bit 2: 1 = modo RAW directo
    assign sevenseg_active_low = sevenseg_ctrl[3]; // CTRL bit 3: 1 = salida invertida active-low

    sevenseg u_sevenseg (                          // Instancia del decodificador configurable 7 segmentos
        .value      (sevenseg_data),               // Valor de entrada: HEX, ASCII o RAW según modo
        .ascii_mode (sevenseg_ascii_mode),         // Selección de modo ASCII
        .raw_mode   (sevenseg_raw_mode),           // Selección de modo RAW
        .active_low (sevenseg_active_low),         // Selección active-high / active-low
        .seg_out    (sevenseg_decoded)             // Patrón final del display
    );

    assign out_reg =                               // Salida física compartida
        sevenseg_enable ? sevenseg_decoded :       // Si sevenseg está habilitado, domina el display
                          gpio_out_reg;            // Si no, la salida funciona como GPIO normal

    assign sevenseg_out = sevenseg_decoded;        // Señal de debug: patrón de 7 segmentos siempre visible

    // ============================================================
    // UART TX
    // ============================================================

    reg        uart0_tx_start;                     // Pulso de arranque de transmisión UART TX
    reg [7:0]  uart0_tx_data;                      // Byte registrado que se enviará por UART TX
    wire       uart0_busy;                         // UART TX ocupada transmitiendo
    wire       uart0_done;                         // Pulso de fin de transmisión UART TX

    wire _unused_dmem;                             // Señal dummy para evitar advertencias de señales no conectadas
    assign _unused_dmem = &{uart0_done, 1'b0};     // Evita advertencia de uart0_done no conectado, aunque no se use en la lógica del dmem

    uart_tx #(                                    // Instancia UART TX
        .CLK_FREQ_HZ(60000000),                   // Frecuencia de reloj del sistema: 60 MHz
        .BAUD_RATE  (115200)                      // Baudrate UART: 115200 baudios
    ) u_uart_tx (
        .clk      (clk),                          // Reloj
        .rst      (rst),                          // Reset
        .tx_start (uart0_tx_start),               // Inicio de transmisión
        .tx_data  (uart0_tx_data),                // Byte a transmitir
        .tx       (uart0_tx),                     // Línea UART TX
        .busy     (uart0_busy),                   // Estado ocupado
        .done     (uart0_done)                    // Fin de transmisión
    );

    // ============================================================
    // UART RX
    // ============================================================

    wire [7:0] uart0_rx_data_raw;                 // Byte recibido directamente desde uart_rx
    wire       uart0_rx_valid_raw;                // Pulso de byte válido desde uart_rx
    wire       uart0_rx_busy;                     // UART RX ocupada recibiendo una trama
    wire       uart0_rx_framing_error_raw;        // Pulso de error de framing desde uart_rx

    reg [7:0]  uart0_rx_data_reg;                 // Registro latched del último byte recibido
    reg        uart0_rx_valid_latched;            // Flag latched: hay byte RX pendiente de leer
    reg        uart0_rx_framing_error_latched;    // Flag latched: hubo error de framing

    uart_rx #(                                    // Instancia UART RX
        .CLK_FREQ_HZ(60000000),                   // Frecuencia de reloj del sistema: 60 MHz
        .BAUD_RATE  (115200)                      // Baudrate UART: 115200 baudios
    ) u_uart_rx (
        .clk           (clk),                     // Reloj
        .rst           (rst),                     // Reset
        .rx            (uart0_rx),                // Línea UART RX
        .rx_data       (uart0_rx_data_raw),       // Byte recibido
        .rx_valid      (uart0_rx_valid_raw),      // Pulso de dato recibido válido
        .busy          (uart0_rx_busy),           // Estado ocupado recibiendo
        .framing_error (uart0_rx_framing_error_raw) // Error si stop bit no fue válido
    );

    // ============================================================
    // SEQUENTIAL LOGIC
    // ============================================================

    always @(posedge clk) begin                   // Toda la lógica secuencial se actualiza en flanco positivo
        if (rst) begin                            // Reset síncrono
            gpio_out_reg                 <= 8'd0; // Limpia GPIO normal
            sevenseg_data                <= 8'd0; // Limpia dato del 7 segmentos
            sevenseg_ctrl                <= 8'd0; // Deshabilita 7 segmentos por defecto

            uart0_tx_start               <= 1'b0; // No arrancar transmisión en reset
            uart0_tx_data                <= 8'd0; // Limpia dato TX

            uart0_rx_data_reg            <= 8'd0; // Limpia dato RX latched
            uart0_rx_valid_latched       <= 1'b0; // Limpia flag RX válido
            uart0_rx_framing_error_latched <= 1'b0; // Limpia flag de framing error
            
        end else begin                            // Funcionamiento normal
            uart0_tx_start <= 1'b0;               // Por defecto, TX start es un pulso de un ciclo

            // ----------------------------------------------------
            // UART RX capture
            // ----------------------------------------------------

            if (uart0_rx_valid_raw) begin         // Si UART RX ha recibido un byte válido
                uart0_rx_data_reg      <= uart0_rx_data_raw; // Guarda el byte recibido
                uart0_rx_valid_latched <= 1'b1;   // Marca que hay dato pendiente de lectura
            end

            if (uart0_rx_framing_error_raw) begin // Si UART RX detecta error de stop bit
                uart0_rx_framing_error_latched <= 1'b1; // Guarda el error hasta que software lo limpie
            end

            if (!we && addr == UART0_RXDATA_ADDR) begin // Si el core lee UART0_RXDATA
                uart0_rx_valid_latched         <= 1'b0; // Limpia flag de dato pendiente
                uart0_rx_framing_error_latched <= 1'b0; // Limpia flag de error asociado
            end

            // ----------------------------------------------------
            // CPU writes
            // ----------------------------------------------------

            if (we) begin                         // Si el core está haciendo un store
                if (addr == GPIO_OUT_ADDR) begin  // Escritura a GPIO_OUT
                    gpio_out_reg <= wdata[7:0];   // Guarda los 8 bits bajos como GPIO

                end else if (addr == SEVENSEG_DATA_ADDR) begin // Escritura a SEVENSEG_DATA
                    sevenseg_data <= wdata[7:0];  // Guarda dato para HEX/ASCII/RAW

                end else if (addr == SEVENSEG_CTRL_ADDR) begin // Escritura a SEVENSEG_CTRL
                    sevenseg_ctrl <= wdata[7:0];  // Configura enable/modo/active_low

                end else if (addr == UART0_DATA_ADDR) begin // Escritura a UART0_DATA
                    if (!uart0_busy) begin         // Solo acepta byte si TX está libre
                        uart0_tx_data  <= wdata[7:0]; // Registra byte a transmitir
                        uart0_tx_start <= 1'b1;    // Lanza transmisión UART
                    end

                end else begin                    // Si no es periférico, es memoria de datos normal
                    mem[addr[9:2]] <= wdata;      // Escribe word alineada en memoria interna
                end
            end
        end
    end

    // ============================================================
    // READ DATA MUX
    // ============================================================

    assign rdata =                                // Multiplexor de lectura memory-mapped
        (addr == GPIO_OUT_ADDR)      ? {24'd0, gpio_out_reg} : // Lee GPIO_OUT
        (addr == SEVENSEG_DATA_ADDR) ? {24'd0, sevenseg_data} : // Lee dato del 7 segmentos
        (addr == SEVENSEG_CTRL_ADDR) ? {24'd0, sevenseg_ctrl} : // Lee control del 7 segmentos
        (addr == UART0_STATUS_ADDR)  ? {27'd0,                    // Lee UART status
                                        uart0_rx_framing_error_latched, // bit 4: framing error
                                        uart0_rx_busy,                  // bit 3: RX busy
                                        uart0_rx_valid_latched,         // bit 2: RX valid
                                        !uart0_busy,                   // bit 1: TX ready
                                        uart0_busy} :                  // bit 0: TX busy
        (addr == UART0_RXDATA_ADDR)  ? {24'd0, uart0_rx_data_reg} : // Lee último byte recibido
                                       mem[addr[9:2]];              // Lee memoria de datos interna

endmodule