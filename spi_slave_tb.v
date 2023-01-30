`timescale 1ns/1ps

module spi_slave_tb;

localparam BYTES = 8;
localparam TCNT = BYTES*8*2-1;

localparam CPOL = 0;
localparam CPHA = 0;

integer num_in;
integer num_out;

reg clk;
reg [7:0] i;
reg rst_n;
reg spi_clk;
reg spi_ss;
reg [3:0] bit_cnt;
reg [7:0] spi_tx_buf;

wire spi_rxvalid;
wire [7:0] spi_rdata;
wire spi_mosi;
wire spi_miso;
assign spi_mosi = spi_tx_buf[7];

spi_slave#
(
.BITS_LEN(8),
.CPOL(CPOL),
.CPHA(CPHA)
)
spi_slave_uut(
.clk(clk),
.rst_n(rst_n),
.spi_clk(spi_clk),
.spi_mosi(spi_mosi),
.spi_miso(spi_miso),
.spi_ss(spi_ss),
.spi_rxvalid(spi_rxvalid),
.spi_rdata(spi_rdata)
);

initial begin
  clk = 1'b0;
  rst_n = 1'b0;
  #100;
  rst_n = 1'b1;
end

always #10 clk = ~clk;

initial begin
  #100
  i = 0;
  spi_clk = CPOL;
  forever begin
    spi_ss = 1;
    #2000
    spi_ss = 0;
    for(i=0;i<TCNT;i=i+1) #1000 spi_clk = ~spi_clk;
     
    #2000
    spi_ss = 1;
  end
end

initial begin
  #100
  bit_cnt = 0;
  num_in = $fopen("D:/spi_project/slave_txt_in", "r");
  num_out = $fopen("D:/spi_project/slave_txt_out", "w");

  forever begin
//spi ss control is used to enable transfers
    wait(spi_ss)
      bit_cnt = 0;
      $fscanf(num_in, "%b", spi_tx_buf[7:0]);

//Data transfer starts when ss is low
    wait(!spi_ss)
      
//CPHA=0 CPOL=1 SPI RX Sampling data on the falling edge
    if(CPOL == 0 && CPHA == 1)
      @(posedge spi_clk);
//CPHA=1 CPOL=1 SPI RX Sampling data on the rising edge
    if(CPHA == 1 && CPOL == 1)
      @(negedge spi_clk);

    while(!spi_ss) begin
      if((CPOL == 0 && CPHA == 1) || (CPOL == 1 && CPHA == 0)) begin
        @(posedge spi_clk) begin
          spi_tx_buf = {spi_tx_buf[6:0], 1'b0};
          if(bit_cnt == 7) begin
            bit_cnt = 0;
            $fscanf(num_in, "%b", spi_tx_buf[7:0]);
            $fwrite(num_out, "%b\n", spi_rdata[7:0]);
          end
          else
            bit_cnt = bit_cnt + 1'b1;
        end
      end
      if((CPOL == 0 && CPHA == 0) || (CPOL == 1 && CPHA == 1)) begin
        @(negedge spi_clk) begin
          spi_tx_buf = {spi_tx_buf[6:0], 1'b0};
          if(bit_cnt == 7) begin
            bit_cnt = 0;
            $fscanf(num_in, "%b", spi_tx_buf[7:0]);
            $fwrite(num_out, "%b\n", spi_rdata[7:0]); 
          end
          else
            bit_cnt = bit_cnt + 1'b1;
        end
      end
    end
  end
end
endmodule

