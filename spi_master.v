module spi_master#
(
parameter CLK_DIV = 100,
parameter CPOL = 1'b0,
parameter CPHA = 1'b0
)
(
input clk,
input rst_n,
input spi_tx_req_i,
input [7:0] spi_tx_data_i,
output spi_mosi_o,
output spi_sclk_o,
output spi_busy_o,
output reg	[7:0] LED
);

localparam [9:0] SPI_DIV  = CLK_DIV; //second clock edge counter
localparam [9:0] SPI_DIV1  = SPI_DIV/2; //first clock edge counter

reg [9:0] clk_div = 10'd0;
reg spi_en = 1'b0;
reg spi_clk = 1'b0;
reg [3:0] tx_cnt = 4'd0;
reg [7:0] spi_tx_data_r = 8'd0;
wire clk_end;
wire clk_en1; //fist internal clock edge enable
wire clk_en2; //second internal clock edge enable
reg spi_strobe_en;
wire spi_strobe; //CPHA=0 data is transmitted on the first clock edge 

assign clk_en1 = (clk_div == SPI_DIV1); //fist internal clock edge enable
assign clk_en2 = (clk_div == SPI_DIV);  //second internal clock edge enable
assign clk_end = (clk_div == SPI_DIV1)&&(tx_cnt==4'd8);
//When CPHA=0, the first SCLK transition edge of the data is sampled
//When CPHA=1, the second SCLK transition edge of the data is sampled
assign spi_strobe = CPHA ? clk_en1&spi_strobe_en : clk_en2&spi_strobe_en;
assign spi_sclk_o = (CPOL == 1'b1) ? ~spi_clk : spi_clk;
assign spi_mosi_o = spi_tx_data_r[7];
assign spi_busy_o = spi_en;

//clock division
always @(posedge clk) begin
  if(spi_en == 1'b0)
    clk_div <= 10'd0;
  else if(clk_div < SPI_DIV)
    clk_div <= clk_div + 1'b1;
  else 
    clk_div <= 0;
end

//Generate spi internal clock
always @(posedge clk) begin
  if(spi_en == 1'b0)
    spi_clk <= 1'b0;
  else if(clk_en2) //scond clock edge
    spi_clk <= 1'b0;
  else if(clk_en1&&(tx_cnt<4'd8)) //first clock edge
    spi_clk <= 1'b1;
end

always @(posedge clk) begin
  if(rst_n == 1'b0)
    spi_strobe_en <= 1'b0;
  else if(tx_cnt < 4'd8) begin
    if(clk_en1) spi_strobe_en <= 1'b1;
  end
  else
    spi_strobe_en <= 1'b0;
end


always @(posedge clk)begin
  if(rst_n == 1'b0 || (spi_en == 1'b0))
    tx_cnt <= 4'd0;
  else if(clk_en1)
    tx_cnt <= tx_cnt + 1'b1;
end

//spi sending module 
always @(posedge clk) begin
  if(rst_n == 1'b0 || clk_end) begin
    spi_en <= 1'b0;
    spi_tx_data_r <= 8'h00;
  end  
  else if(spi_tx_req_i&&(spi_en == 1'b0)) begin //enable transfer
    spi_en <= 1'b1;
    spi_tx_data_r <= spi_tx_data_i;
  end
  else if(spi_en) begin
    spi_tx_data_r[7:0] <= (spi_strobe) ? {spi_tx_data_r[6:0], 1'b1} : spi_tx_data_r;
  end
end 

always @(posedge clk) begin
  if(rst_n== 1'b0)
    LED <= 0;
  else if(tx_data == 8'd255)
    LED <= LED + 1;
  else
    LED <= LED;
end

endmodule 
