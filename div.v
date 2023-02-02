module div(
  input clk,
  input rst_n,
  output reg o_clk
);
 
reg [7:0] cnt;

always@(posedge clk or negedge rst_n) begin
  if (!rst_n)
    cnt <= 0;
  else if (cnt == 8'h255)
    cnt <= 0;
  else
    cnt <= cnt + 1'b1;
end
 
always@(posedge clk or negedge rst_n) begin
  if (!rst_n)
    o_clk <= 0;
  else if (cnt == 8'h255) 
    o_clk = 0;
  else           
    o_clk = o_clk + 1'b1;   
 end
 
endmodule
