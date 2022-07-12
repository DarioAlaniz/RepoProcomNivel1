module downsampling_slicer
(
    input i_fir_poli,
    input clock,
    input i_reset,
    input i_enable,
    input [1:0] i_sel_phase,
    output o_reset_sinc,
    output o_bit
);

//obtengo el bit correspondiente dependiendo del signo de la senal de entrada 0 para + y 1 para -

wire w_bit;
assign w_bit = (i_fir_poli==1'b1) ? 1'b1 : 1'b0;

//posible retrazo extra que me corria en 1 la fase
// reg bit;
// always@(posedge clock)begin
//     if (i_fir_poli==1'b1) begin
//         bit <= 1'b1;
//     end
//     else if (i_fir_poli==1'b0) begin
//         bit <= 1'b0;
//     end
// end
// assign w_bit = bit;

//shiftreg para seleccionar la phase
wire [3:0]r_shift_mux_in;
reg [2:0] r_shift;
always@(posedge clock, negedge i_reset)begin
    if(!i_reset)begin
      r_shift <= {3{1'b0}};
    end
    else begin
      r_shift <= {r_shift[1:0],w_bit};
    end
end
assign r_shift_mux_in = {r_shift,w_bit};


//toma una de las 4 phase por cada enable
reg o_output_bit;
always @(*) begin
    case (i_sel_phase)
      2'b00: o_output_bit = r_shift_mux_in[0];
      2'b01: o_output_bit = r_shift_mux_in[1];
      2'b10: o_output_bit = r_shift_mux_in[2];
      2'b11: o_output_bit = r_shift_mux_in[3];
      default o_output_bit = 1'b0;
    endcase
end

assign o_bit = o_output_bit;


///detector de flanco
reg [1:0] sel_phase_reg;
reg o_reset_reg;

always@(posedge clock,negedge i_reset)begin
  if(!i_reset) begin
    sel_phase_reg <= {2{1'b0}};
  end
  else begin
    sel_phase_reg <= i_sel_phase;
  end
end

//registro de flanco por cada bit de entrada 
always@(posedge clock)begin
  if(i_sel_phase[0] && !sel_phase_reg[0]) begin
    o_reset_reg <= 1'b1;
  end  
  else if(i_sel_phase[1] && !sel_phase_reg[1])  begin
    o_reset_reg <= 1'b1;
  end
  else if(sel_phase_reg && !i_sel_phase)begin //para detectar cuando vuelve a la fase cero
    o_reset_reg <= 1'b1;
  end
  else begin
    o_reset_reg <= 1'b0;
  end 
end

assign o_reset_sinc = o_reset_reg;

endmodule
