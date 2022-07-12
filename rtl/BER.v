module BER
#(
    parameter PRBS_N = 9
)
(
    input clock,
    input i_reset,
    input i_reset_sinc,
    input i_enable,
    input i_enb_rx,
    input i_PRBS,
    input i_sim,
    output o_led,
    output [63:0] o_bits_count,
    output [63:0] o_error_count
);
localparam errors_min = 9'd511;
localparam NB_CHECK = 2**PRBS_N-1;

wire [NB_CHECK-1:0] PRBS_reg_mux_in;
reg  [NB_CHECK-2:0] PRBS_reg; 

assign PRBS_reg_mux_in = {PRBS_reg,i_PRBS};  //tomo el dato de entrada mas el registro de desplazamiento

//registro de desplazamiento
always@(posedge clock, negedge i_reset)begin
    if (!i_reset||i_reset_sinc)begin //
      PRBS_reg <= {NB_CHECK-1{1'b0}};
    end
    else begin
      if (i_enb_rx) begin
        if(i_enable)begin
            PRBS_reg <= {PRBS_reg[NB_CHECK-3:0],i_PRBS};
         end 
       end
    end
end


reg [PRBS_N-1:0] PRBS_checker_count;
reg [PRBS_N-1:0] PRBS_errors_count;
reg [PRBS_N-1:0] PRBS_pos;
reg [PRBS_N-1:0] PRBS_errors_min;
reg [PRBS_N-1:0] PRBS_index_min;
reg PRBS_checker_locked;
reg [63:0] error_count; //variables a leer con el micro
reg [63:0] bits_count; //variables a leer con el micro

//cuenta de error
always@(posedge clock, negedge i_reset)begin
  if(!i_reset || i_reset_sinc)begin // falta agregar eso cuando se decida la fase vuelva a contar BER para arreglar la latencia!!
    PRBS_errors_count <= {PRBS_N{1'b0}};
    PRBS_checker_count <= {PRBS_N{1'b0}}; 
    PRBS_errors_min <= errors_min;
    PRBS_pos <= {PRBS_N{1'b0}};
    PRBS_checker_locked <= 1'b0;
    PRBS_index_min <= {PRBS_N{1'b0}};
    error_count <= {64{1'b0}};
    bits_count <= {64{1'b0}};
  end
  else begin
    if(i_enb_rx)begin
      if(i_enable)begin
        if(!PRBS_checker_locked)begin
            if(PRBS_checker_count == NB_CHECK-1)begin
                PRBS_checker_count <= {PRBS_N{1'b0}};
                PRBS_errors_count <= {PRBS_N{1'b0}};
                if(PRBS_errors_count < PRBS_errors_min)begin
                    PRBS_errors_min <= PRBS_errors_count;
                    PRBS_index_min <= PRBS_pos;
                end
                if (PRBS_pos>=NB_CHECK-1) begin
                    PRBS_pos <= {PRBS_N{1'b0}};
                    PRBS_checker_locked <= 1'b1; 
                end
                else begin
                    PRBS_pos <= PRBS_pos + 1'b1;
                end
            end
            else begin
             PRBS_checker_count <=  PRBS_checker_count + 1'b1;
             PRBS_errors_count <= PRBS_errors_count + (i_sim^PRBS_reg_mux_in[PRBS_pos]);
            end
        end
        else begin
         error_count <= error_count + (i_sim ^ PRBS_reg_mux_in[PRBS_index_min]);
         bits_count <= bits_count + 1'b1;
        end
      end
    end
  end 
end



assign o_led = (PRBS_checker_locked & error_count == 64'b0) ? 1'b1 : 1'b0; //agrego el locked por que sino prenderia cuando arranca un reset

assign o_bits_count = bits_count;
assign o_error_count = error_count;

endmodule