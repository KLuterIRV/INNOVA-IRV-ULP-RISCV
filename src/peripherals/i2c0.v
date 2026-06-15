`default_nettype none

module i2c0 (
    input  wire       clk,
    input  wire       rst,

    input  wire [7:0] ctrl,
    output wire [7:0] status,

    input  wire       scl_in,
    input  wire       sda_in,

    output wire       scl_out,
    output wire       scl_oe,

    output wire       sda_out,
    output wire       sda_oe
);

    // Minimal open-drain I2C control.
    //
    // ctrl[0] = 1 -> drive SCL low
    // ctrl[1] = 1 -> drive SDA low
    //
    // To release the line, set the corresponding ctrl bit to 0.
    // External pull-ups are expected on the real board.

    wire scl_drive_low;
    wire sda_drive_low;

    assign scl_drive_low = ctrl[0];
    assign sda_drive_low = ctrl[1];

    assign scl_out = 1'b0;
    assign sda_out = 1'b0;

    assign scl_oe = scl_drive_low;
    assign sda_oe = sda_drive_low;

    // status[0] = sampled SCL
    // status[1] = sampled SDA
    // status[2] = SCL drive-low control
    // status[3] = SDA drive-low control
    assign status = {4'd0, sda_drive_low, scl_drive_low, sda_in, scl_in};

    // Keep clk/rst intentionally present for future FSM upgrade.
    wire unused_clk;
    wire unused_rst;

    assign unused_clk = clk;
    assign unused_rst = rst;

endmodule

`default_nettype wire
