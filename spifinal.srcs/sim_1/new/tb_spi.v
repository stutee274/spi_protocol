`timescale 1ns / 1ps

module tb_spi;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;

    // SPI lines
    wire sclk;
    wire cs_n;
    wire mosi;
    wire miso;

    // Master signals
    reg  [7:0] master_data_in;
    reg        start;
    wire [7:0] master_data_out;
    wire       busy;

    // Slave signals
    reg  [7:0] slave_transmit_data;
    wire [7:0] slave_received_data;

    // Generate system clock (50 MHz)
    always #5 clk = ~clk;

    // Instantiate SPI Master
    spim #(.CLK_DIV(4)) master (
        .clk(clk),
        .rst(rst),
        .data_in(master_data_in),
        .start(start),
        .data_out(master_data_out),
        .busy(busy),
        .cs_n(cs_n),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso)
    );

    // Instantiate SPI Slave
    spislave slave (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .ss(cs_n),
        .mosi(mosi),
        .miso(miso),
        .received_data(slave_received_data),
        .transmit_data(slave_transmit_data)
    );

    initial begin
        // Initialize
        $display("Starting SPI Master-Slave Simulation...");
        master_data_in = 8'hA5;
        slave_transmit_data = 8'h3C;
        start = 0;

        // Reset pulse
        #25;
        rst = 0;
        #50;

        // Start SPI transfer
        $display("Master sending: 0x%h", master_data_in);
        start = 1;
        #20;
        start = 0;

        // Wait for transfer to complete
        wait (busy == 0);
        #50;

        $display("Slave received: 0x%h", slave_received_data);
        $display("Master received: 0x%h", master_data_out);

        // Additional checks
        if (slave_received_data == 8'hA5 && master_data_out == 8'h3C)
            $display(" SPI transfer successful!");
        else
            $display("SPI transfer failed.");

        #100;
        $finish;
    end

endmodule
