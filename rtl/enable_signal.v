/*
modulo para hacer un divisor de clock
*/
module enable_signal
(
    input clock,
    input i_reset,
    input [1:0]i_sw,
    output BR_clock
);

reg [1:0] count;
reg enable;

always@(posedge clock, negedge i_reset)begin
  if (!i_reset)begin
    count  <= 2'b00;
    enable <= 1'b0;
  end
  else if (i_sw[0] || i_sw[1])begin
      if (count==2'b11)begin
        enable <= 1'b1;
        count  <= 2'b00;
      end
      else begin
          count  <= count + 1'b1;
          enable <= 1'b0;
      end   
  end
end
assign BR_clock = enable;

endmodule
