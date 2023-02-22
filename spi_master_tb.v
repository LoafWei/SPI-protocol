`timescale 1ns/1ps

module spi_master_tb;

reg clk;
reg rst_n;
wire spi_sclk_o;
wire spi_mosi_o;

spi_master_tx#
(
.CLK_DIV(100)
)
spi_master_inst(
.clk(clk),
.rst_n(rst_n),
.spi_sclk_o(spi_sclk_o),
.spi_mosi_o(spi_mosi_o)
);

initial begin
  clk = 1'b0;
  rst_n = 1'b0;
  #100
  rst_n = 1'b1;
end

always
  begin
    #10 clk = ~clk;
  end
endmodule
