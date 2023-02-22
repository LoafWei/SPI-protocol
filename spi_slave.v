`timescale 1ns/1ns
module spi_slave#
(
parameter BITS_LEN = 8,
parameter CPOL = 1'b0,
parameter CPHA = 1'b0
)
(
input clk,
input rst_n,
input spi_clk,
input spi_mosi,
input spi_ss,
output spi_miso,
output spi_rxvalid,
output [BITS_LEN-1'b1:0] spi_rdata,
output o_clk,
output reg [7:0] LED
);

reg spi_cap = 1'b0;
reg shift_en = 1'b0;
reg [3:0] spi_clk_r = 4'b0;
reg [2:0] spi_bit_cnt = 3'b0;
reg [BITS_LEN-1'b1:0] spi_rx_r;
reg [BITS_LEN-1'b1:0] spi_tx_r;
reg [3:0] spi_ss_r = 4'b0;

wire spi_rx_en;
wire spi_clkp;
wire spi_clkn;

assign spi_rdata = spi_rx_r;
assign spi_rxvalid = (spi_bit_cnt == BITS_LEN);

assign spi_clkp = spi_clk_r[3:2] == 2'b01;
assign spi_clkn = spi_clk_r[3:2] == 2'b10;

assign spi_rx_en = (~spi_ss_r[3]);

always @(posedge clk or negedge rst_n) begin
  if(rst_n == 1'b0)
    spi_clk_r <= 4'd0;
  else
    spi_clk_r <= {spi_clk_r[2:0], spi_clk};
end

always @(posedge clk or negedge rst_n) begin
  if(rst_n == 1'b0)
    spi_ss_r <= 4'd0;
  else
    spi_ss_r <= {spi_ss_r[2:0], spi_ss};
end


always @(*) begin
  if(CPHA) begin
    if(CPOL) spi_cap = spi_clkp; // CPOL=1, CPHA=1
    else spi_cap = spi_clkn;  // CPOL=0, CPOL=1
  end
  else begin
    if(CPOL) spi_cap = spi_clkn; // CPOL=1, CPHA=0
    else spi_cap = spi_clkp;  // CPOL=0, CPHA=0;
  end
end

always @(*) begin
  if(CPHA) begin
    if(CPOL) shift_en = spi_clkn; // CPOL=1, CPHA=1
    else shift_en = spi_clkp;  // CPOL=0, CPHL=1
  end
  else begin
    if(CPOL) shift_en = spi_clkp; // CPOL=1, CPHA=0
    else shift_en = spi_clkn;  // CPOL=0, CPHA=0;
  end
end

//spi bit counter
always @(posedge clk) begin
  if(spi_rx_en&&spi_cap&&(spi_bit_cnt < BITS_LEN)) begin
    spi_bit_cnt <= spi_bit_cnt + 1'b1;
  end
  else if(spi_rx_en==0||spi_bit_cnt == BITS_LEN) begin
    spi_bit_cnt <= 0;
  end
end

//spi rx bit shift
always @(posedge clk or negedge rst_n) begin
  if(rst_n == 1'b0)
    spi_rx_r <= BITS_LEN-1'b0;
  else if(spi_rx_en&&spi_cap) begin
    spi_rx_r <= {spi_rx_r[BITS_LEN-2:0], spi_mosi};
  end
  else if(spi_rx_en == 1'b0) begin
    spi_rx_r <= 8'b0;
  end
  else
    spi_rx_r <= spi_rx_r;
end


//spi tx shift
always @(posedge shift_en or negedge rst_n) begin
  if(rst_n == 1'b0)
    spi_tx_r <= BITS_LEN-1'd0;
  else if(spi_rx_en)
    spi_tx_r <= spi_rx_r;
  else if(spi_rx_en && shift_en)
    spi_tx_r <= {spi_tx_r[BITS_LEN-2:0], 1'b0};
  else
    spi_tx_r <= spi_tx_r;
end

assign spi_miso = spi_rx_en ? spi_tx_r[BITS_LEN-1]:1'bz;

endmodule

