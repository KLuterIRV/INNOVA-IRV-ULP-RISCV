`default_nettype none

module gf180mcu_fd_ip_sram__sram64x8m8wm1 (
    input  wire       CLK,
    input  wire       CEN,
    input  wire       GWEN,
    input  wire [7:0] WEN,
    input  wire [5:0] A,
    input  wire [7:0] D,
    output wire [7:0] Q
);

`ifdef SIM

    reg [7:0] mem [0:63];
    reg [7:0] q_reg;

    assign Q = q_reg;

    integer i;

    initial begin
        q_reg = 8'd0;
        for (i = 0; i < 64; i = i + 1) begin
            mem[i] = 8'd0;
        end
    end

    always @(posedge CLK) begin
        if (!CEN) begin
            if (!GWEN) begin
                if (!WEN[0]) mem[A][0] <= D[0];
                if (!WEN[1]) mem[A][1] <= D[1];
                if (!WEN[2]) mem[A][2] <= D[2];
                if (!WEN[3]) mem[A][3] <= D[3];
                if (!WEN[4]) mem[A][4] <= D[4];
                if (!WEN[5]) mem[A][5] <= D[5];
                if (!WEN[6]) mem[A][6] <= D[6];
                if (!WEN[7]) mem[A][7] <= D[7];
            end

            q_reg <= mem[A];
        end
    end

`else

    // Physical macro blackbox.
    // The real implementation is provided by:
    //   - LEF for floorplanning/routing
    //   - GDS for streamout
    //   - LIB for timing
    //   - CDL for LVS/signoff
    //
    // No behavioral logic here during synthesis.

`endif

endmodule

`default_nettype wire