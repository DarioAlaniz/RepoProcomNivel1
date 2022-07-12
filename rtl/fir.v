module fir
#(
  parameter N_B_SALIDA = 10
) 
(
    input clock,
    input i_reset,
    input i_sim,
    output signed [N_B_SALIDA:0] o_output,  //11 bit para la salida por la forma que genera el arbol de suma
    input i_enable,  //clock del modulo a clocl/4
    input i_enb_tx   //habilita el modulo 
);
//coeficientes
// [  0.   0.   0. 127.   0.   0.]
// [  1. 249.  34. 114. 240.   3.]
// [  2. 241.  77.  77. 241.   2.]
// [  3. 240. 114.  34. 249.   1.]
localparam signed H_0 = 8'd0; 
localparam signed H_1 = 8'd0;
localparam signed H_2 = 8'd0;
localparam signed H_3 = 8'd127;
localparam signed H_4 = 8'd0;
localparam signed H_5 = 8'd0;
localparam signed H_6 = 8'd1; 
localparam signed H_7 = 8'd249;
localparam signed H_8 = 8'd34;
localparam signed H_9 = 8'd114;
localparam signed H_10 = 8'd240;
localparam signed H_11 = 8'd3;
localparam signed H_12 = 8'd2; 
localparam signed H_13 = 8'd241;
localparam signed H_14 = 8'd77;
localparam signed H_15 = 8'd77;
localparam signed H_16 = 8'd241;
localparam signed H_17 = 8'd2;
localparam signed H_18 = 8'd3; 
localparam signed H_19 = 8'd240;
localparam signed H_20 = 8'd114;
localparam signed H_21 = 8'd34;
localparam signed H_22 = 8'd249;
localparam signed H_23 = 8'd1;

reg [4:0] shiftreg; //registros para guardar el simbolo que entra
reg signed [N_B_SALIDA:0] reg_output;
wire signed [7:0] coefficient [5:0];

//a la velocidad de SR alterno los coeficientes
reg [1:0] address; //registro para alternar entre los distintos coeficientes 
always@(posedge clock)begin
  if(i_enable)begin
    address <= 2'b00;
  end
  else begin
    address <= address + 1'b1;  //revisar por que el desfasaje con el enable del shift reg!!! se arreglo haciendo cero el contador con el enable
  end
end

assign coefficient[0] = (address==2'b00) ? H_0 :
                        (address==2'b01) ? H_6 :
                        (address==2'b10) ? H_12 : H_18;

assign coefficient[1] = (address==2'b00) ? H_1 :
                        (address==2'b01) ? H_7 :
                        (address==2'b10) ? H_13 : H_19;

assign coefficient[2] = (address==2'b00) ? H_2 :
                        (address==2'b01) ? H_8 :
                        (address==2'b10) ? H_14 : H_20;

assign coefficient[3] = (address==2'b00) ? H_3 :
                        (address==2'b01) ? H_9 :
                        (address==2'b10) ? H_15 : H_21;

assign coefficient[4] = (address==2'b00) ? H_4 :
                        (address==2'b01) ? H_10 :
                        (address==2'b10) ? H_16 : H_22;

assign coefficient[5] = (address==2'b00) ? H_5 :
                        (address==2'b01) ? H_11 :
                        (address==2'b10) ? H_17 : H_23;

//registro de desplazamiento
always @(posedge clock,negedge i_reset)begin
  if(!i_reset)begin
      shiftreg <= {5{1'b0}}; //inicializo el shiftreg, no haria falta
  end
  else if (i_enb_tx) begin
    if (i_enable)begin
      shiftreg <= {shiftreg[3:0],i_sim}; 
    end
  end
end

//arbol de suma
//hacer con complemento a 2 con (-)
integer i;
always@(*)begin
  if (i_sim)begin
    reg_output = -coefficient[0];
  end
  else begin 
    reg_output = coefficient[0];
  end
  for (i=1;i<6;i=i+1)begin
    if (shiftreg[i-1]) begin
      reg_output = reg_output - coefficient[i];
    end
    else begin
      reg_output = reg_output + coefficient[i];
    end
  end
end

//evitar la propagacion de timming agrego un registro a la salida
reg signed [N_B_SALIDA:0] sal_fir;
always @ (posedge clock)begin
  sal_fir <= reg_output;
end

assign o_output = sal_fir;

endmodule


