`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_regfile
// -----------------------------------------------------------------------------
// Description:
//   Minimal physical register file for the current TinyTapeout RISC-V core.
//
// Current implementation:
//   - x0 is hardwired to zero.
//   - x1 to x8 are implemented as 32-bit physical registers.
//   - Unsupported registers read as zero.
//   - Writes to unsupported registers are ignored.
//
// Why this is still intentionally small:
//   A full RV32E register file would contain x0-x15. In this TinyTapeout tile,
//   we are growing the CPU progressively and monitoring area/routing impact
//   after each step.
//
// Future growth:
//   - Later consider x1-x15 if the area/routing budget allows it.
// -----------------------------------------------------------------------------

module irv_regfile (
    input  wire        clk,
    input  wire        rst,

    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    output reg  [31:0] rs1_val,
    output reg  [31:0] rs2_val,

    input  wire        rd_we,
    input  wire [4:0]  rd,
    input  wire [31:0] rd_wdata
);

    reg [31:0] x1;
    reg [31:0] x2;
    reg [31:0] x3;
    reg [31:0] x4;
    reg [31:0] x5;
    reg [31:0] x6;
    reg [31:0] x7;
    reg [31:0] x8;

    // ---------------------------------------------------------------------
    // Combinational read ports
    // ---------------------------------------------------------------------

    always @(*) begin
        case (rs1)
            5'd0: rs1_val = 32'd0;
            5'd1: rs1_val = x1;
            5'd2: rs1_val = x2;
            5'd3: rs1_val = x3;
            5'd4: rs1_val = x4;
            5'd5: rs1_val = x5;
            5'd6: rs1_val = x6;
            5'd7: rs1_val = x7;
            5'd8: rs1_val = x8;
            default: rs1_val = 32'd0;
        endcase
    end

    always @(*) begin
        case (rs2)
            5'd0: rs2_val = 32'd0;
            5'd1: rs2_val = x1;
            5'd2: rs2_val = x2;
            5'd3: rs2_val = x3;
            5'd4: rs2_val = x4;
            5'd5: rs2_val = x5;
            5'd6: rs2_val = x6;
            5'd7: rs2_val = x7;
            5'd8: rs2_val = x8;
            default: rs2_val = 32'd0;
        endcase
    end

    // ---------------------------------------------------------------------
    // Synchronous write port
    // ---------------------------------------------------------------------

    always @(posedge clk) begin
        if (rst) begin
            x1 <= 32'd0;
            x2 <= 32'd0;
            x3 <= 32'd0;
            x4 <= 32'd0;
            x5 <= 32'd0;
            x6 <= 32'd0;
            x7 <= 32'd0;
            x8 <= 32'd0;
        end else if (rd_we) begin
            case (rd)
                5'd1: x1 <= rd_wdata;
                5'd2: x2 <= rd_wdata;
                5'd3: x3 <= rd_wdata;
                5'd4: x4 <= rd_wdata;
                5'd5: x5 <= rd_wdata;
                5'd6: x6 <= rd_wdata;
                5'd7: x7 <= rd_wdata;
                5'd8: x8 <= rd_wdata;
                default: begin end
            endcase
        end
    end

endmodule

`default_nettype wire
