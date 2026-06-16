`default_nettype none

// -----------------------------------------------------------------------------
// Module: irv_fetch
// -----------------------------------------------------------------------------
// Description:
//   Instruction fetch helper for the INNOVA IRV RV32E core.
//
// SRAM timing:
//   - The GF180 SRAM behavioral blackbox is synchronous.
//   - Address is sampled on the rising clock edge.
//   - Q is updated with mem[A] on that same edge.
//   - Therefore, the CPU fetch sequence keeps the original 3-state timing:
//
//       S_ADDR_LO -> drive low halfword address
//       S_CAP_LO  -> capture low halfword, drive high halfword address
//       S_CAP_HI  -> capture high halfword and assemble 32-bit instruction
//
// This module does not advance the PC and does not control the CPU FSM.
// -----------------------------------------------------------------------------

module irv_fetch (
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] pc,

    input  wire        fetch_addr_lo,
    input  wire        fetch_cap_lo,
    input  wire        fetch_cap_hi,

    input  wire [15:0] sram_rhalf,

    output reg  [5:0]  sram_addr,
    output reg  [31:0] instr
);

    wire [5:0] pc_half_addr;
    wire [5:0] pc_half_addr_hi;

    assign pc_half_addr    = pc[6:1];
    assign pc_half_addr_hi = pc[6:1] + 6'd1;

    reg [15:0] instr_lo;

    always @(*) begin
        if (fetch_cap_lo) begin
            sram_addr = pc_half_addr_hi;
        end else begin
            sram_addr = pc_half_addr;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            instr_lo <= 16'd0;
            instr    <= 32'd0;
        end else begin
            if (fetch_cap_lo) begin
                instr_lo <= sram_rhalf;
            end

            if (fetch_cap_hi) begin
                instr <= {sram_rhalf, instr_lo};
            end
        end
    end

    // fetch_addr_lo is intentionally part of the interface to make the fetch
    // state explicit from the top-level FSM. The low-address path is also the
    // default address path.
    wire unused_fetch_addr_lo;
    assign unused_fetch_addr_lo = fetch_addr_lo;

endmodule

`default_nettype wire
