`default_nettype none

module i2c0 (
    input  wire       clk,
    input  wire       rst,

    // Register interface
    input  wire [7:0] ctrl_wr_data,
    input  wire       ctrl_we,

    input  wire [7:0] data_wr_data,
    input  wire       data_we,
    output wire [7:0] data_rd_data,

    input  wire [7:0] div_wr_data,
    input  wire       div_we,

    output wire [7:0] status,

    // I2C pins
    input  wire       scl_in,
    input  wire       sda_in,

    output wire       scl_out,
    output wire       scl_oe,

    output wire       sda_out,
    output wire       sda_oe
);

    // ---------------------------------------------------------------------
    // Register definitions
    // ---------------------------------------------------------------------
    //
    // CTRL write:
    //   bit 0 = START
    //   bit 1 = STOP
    //   bit 2 = WRITE_BYTE
    //   bit 3 = READ_BYTE
    //   bit 4 = READ_ACK_VALUE, 0 = ACK, 1 = NACK
    //
    // STATUS:
    //   bit 0 = busy
    //   bit 1 = done
    //   bit 2 = ack_error
    //   bit 3 = rx_valid
    //   bit 4 = scl_in
    //   bit 5 = sda_in

    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg [7:0] div_reg;

    reg busy;
    reg done;
    reg ack_error;
    reg rx_valid;

    assign data_rd_data = rx_data;

    assign status = {
        2'b00,
        sda_in,
        scl_in,
        rx_valid,
        ack_error,
        done,
        busy
    };

    // ---------------------------------------------------------------------
    // Open-drain pin control
    // ---------------------------------------------------------------------
    //
    // I2C lines are released for logic 1 and driven low for logic 0.
    // External pull-ups are expected on real hardware.

    reg scl_drive_low;
    reg sda_drive_low;

    assign scl_out = 1'b0;
    assign sda_out = 1'b0;

    assign scl_oe = scl_drive_low;
    assign sda_oe = sda_drive_low;

    // ---------------------------------------------------------------------
    // FSM
    // ---------------------------------------------------------------------

    localparam [3:0]
        S_IDLE        = 4'd0,

        S_START_A     = 4'd1,
        S_START_B     = 4'd2,

        S_WRITE_LOW   = 4'd3,
        S_WRITE_HIGH  = 4'd4,

        S_ACK_LOW     = 4'd5,
        S_ACK_HIGH    = 4'd6,

        S_READ_LOW    = 4'd7,
        S_READ_HIGH   = 4'd8,

        S_READ_ACK_L  = 4'd9,
        S_READ_ACK_H  = 4'd10,

        S_STOP_A      = 4'd11,
        S_STOP_B      = 4'd12,
        S_STOP_C      = 4'd13,

        S_DONE        = 4'd14;

    reg [3:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] shifter;

    reg cmd_start;
    reg cmd_stop;
    reg cmd_write;
    reg cmd_read;
    reg cmd_read_ack_value;

    wire tick;

    assign tick = (clk_count == {8'd0, div_reg});

    always @(posedge clk) begin
        if (rst) begin
            div_reg            <= 8'd8;
            tx_data            <= 8'd0;
            rx_data            <= 8'd0;

            busy               <= 1'b0;
            done               <= 1'b0;
            ack_error          <= 1'b0;
            rx_valid           <= 1'b0;

            scl_drive_low      <= 1'b0;
            sda_drive_low      <= 1'b0;

            state              <= S_IDLE;
            clk_count          <= 16'd0;
            bit_index          <= 3'd0;
            shifter            <= 8'd0;

            cmd_start          <= 1'b0;
            cmd_stop           <= 1'b0;
            cmd_write          <= 1'b0;
            cmd_read           <= 1'b0;
            cmd_read_ack_value <= 1'b1;
        end else begin
            // Default done is sticky until next command.
            if (data_we) begin
                tx_data <= data_wr_data;
            end

            if (div_we) begin
                div_reg <= div_wr_data;
            end

            if (ctrl_we && !busy) begin
                cmd_start          <= ctrl_wr_data[0];
                cmd_stop           <= ctrl_wr_data[1];
                cmd_write          <= ctrl_wr_data[2];
                cmd_read           <= ctrl_wr_data[3];
                cmd_read_ack_value <= ctrl_wr_data[4];

                busy               <= 1'b1;
                done               <= 1'b0;
                ack_error          <= 1'b0;
                rx_valid           <= 1'b0;

                clk_count          <= 16'd0;
                bit_index          <= 3'd7;
                shifter            <= data_wr_data;

                if (ctrl_wr_data[0]) begin
                    state <= S_START_A;
                end else if (ctrl_wr_data[2]) begin
                    shifter <= tx_data;
                    state   <= S_WRITE_LOW;
                end else if (ctrl_wr_data[3]) begin
                    shifter <= 8'd0;
                    state   <= S_READ_LOW;
                end else if (ctrl_wr_data[1]) begin
                    state <= S_STOP_A;
                end else begin
                    state <= S_DONE;
                end
            end else begin
                if (busy) begin
                    if (tick) begin
                        clk_count <= 16'd0;

                        case (state)

                            // START: SDA falls while SCL is released high.
                            S_START_A: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b0;
                                state         <= S_START_B;
                            end

                            S_START_B: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b1;

                                if (cmd_write) begin
                                    shifter   <= tx_data;
                                    bit_index <= 3'd7;
                                    state     <= S_WRITE_LOW;
                                end else if (cmd_read) begin
                                    shifter   <= 8'd0;
                                    bit_index <= 3'd7;
                                    state     <= S_READ_LOW;
                                end else if (cmd_stop) begin
                                    state <= S_STOP_A;
                                end else begin
                                    state <= S_DONE;
                                end
                            end

                            // WRITE byte, MSB first.
                            S_WRITE_LOW: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= ~shifter[bit_index];
                                state         <= S_WRITE_HIGH;
                            end

                            S_WRITE_HIGH: begin
                                scl_drive_low <= 1'b0;

                                if (bit_index == 3'd0) begin
                                    state <= S_ACK_LOW;
                                end else begin
                                    bit_index <= bit_index - 3'd1;
                                    state     <= S_WRITE_LOW;
                                end
                            end

                            // ACK bit from slave.
                            S_ACK_LOW: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0; // release SDA
                                state         <= S_ACK_HIGH;
                            end

                            S_ACK_HIGH: begin
                                scl_drive_low <= 1'b0;
                                ack_error     <= sda_in;

                                if (cmd_stop) begin
                                    state <= S_STOP_A;
                                end else begin
                                    state <= S_DONE;
                                end
                            end

                            // READ byte, MSB first.
                            S_READ_LOW: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0; // release SDA
                                state         <= S_READ_HIGH;
                            end

                            S_READ_HIGH: begin
                                scl_drive_low      <= 1'b0;
                                shifter[bit_index] <= sda_in;

                                if (bit_index == 3'd0) begin
                                    state <= S_READ_ACK_L;
                                end else begin
                                    bit_index <= bit_index - 3'd1;
                                    state     <= S_READ_LOW;
                                end
                            end

                            // Master ACK/NACK after read.
                            S_READ_ACK_L: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= cmd_read_ack_value; // 0 ACK, 1 NACK -> drive low if ACK
                                state         <= S_READ_ACK_H;
                            end

                            S_READ_ACK_H: begin
                                scl_drive_low <= 1'b0;
                                rx_data       <= shifter;
                                rx_valid      <= 1'b1;

                                if (cmd_stop) begin
                                    state <= S_STOP_A;
                                end else begin
                                    state <= S_DONE;
                                end
                            end

                            // STOP: SDA rises while SCL is high.
                            S_STOP_A: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                state         <= S_STOP_B;
                            end

                            S_STOP_B: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b1;
                                state         <= S_STOP_C;
                            end

                            S_STOP_C: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b0;
                                state         <= S_DONE;
                            end

                            S_DONE: begin
                                busy  <= 1'b0;
                                done  <= 1'b1;
                                state <= S_IDLE;
                            end

                            default: begin
                                state <= S_DONE;
                            end

                        endcase
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end
            end
        end
    end

endmodule

`default_nettype wire
