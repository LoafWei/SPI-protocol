module spi_master_tx#
(
parameter CLK_DIV = 100
)
(
input clk,
input rst_n,
output spi_sclk_o,
output spi_mosi_o,
output [7:0] LED
);

wire spi_busy;
reg spi_tx_req;
reg [7:0] spi_tx_data;
reg [2:0] M_S;

//spi send state machine
always @(posedge clk) begin
  if(rst_n==1'b0) begin
    spi_tx_req <= 1'b0;
    spi_tx_data <= 8'd0;
    M_S <= 3'd0;
  end
  else begin
    case(M_S)
    0:if(!spi_busy) begin  //Bus not busy start transfer
      spi_tx_req <= 1'b1;
      spi_tx_data <= spi_tx_data + 1'b1; //test data
      M_S <= 3'd1;
    end
    1:if(spi_busy) begin //if spi Bus busy clear spi_tx_req
      spi_tx_req <= 1'b0;
      M_S <= 3'd2;
    end
	 2:if(spi_busy && spi_tx_data == 8'd255) begin
	   spi_tx_data <= 0;
		M_S <= 3'd0;
	 end
    default:M_S <= 3'd0;
    endcase
  end
end

//spi master controller
spi_master#
(
.CLK_DIV(CLK_DIV),
.CPOL(1'b0),
.CPHA(1'b0)
)
spi_inst(
.clk(clk),
.rst_n(rst_n),
.spi_mosi_o(spi_mosi_o),
.spi_sclk_o(spi_sclk_o),
.spi_tx_req_i(spi_tx_req),
.spi_tx_data_i(spi_tx_data),
.spi_busy_o(spi_busy),
.LED(LED)
);

endmodule