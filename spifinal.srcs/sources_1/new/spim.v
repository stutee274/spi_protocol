module spim (
    input  wire        clk,        // System clock
    input  wire        rst,        // Synchronous reset (active-high)

    input  wire [7:0]  data_in,    // Byte to transmit
    input  wire        start,      // Start transfer pulse

    output reg  [7:0]  data_out,   // Received byte
    output reg         busy,       // 1 during transfer
    output reg         cs_n,       // CS (active low)

    output reg         sclk,      // SPI clock
    output wire        mosi,       // Master Out
    input  wire        miso       // Master In
);

    // ------------------------------------------------------------------------------
    // Parameter
    // ------------------------------------------------------------------------------
    parameter CLK_DIV = 4; // clock division

    // ------------------------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------------------------
    reg [15:0] clk_cnt;
    reg [2:0] bit_cnt;

    reg [7:0] r_TX_Byte;
    reg [7:0] r_RX_Byte;

    reg r_Leading_Edge;
    reg r_Trailing_Edge;

    // ------------------------------------------------------------------------------
    // Assign output
    // ------------------------------------------------------------------------------
    assign mosi = r_TX_Byte[7]; // Transmit MSB first

    // ------------------------------------------------------------------------------
    // Main control (shift, sample, clock, etc.)
    // ------------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            busy <= 0;
            cs_n <= 1;
            sclk <= 0;
            bit_cnt <= 0;
            clk_cnt <= 0;
            r_TX_Byte <= 0;
            r_RX_Byte <= 0;
            r_Leading_Edge <= 0;
            r_Trailing_Edge <= 0;
            data_out <= 0;
        end else begin
            r_Leading_Edge <= 0;
            r_Trailing_Edge <= 0;

            if (start && !busy) begin
                // Initialize transfer
                busy <= 1;
                cs_n <= 0;
                sclk <= 0;
                bit_cnt <= 7;
                r_TX_Byte <= data_in;
                r_RX_Byte <= 0;
                clk_cnt <= 0;
            end else if (busy) begin
                
                // SPI clock division
                if (clk_cnt == CLK_DIV-1) begin
                    sclk <= ~sclk;
                    clk_cnt <= 0;

                    if (sclk == 0) begin
                        // Rising edge
                        r_Leading_Edge <= 1;
                    end else begin
                        // Falling edge
                        r_Trailing_Edge <= 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end

                // ------------------------------------------------------------------------------
                // Sample and shift on appropriate edges
                // ------------------------------------------------------------------------------

                if (r_Leading_Edge) begin
                    r_RX_Byte <= {r_RX_Byte[6:0], miso};

                    if (bit_cnt == 0) begin
                        // All 8 bits received
                        data_out <= {r_RX_Byte[6:0], miso};

                        busy <= 0;
                        cs_n <= 1;
                        sclk <= 0;
                    end
                end

                if (r_Trailing_Edge && busy) begin
                    r_TX_Byte <= {r_TX_Byte[6:0], 1'b0};

                    if (bit_cnt > 0) begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end
        end
    end

endmodule