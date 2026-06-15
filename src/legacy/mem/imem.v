// ============================================================
// Module: imem
// ------------------------------------------------------------
// Small instruction memory for Tiny Tapeout flow.
//
// This version intentionally avoids Verilog memory arrays
// such as reg [31:0] mem [0:N-1] because the LibreLane/Yosys
// synth check reported multiple conflicting drivers on the
// inferred memory read port.
//
// Implementation:
//   - 64 explicit 32-bit instruction registers
//   - UART loader writes one 32-bit word at a time
//   - core fetches instruction using pc[7:2]
// ============================================================

`default_nettype none

module imem (
    input  wire        clk,

    input  wire [31:0] addr,
    output reg  [31:0] instr,

    input  wire        prog_we,
    input  wire [7:0]  prog_addr,
    input  wire [31:0] prog_wdata
);

    // ------------------------------------------------------------
    // Explicit instruction registers
    // ------------------------------------------------------------

    reg [31:0] imem_00;
    reg [31:0] imem_01;
    reg [31:0] imem_02;
    reg [31:0] imem_03;
    reg [31:0] imem_04;
    reg [31:0] imem_05;
    reg [31:0] imem_06;
    reg [31:0] imem_07;
    reg [31:0] imem_08;
    reg [31:0] imem_09;
    reg [31:0] imem_10;
    reg [31:0] imem_11;
    reg [31:0] imem_12;
    reg [31:0] imem_13;
    reg [31:0] imem_14;
    reg [31:0] imem_15;
    reg [31:0] imem_16;
    reg [31:0] imem_17;
    reg [31:0] imem_18;
    reg [31:0] imem_19;
    reg [31:0] imem_20;
    reg [31:0] imem_21;
    reg [31:0] imem_22;
    reg [31:0] imem_23;
    reg [31:0] imem_24;
    reg [31:0] imem_25;
    reg [31:0] imem_26;
    reg [31:0] imem_27;
    reg [31:0] imem_28;
    reg [31:0] imem_29;
    reg [31:0] imem_30;
    reg [31:0] imem_31;
    reg [31:0] imem_32;
    reg [31:0] imem_33;
    reg [31:0] imem_34;
    reg [31:0] imem_35;
    reg [31:0] imem_36;
    reg [31:0] imem_37;
    reg [31:0] imem_38;
    reg [31:0] imem_39;
    reg [31:0] imem_40;
    reg [31:0] imem_41;
    reg [31:0] imem_42;
    reg [31:0] imem_43;
    reg [31:0] imem_44;
    reg [31:0] imem_45;
    reg [31:0] imem_46;
    reg [31:0] imem_47;
    reg [31:0] imem_48;
    reg [31:0] imem_49;
    reg [31:0] imem_50;
    reg [31:0] imem_51;
    reg [31:0] imem_52;
    reg [31:0] imem_53;
    reg [31:0] imem_54;
    reg [31:0] imem_55;
    reg [31:0] imem_56;
    reg [31:0] imem_57;
    reg [31:0] imem_58;
    reg [31:0] imem_59;
    reg [31:0] imem_60;
    reg [31:0] imem_61;
    reg [31:0] imem_62;
    reg [31:0] imem_63;

    // ------------------------------------------------------------
    // Address handling
    // ------------------------------------------------------------

    wire [5:0] word_addr;

    assign word_addr = addr[7:2];

    wire _unused_imem_addr;
    assign _unused_imem_addr = &{addr[31:8], addr[1:0], prog_addr[7:6], 1'b0};

    // ------------------------------------------------------------
    // Program write port
    // ------------------------------------------------------------

    always @(posedge clk) begin
        if (prog_we) begin
            case (prog_addr[5:0])
                6'd0:  imem_00 <= prog_wdata;
                6'd1:  imem_01 <= prog_wdata;
                6'd2:  imem_02 <= prog_wdata;
                6'd3:  imem_03 <= prog_wdata;
                6'd4:  imem_04 <= prog_wdata;
                6'd5:  imem_05 <= prog_wdata;
                6'd6:  imem_06 <= prog_wdata;
                6'd7:  imem_07 <= prog_wdata;
                6'd8:  imem_08 <= prog_wdata;
                6'd9:  imem_09 <= prog_wdata;
                6'd10: imem_10 <= prog_wdata;
                6'd11: imem_11 <= prog_wdata;
                6'd12: imem_12 <= prog_wdata;
                6'd13: imem_13 <= prog_wdata;
                6'd14: imem_14 <= prog_wdata;
                6'd15: imem_15 <= prog_wdata;
                6'd16: imem_16 <= prog_wdata;
                6'd17: imem_17 <= prog_wdata;
                6'd18: imem_18 <= prog_wdata;
                6'd19: imem_19 <= prog_wdata;
                6'd20: imem_20 <= prog_wdata;
                6'd21: imem_21 <= prog_wdata;
                6'd22: imem_22 <= prog_wdata;
                6'd23: imem_23 <= prog_wdata;
                6'd24: imem_24 <= prog_wdata;
                6'd25: imem_25 <= prog_wdata;
                6'd26: imem_26 <= prog_wdata;
                6'd27: imem_27 <= prog_wdata;
                6'd28: imem_28 <= prog_wdata;
                6'd29: imem_29 <= prog_wdata;
                6'd30: imem_30 <= prog_wdata;
                6'd31: imem_31 <= prog_wdata;
                6'd32: imem_32 <= prog_wdata;
                6'd33: imem_33 <= prog_wdata;
                6'd34: imem_34 <= prog_wdata;
                6'd35: imem_35 <= prog_wdata;
                6'd36: imem_36 <= prog_wdata;
                6'd37: imem_37 <= prog_wdata;
                6'd38: imem_38 <= prog_wdata;
                6'd39: imem_39 <= prog_wdata;
                6'd40: imem_40 <= prog_wdata;
                6'd41: imem_41 <= prog_wdata;
                6'd42: imem_42 <= prog_wdata;
                6'd43: imem_43 <= prog_wdata;
                6'd44: imem_44 <= prog_wdata;
                6'd45: imem_45 <= prog_wdata;
                6'd46: imem_46 <= prog_wdata;
                6'd47: imem_47 <= prog_wdata;
                6'd48: imem_48 <= prog_wdata;
                6'd49: imem_49 <= prog_wdata;
                6'd50: imem_50 <= prog_wdata;
                6'd51: imem_51 <= prog_wdata;
                6'd52: imem_52 <= prog_wdata;
                6'd53: imem_53 <= prog_wdata;
                6'd54: imem_54 <= prog_wdata;
                6'd55: imem_55 <= prog_wdata;
                6'd56: imem_56 <= prog_wdata;
                6'd57: imem_57 <= prog_wdata;
                6'd58: imem_58 <= prog_wdata;
                6'd59: imem_59 <= prog_wdata;
                6'd60: imem_60 <= prog_wdata;
                6'd61: imem_61 <= prog_wdata;
                6'd62: imem_62 <= prog_wdata;
                6'd63: imem_63 <= prog_wdata;
                default: begin
                end
            endcase
        end
    end

    // ------------------------------------------------------------
    // Instruction read mux
    // ------------------------------------------------------------

    always @(*) begin
        case (word_addr)
            6'd0:  instr = imem_00;
            6'd1:  instr = imem_01;
            6'd2:  instr = imem_02;
            6'd3:  instr = imem_03;
            6'd4:  instr = imem_04;
            6'd5:  instr = imem_05;
            6'd6:  instr = imem_06;
            6'd7:  instr = imem_07;
            6'd8:  instr = imem_08;
            6'd9:  instr = imem_09;
            6'd10: instr = imem_10;
            6'd11: instr = imem_11;
            6'd12: instr = imem_12;
            6'd13: instr = imem_13;
            6'd14: instr = imem_14;
            6'd15: instr = imem_15;
            6'd16: instr = imem_16;
            6'd17: instr = imem_17;
            6'd18: instr = imem_18;
            6'd19: instr = imem_19;
            6'd20: instr = imem_20;
            6'd21: instr = imem_21;
            6'd22: instr = imem_22;
            6'd23: instr = imem_23;
            6'd24: instr = imem_24;
            6'd25: instr = imem_25;
            6'd26: instr = imem_26;
            6'd27: instr = imem_27;
            6'd28: instr = imem_28;
            6'd29: instr = imem_29;
            6'd30: instr = imem_30;
            6'd31: instr = imem_31;
            6'd32: instr = imem_32;
            6'd33: instr = imem_33;
            6'd34: instr = imem_34;
            6'd35: instr = imem_35;
            6'd36: instr = imem_36;
            6'd37: instr = imem_37;
            6'd38: instr = imem_38;
            6'd39: instr = imem_39;
            6'd40: instr = imem_40;
            6'd41: instr = imem_41;
            6'd42: instr = imem_42;
            6'd43: instr = imem_43;
            6'd44: instr = imem_44;
            6'd45: instr = imem_45;
            6'd46: instr = imem_46;
            6'd47: instr = imem_47;
            6'd48: instr = imem_48;
            6'd49: instr = imem_49;
            6'd50: instr = imem_50;
            6'd51: instr = imem_51;
            6'd52: instr = imem_52;
            6'd53: instr = imem_53;
            6'd54: instr = imem_54;
            6'd55: instr = imem_55;
            6'd56: instr = imem_56;
            6'd57: instr = imem_57;
            6'd58: instr = imem_58;
            6'd59: instr = imem_59;
            6'd60: instr = imem_60;
            6'd61: instr = imem_61;
            6'd62: instr = imem_62;
            6'd63: instr = imem_63;
            default: instr = 32'd0;
        endcase
    end

endmodule

`default_nettype wire