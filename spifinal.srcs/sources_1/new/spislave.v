module spislave (
    input  wire sclk,    // SPI clock
    input  wire ss,      // Active low chip select
    input  wire mosi,    // Master Out, Slave In
    output wire  miso,    // Master In, Slave Out
    output reg [7:0] received_data, // Byte received from master
    input  wire [7:0] transmit_data // Byte to send back to master
);
    reg [7:0] shift_reg_in;  // Shift register for incoming data
    reg [7:0] shift_reg_out; // Shift register for outgoing data
    reg [3:0] bit_count;
   assign  miso = shift_reg_out[0];
    always @(posedge sclk or posedge ss) begin
        if (ss) begin                                                                                                  
            // Loading the data to send back first
            shift_reg_out <= transmit_data;
            shift_reg_in <= 8'd0;
            bit_count <= 4'd0;
        end else begin
            // 1. Transmit first (LSB first)
          
            shift_reg_out <= {1'b0, shift_reg_out[7:1]};

            // 2. Then receive
            shift_reg_in <= {mosi, shift_reg_in[7:1]};

            // 3. After 8th bit, latch the received byte
            if (bit_count == 7) begin
                received_data <= {mosi, shift_reg_in[7:1]};
                bit_count <= 0;
            end else begin
                bit_count <= bit_count + 1;
            end
        end
    end
endmodule