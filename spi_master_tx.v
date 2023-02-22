
module spi_master_tx#
(
parameter CLK_DIV = 6
)
(
input sysclk_p,
input rst_n,
output spi_sclk_o,
input spi_sclk_i,
output spi_mosi_o,
input spi_mosi_i,
output [7:0] LED
);

wire spi_busy;
reg spi_tx_req;
reg [7:0] spi_tx_data;
reg [1:0] M_S;

reg spi_ss_i;
wire spi_rxvalid;
wire[7:0] spi_rdata;
reg[10:0] delay_cnt;
wire delay_done;

assign delay_done=delay_cnt[10];

always @(posedge sysclk_p or negedge rst_n)begin
  if(!rst_n)
    delay_cnt <= 0;
  else if(delay_cnt[10] == 1'b0)
    delay_cnt <= delay_cnt + 1'b1;
  else
    delay_cnt <= 0;
end

//spi send state machine
always @(posedge sysclk_p) begin
  if(rst_n==1'b0) begin
    spi_ss_i <= 1'b1;
    spi_tx_req <= 1'b0;
    spi_tx_data <= 8'd0;
    M_S <= 2'd0;
  end
  else begin
    case(M_S)
    0:if(delay_done&&(!spi_busy)) begin  //Bus not busy start transfer
      spi_ss_i <= 1'b1;
      M_S <= 2'd1;
    end
    1:if(delay_done&&(!spi_busy)) begin //if spi Bus busy clear spi_tx_req
        spi_ss_i <= 1'b0;
        M_S <= 2'd2;
      end
    2:if (delay_done && (!spi_busy)) begin
        spi_tx_req <= 1'b1;
		  spi_tx_data <= spi_tx_data + 1'b1;
		  if(spi_tx_data == 8'd255)
		    spi_tx_data <= 0;
		  M_S <= 2'd3;
      end
    3:if (spi_busy) begin
        spi_tx_req <= 1'b0;
        M_S <= 2'd0;
      end
    default:M_S <= 2'd0;
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
spi_tx_inst(
.clk(sysclk_p),
.rst_n(rst_n),
.spi_mosi_o(spi_mosi_o),
.spi_sclk_o(spi_sclk_o),
.spi_tx_req_i(spi_tx_req),
.spi_tx_data_i(spi_tx_data),
.spi_busy_o(spi_busy),
.LED(LED)
);

//spi rx controller
spi_slave#
(
.BITS_LEN(8),
.CPOL(1'b0),
.CPHA(1'b0)
)
spi_rx_inst(
.clk(sysclk_p),
.rst_n(rst_n),
.spi_clk(spi_sclk_i),
.spi_mosi(spi_mosi_i),
.spi_ss(spi_ss_i),
.spi_rdata(spi_rdata),
.spi_rxvalid(spi_rxvalid)
);


endmodule