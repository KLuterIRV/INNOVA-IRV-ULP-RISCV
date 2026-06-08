// ============================================================
// Module: soc_top
// ------------------------------------------------------------
// Top level del sistema.
// Este módulo conecta:
//   - el loader por UART
//   - el core RV32E
//   - las señales externas del sistema
//
// Función:
//   1. Si boot_mode = 1, el loader recibe un programa por UART
//      y lo escribe en la memoria de programa.
//   2. Cuando termina, loader_done = 1.
//   3. El core comienza a ejecutar desde la dirección 0.
//
// Señales externas:
//   - uart0_rx : entrada UART
//   - uart0_tx : salida UART
//   - gpio_out : salida física compartida GPIO / 7 segmentos
//   - sevenseg_out : patrón decodificado del display
// ============================================================

module soc_top (
    input  wire        clk,                // Reloj principal del sistema
    input  wire        rst,                // Reset del sistema
    input  wire        boot_mode,          // 1 = habilita modo carga por UART
    input  wire        uart0_rx,           // Entrada serie UART RX

    output wire [7:0]  gpio_out,           // Salida física compartida
    output wire [7:0]  sevenseg_out,       // Patrón del 7 segmentos para debug
    output wire        uart0_tx,           // Salida serie UART TX

    output wire [31:0] pc_debug,           // PC del core para depuración
    output wire [31:0] instr_debug,        // Instrucción actual para depuración
    output wire        halted_debug,       // Indica si el core está parado por ebreak
    output wire        loader_done_debug,  // Indica que el loader terminó
    output wire        loader_error_debug  // Indica error en el loader
);

    // Señales internas entre loader e IMEM del core
    wire        imem_prog_we;              // Write enable de programación de IMEM
    wire [7:0]  imem_prog_addr;            // Dirección de palabra a programar
    wire [31:0] imem_prog_wdata;           // Dato de 32 bits a escribir en IMEM
    wire        loader_done;               // Loader terminó correctamente
    wire        loader_error;              // Loader terminó con error

    // ------------------------------------------------------------
    // Instancia del loader por UART
    // ------------------------------------------------------------
    uart_loader #(
        .CLK_FREQ_HZ(60000000),            // Frecuencia del sistema: 60 MHz
        .BAUD_RATE  (115200)               // Baudrate de la UART
    ) u_uart_loader (
        .clk         (clk),                // Reloj
        .rst         (rst),                // Reset
        .enable      (boot_mode),          // Solo funciona si boot_mode = 1
        .uart_rx_i   (uart0_rx),           // Entrada UART física
        .prog_we     (imem_prog_we),       // Escribe en memoria de programa
        .prog_addr   (imem_prog_addr),     // Dirección de programación
        .prog_wdata  (imem_prog_wdata),    // Dato de programación
        .done        (loader_done),        // Fin correcto
        .error       (loader_error)        // Error detectado
    );

    // ------------------------------------------------------------
    // Instancia del core RV32E
    // ------------------------------------------------------------
    core u_core (
        .clk             (clk),            // Reloj
        .rst             (rst),            // Reset
        .uart0_rx        (uart0_rx),       // UART RX también entra al core/periféricos
        .boot_mode       (boot_mode),      // Modo boot
        .imem_prog_we    (imem_prog_we),   // Escritura de programa a IMEM
        .imem_prog_addr  (imem_prog_addr), // Dirección de programación
        .imem_prog_wdata (imem_prog_wdata),// Dato de programación
        .loader_done     (loader_done),    // El core arranca cuando loader_done = 1
        .pc_debug        (pc_debug),       // PC para debug
        .instr_debug     (instr_debug),    // Instrucción para debug
        .out_reg         (gpio_out),       // Salida física compartida
        .sevenseg_out    (sevenseg_out),   // Patrón del 7 segmentos
        .uart0_tx        (uart0_tx),       // UART TX hacia exterior
        .halted_debug    (halted_debug)    // Estado halted del core
    );

    // ------------------------------------------------------------
    // Señales de debug del loader
    // ------------------------------------------------------------
    assign loader_done_debug  = loader_done;   // Exporta done al exterior
    assign loader_error_debug = loader_error;  // Exporta error al exterior

endmodule