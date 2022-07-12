module prbs
#(
    parameter seed = 9'h1AA
)
(
    input clock,
    input i_enable,
    input i_reset,
    input i_enb_tx,
    output o_output
);

reg [8:0] shiftreg;

always@(posedge clock, negedge i_reset)begin
  if (!i_reset) begin
      shiftreg <= seed;
  end
  else begin
    if (i_enb_tx)begin
      if (i_enable) begin
          shiftreg <= {shiftreg[7:0],shiftreg[8]^shiftreg[4]};
      end
    end
  end
end

assign o_output = shiftreg[8];

endmodule