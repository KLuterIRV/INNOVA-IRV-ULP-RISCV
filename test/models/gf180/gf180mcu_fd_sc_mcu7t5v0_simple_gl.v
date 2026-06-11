// Simple GF180 MCU7T5V0 functional models for Icarus GL simulation
// Generated from PDK cell declarations, with VNW/VPW added for powered netlists.
// Do not use for synthesis, timing signoff, LVS, or physical implementation.

`timescale 1ns / 1ps

module gf180mcu_fd_sc_mcu7t5v0__addf_1(S, A, CI, B, CO, VDD, VNW, VPW, VSS);
  input A, CI, B, VDD, VNW, VPW, VSS;
  output S, CO;
  assign S = 1'b0;
  assign CO = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__addf_2(S, A, CI, B, CO, VDD, VNW, VPW, VSS);
  input A, CI, B, VDD, VNW, VPW, VSS;
  output S, CO;
  assign S = 1'b0;
  assign CO = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__addf_4(S, A, CI, B, CO, VDD, VNW, VPW, VSS);
  input A, CI, B, VDD, VNW, VPW, VSS;
  output S, CO;
  assign S = 1'b0;
  assign CO = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__addh_1(CO, A, B, S, VDD, VNW, VPW, VSS);
  input A, B, VDD, VNW, VPW, VSS;
  output CO, S;
  assign CO = 1'b0;
  assign S = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__addh_2(CO, A, B, S, VDD, VNW, VPW, VSS);
  input A, B, VDD, VNW, VPW, VSS;
  output CO, S;
  assign CO = 1'b0;
  assign S = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__addh_4(A, B, CO, S, VDD, VNW, VPW, VSS);
  input A, B, VDD, VNW, VPW, VSS;
  output CO, S;
  assign CO = 1'b0;
  assign S = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and2_1(A1, A2, Z, VDD, VNW, VPW, VSS);
  input A1, A2, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and2_2(A1, A2, Z, VDD, VNW, VPW, VSS);
  input A1, A2, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and2_4(A2, A1, Z, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and3_1(A1, A2, A3, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2 & A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and3_2(A1, A2, A3, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2 & A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and3_4(A3, A2, A1, Z, VDD, VNW, VPW, VSS);
  input A3, A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2 & A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and4_1(A1, A2, A3, A4, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, A4, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2 & A3 & A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and4_2(A1, A2, A3, A4, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, A4, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2 & A3 & A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and4_4(A4, A3, A1, A2, Z, VDD, VNW, VPW, VSS);
  input A4, A3, A1, A2, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 & A2 & A3 & A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__antenna(I, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi211_1(A2, ZN, A1, B, C, VDD, VNW, VPW, VSS);
  input A2, A1, B, C, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi211_2(A2, A1, ZN, B, C, VDD, VNW, VPW, VSS);
  input A2, A1, B, C, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi211_4(ZN, A2, A1, B, C, VDD, VNW, VPW, VSS);
  input A2, A1, B, C, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi21_1(A2, ZN, A1, B, VDD, VNW, VPW, VSS);
  input A2, A1, B, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi21_2(B, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input B, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi21_4(A2, A1, ZN, B, VDD, VNW, VPW, VSS);
  input A2, A1, B, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi221_1(B2, B1, ZN, C, A2, A1, VDD, VNW, VPW, VSS);
  input B2, B1, C, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi221_2(ZN, B2, C, B1, A1, A2, VDD, VNW, VPW, VSS);
  input B2, C, B1, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi221_4(ZN, B2, B1, C, A1, A2, VDD, VNW, VPW, VSS);
  input B2, B1, C, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi222_1(C2, C1, B1, ZN, B2, A2, A1, VDD, VNW, VPW, VSS);
  input C2, C1, B1, B2, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi222_2(ZN, C2, C1, B2, B1, A1, A2, VDD, VNW, VPW, VSS);
  input C2, C1, B2, B1, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi222_4(ZN, C2, C1, B1, B2, A2, A1, VDD, VNW, VPW, VSS);
  input C2, C1, B1, B2, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi22_1(B2, B1, ZN, A1, A2, VDD, VNW, VPW, VSS);
  input B2, B1, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi22_2(B2, B1, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input B2, B1, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__aoi22_4(B2, B1, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input B2, B1, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_1(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_12(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_16(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_2(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_20(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_3(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_4(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_8(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__bufz_1(EN, I, Z, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__bufz_12(EN, I, Z, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__bufz_16(EN, I, Z, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__bufz_2(EN, I, Z, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__bufz_3(EN, I, Z, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__bufz_4(EN, I, Z, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__bufz_8(EN, I, Z, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_1(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_12(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_16(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_2(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_20(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_3(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_4(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_8(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_1(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_12(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_16(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_2(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_20(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_3(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_4(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_8(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnq_1(CLKN, D, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnq_2(CLKN, D, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnq_4(CLKN, D, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnrnq_1(CLKN, D, RN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnrnq_2(CLKN, D, RN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnrnq_4(CLKN, D, RN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnrsnq_1(CLKN, D, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, SETN, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnrsnq_2(CLKN, D, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, SETN, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnrsnq_4(CLKN, D, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, SETN, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnsnq_1(CLKN, D, SETN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, SETN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnsnq_2(CLKN, D, SETN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, SETN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffnsnq_4(CLKN, D, SETN, Q, VDD, VNW, VPW, VSS);
  input CLKN, D, SETN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffq_1(CLK, D, Q, VDD, VNW, VPW, VSS);
  input CLK, D, VDD, VNW, VPW, VSS;
  output reg Q;
  always @(posedge CLK) begin
    Q <= D;
  end
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffq_2(CLK, D, Q, VDD, VNW, VPW, VSS);
  input CLK, D, VDD, VNW, VPW, VSS;
  output reg Q;
  always @(posedge CLK) begin
    Q <= D;
  end
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffq_4(CLK, D, Q, VDD, VNW, VPW, VSS);
  input CLK, D, VDD, VNW, VPW, VSS;
  output reg Q;
  always @(posedge CLK) begin
    Q <= D;
  end
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffrnq_1(CLK, D, RN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffrnq_2(CLK, D, RN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffrnq_4(CLK, D, RN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffrsnq_1(CLK, D, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, SETN, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffrsnq_2(CLK, D, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, SETN, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffrsnq_4(CLK, D, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, SETN, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffsnq_1(CLK, D, SETN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, SETN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffsnq_2(CLK, D, SETN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, SETN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffsnq_4(CLK, D, SETN, Q, VDD, VNW, VPW, VSS);
  input CLK, D, SETN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlya_1(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlya_2(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlya_4(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyb_1(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyb_2(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyb_4(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyc_1(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyc_2(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyc_4(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyd_1(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyd_2(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyd_4(I, Z, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__endcap(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_1(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_16(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_2(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_32(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_4(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_64(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_8(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_16(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_32(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_4(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_64(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_8(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__filltie(VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__hold(Z, VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__icgtn_1(TE, E, CLKN, Q, VDD, VNW, VPW, VSS);
  input TE, E, CLKN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__icgtn_2(TE, E, CLKN, Q, VDD, VNW, VPW, VSS);
  input TE, E, CLKN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__icgtn_4(TE, E, CLKN, Q, VDD, VNW, VPW, VSS);
  input TE, E, CLKN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__icgtp_1(TE, E, CLK, Q, VDD, VNW, VPW, VSS);
  input TE, E, CLK, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__icgtp_2(TE, E, CLK, Q, VDD, VNW, VPW, VSS);
  input TE, E, CLK, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__icgtp_4(TE, E, CLK, Q, VDD, VNW, VPW, VSS);
  input TE, E, CLK, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_1(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_12(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_16(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_2(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_20(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_3(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_4(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__inv_8(I, ZN, VDD, VNW, VPW, VSS);
  input I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = ~I;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__invz_1(EN, ZN, I, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__invz_12(EN, I, ZN, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__invz_16(EN, I, ZN, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__invz_2(EN, ZN, I, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__invz_3(EN, I, ZN, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__invz_4(EN, I, ZN, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__invz_8(EN, I, ZN, VDD, VNW, VPW, VSS);
  input EN, I, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latq_1(E, D, Q, VDD, VNW, VPW, VSS);
  input E, D, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latq_2(E, D, Q, VDD, VNW, VPW, VSS);
  input E, D, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latq_4(E, D, Q, VDD, VNW, VPW, VSS);
  input E, D, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latrnq_1(E, D, RN, Q, VDD, VNW, VPW, VSS);
  input E, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latrnq_2(E, D, RN, Q, VDD, VNW, VPW, VSS);
  input E, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latrnq_4(E, D, RN, Q, VDD, VNW, VPW, VSS);
  input E, D, RN, VDD, VNW, VPW, VSS;
  output reg Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latrsnq_1(E, D, RN, SETN, Q, VDD, VNW, VPW, VSS);
  input E, D, RN, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latrsnq_2(E, D, RN, SETN, Q, VDD, VNW, VPW, VSS);
  input E, D, RN, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latrsnq_4(E, D, RN, SETN, Q, VDD, VNW, VPW, VSS);
  input E, D, RN, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latsnq_1(E, D, SETN, Q, VDD, VNW, VPW, VSS);
  input E, D, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latsnq_2(E, D, SETN, Q, VDD, VNW, VPW, VSS);
  input E, D, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__latsnq_4(E, D, SETN, Q, VDD, VNW, VPW, VSS);
  input E, D, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__mux2_1(Z, I1, S, I0, VDD, VNW, VPW, VSS);
  input I1, I0, VDD, VNW, VPW, VSS;
  output Z, S;
  assign Z = S ? I1 : I0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__mux2_2(Z, I1, S, I0, VDD, VNW, VPW, VSS);
  input I1, I0, VDD, VNW, VPW, VSS;
  output Z, S;
  assign Z = S ? I1 : I0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__mux2_4(Z, I1, S, I0, VDD, VNW, VPW, VSS);
  input I1, I0, VDD, VNW, VPW, VSS;
  output Z, S;
  assign Z = S ? I1 : I0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__mux4_1(I2, S0, I3, Z, S1, I1, I0, VDD, VNW, VPW, VSS);
  input I2, S0, I3, S1, I1, I0, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__mux4_2(I2, S0, I3, Z, S1, I1, I0, VDD, VNW, VPW, VSS);
  input I2, S0, I3, S1, I1, I0, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__mux4_4(I2, S0, I3, Z, S1, I1, I0, VDD, VNW, VPW, VSS);
  input I2, S0, I3, S1, I1, I0, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b0;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand2_1(A2, A1, ZN, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand2_2(A1, A2, ZN, VDD, VNW, VPW, VSS);
  input A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand2_4(A1, A2, ZN, VDD, VNW, VPW, VSS);
  input A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand3_1(A3, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2 & A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand3_2(ZN, A3, A2, A1, VDD, VNW, VPW, VSS);
  input A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2 & A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand3_4(A2, ZN, A3, A1, VDD, VNW, VPW, VSS);
  input A2, A3, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2 & A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand4_1(A4, ZN, A3, A2, A1, VDD, VNW, VPW, VSS);
  input A4, A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2 & A3 & A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand4_2(ZN, A3, A1, A4, A2, VDD, VNW, VPW, VSS);
  input A3, A1, A4, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2 & A3 & A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nand4_4(A3, ZN, A4, A1, A2, VDD, VNW, VPW, VSS);
  input A3, A4, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 & A2 & A3 & A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor2_1(A2, ZN, A1, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor2_2(A2, ZN, A1, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor2_4(ZN, A2, A1, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor3_1(A3, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2 | A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor3_2(ZN, A3, A2, A1, VDD, VNW, VPW, VSS);
  input A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2 | A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor3_4(A2, ZN, A3, A1, VDD, VNW, VPW, VSS);
  input A2, A3, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2 | A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor4_1(A4, ZN, A3, A2, A1, VDD, VNW, VPW, VSS);
  input A4, A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2 | A3 | A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor4_2(A4, A3, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input A4, A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2 | A3 | A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__nor4_4(A4, A3, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input A4, A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 | A2 | A3 | A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai211_1(A2, ZN, A1, B, C, VDD, VNW, VPW, VSS);
  input A2, A1, B, C, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai211_2(A2, ZN, A1, B, C, VDD, VNW, VPW, VSS);
  input A2, A1, B, C, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai211_4(A2, ZN, A1, B, C, VDD, VNW, VPW, VSS);
  input A2, A1, B, C, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai21_1(A2, ZN, A1, B, VDD, VNW, VPW, VSS);
  input A2, A1, B, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai21_2(B, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input B, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai21_4(A2, ZN, A1, B, VDD, VNW, VPW, VSS);
  input A2, A1, B, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai221_1(B2, B1, C, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input B2, B1, C, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai221_2(B2, B1, ZN, C, A1, A2, VDD, VNW, VPW, VSS);
  input B2, B1, C, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai221_4(ZN, B1, B2, C, A1, A2, VDD, VNW, VPW, VSS);
  input B1, B2, C, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai222_1(C2, C1, B1, ZN, B2, A2, A1, VDD, VNW, VPW, VSS);
  input C2, C1, B1, B2, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai222_2(ZN, C1, C2, B1, B2, A1, A2, VDD, VNW, VPW, VSS);
  input C1, C2, B1, B2, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai222_4(C1, ZN, C2, B1, B2, A1, A2, VDD, VNW, VPW, VSS);
  input C1, C2, B1, B2, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai22_1(B2, B1, ZN, A1, A2, VDD, VNW, VPW, VSS);
  input B2, B1, A1, A2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai22_2(B2, B1, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input B2, B1, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai22_4(B2, B1, ZN, A2, A1, VDD, VNW, VPW, VSS);
  input B2, B1, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai31_1(B, A1, ZN, A2, A3, VDD, VNW, VPW, VSS);
  input B, A1, A2, A3, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai31_2(B, ZN, A3, A2, A1, VDD, VNW, VPW, VSS);
  input B, A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai31_4(A3, ZN, A1, A2, B, VDD, VNW, VPW, VSS);
  input A3, A1, A2, B, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai32_1(A3, A2, A1, ZN, B1, B2, VDD, VNW, VPW, VSS);
  input A3, A2, A1, B1, B2, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai32_2(A3, A2, A1, ZN, B2, B1, VDD, VNW, VPW, VSS);
  input A3, A2, A1, B2, B1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai32_4(A2, A3, A1, ZN, B2, B1, VDD, VNW, VPW, VSS);
  input A2, A3, A1, B2, B1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai33_1(B3, B2, B1, ZN, A1, A2, A3, VDD, VNW, VPW, VSS);
  input B3, B2, B1, A1, A2, A3, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai33_2(B3, B2, ZN, B1, A3, A2, A1, VDD, VNW, VPW, VSS);
  input B3, B2, B1, A3, A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__oai33_4(B2, B3, B1, ZN, A1, A2, A3, VDD, VNW, VPW, VSS);
  input B2, B3, B1, A1, A2, A3, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or2_1(A1, A2, Z, VDD, VNW, VPW, VSS);
  input A1, A2, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or2_2(A1, A2, Z, VDD, VNW, VPW, VSS);
  input A1, A2, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or2_4(A2, A1, Z, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or3_1(A1, A2, A3, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2 | A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or3_2(A1, A2, A3, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2 | A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or3_4(A3, A2, A1, Z, VDD, VNW, VPW, VSS);
  input A3, A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2 | A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or4_1(A1, A2, A3, A4, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, A4, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2 | A3 | A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or4_2(A1, A2, A3, A4, Z, VDD, VNW, VPW, VSS);
  input A1, A2, A3, A4, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2 | A3 | A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__or4_4(A4, A3, A2, A1, Z, VDD, VNW, VPW, VSS);
  input A4, A3, A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 | A2 | A3 | A4;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffq_1(SE, SI, D, CLK, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffq_2(SE, SI, D, CLK, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffq_4(SE, SI, D, CLK, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffrnq_1(SE, SI, D, CLK, RN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, RN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffrnq_2(SE, SI, D, CLK, RN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, RN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffrnq_4(SE, SI, D, CLK, RN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, RN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffrsnq_1(SE, SI, D, CLK, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, SETN, RN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffrsnq_2(SE, SI, D, CLK, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, SETN, RN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffrsnq_4(SE, SI, D, CLK, SETN, RN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, SETN, RN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffsnq_1(SE, SI, D, CLK, SETN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffsnq_2(SE, SI, D, CLK, SETN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__sdffsnq_4(SE, SI, D, CLK, SETN, Q, VDD, VNW, VPW, VSS);
  input SE, SI, D, CLK, SETN, VDD, VNW, VPW, VSS;
  output Q;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__tieh(Z, VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
  output Z;
  assign Z = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__tiel(ZN, VDD, VNW, VPW, VSS);
  input VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = 1'b1;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xnor2_1(A2, A1, ZN, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 ^ A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xnor2_2(A2, A1, ZN, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 ^ A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xnor2_4(A2, A1, ZN, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 ^ A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xnor3_1(A2, A1, A3, ZN, VDD, VNW, VPW, VSS);
  input A2, A1, A3, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 ^ A2 ^ A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xnor3_2(A2, A1, A3, ZN, VDD, VNW, VPW, VSS);
  input A2, A1, A3, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 ^ A2 ^ A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xnor3_4(A2, A1, A3, ZN, VDD, VNW, VPW, VSS);
  input A2, A1, A3, VDD, VNW, VPW, VSS;
  output ZN;
  assign ZN = A1 ^ A2 ^ A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xor2_1(A2, A1, Z, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 ^ A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xor2_2(A2, A1, Z, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 ^ A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xor2_4(A2, A1, Z, VDD, VNW, VPW, VSS);
  input A2, A1, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 ^ A2;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xor3_1(A2, A1, A3, Z, VDD, VNW, VPW, VSS);
  input A2, A1, A3, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 ^ A2 ^ A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xor3_2(A2, A1, A3, Z, VDD, VNW, VPW, VSS);
  input A2, A1, A3, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 ^ A2 ^ A3;
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xor3_4(A2, A1, A3, Z, VDD, VNW, VPW, VSS);
  input A2, A1, A3, VDD, VNW, VPW, VSS;
  output Z;
  assign Z = A1 ^ A2 ^ A3;
endmodule

