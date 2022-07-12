module Register_File
#(
    parameter NB_GPIOS  = 32,
    parameter N_REG     = 12, //pueden cambiar los registros
    parameter N_DATA    = 22
)
(
    input                       clock,
    //input                       i_reset,
    input   [NB_GPIOS-1:0]      i_gpio,              //gpio de entrada
    input   [(2*NB_GPIOS)-1:0]  i_ber_count_Q,
    input   [(2*NB_GPIOS)-1:0]  i_ber_error_Q,
    input   [(2*NB_GPIOS)-1:0]  i_ber_count_I,
    input   [(2*NB_GPIOS)-1:0]  i_ber_error_I,
    input   [N_DATA-1:0]        i_data_log_from_mem,   //
    input                       i_mem_full,
    /*////////////////////////////////////////////////////////////////////////////
    / salidas internas para conectar al bloque DSP y memory
    ////////////////////////////////////////////////////////////////////////////*/
    output o_enable_tx,
    output o_enable_rx,
    output [1:0]o_phase,
    output o_reset,
    output o_run_log,
    output o_read_log,    
    output [9:0] o_addr_log_to_men,
    /////////////////////////////////////////////////////////////////////////////
    output  [NB_GPIOS-1:0] o_gpio               //gpio de salida 

);

reg [NB_GPIOS-1:0] registers [N_REG-1:0];       
wire [7:0] command;
wire enable;
wire [22:0]data;

assign command  = i_gpio[31:24];
assign enable   = i_gpio[23];
assign data     = i_gpio[22:0];
/*////////////////////////////////////////////////////////////////////////////
/   command[31:24], enable[23] y data[22:0]
/   command: 0x01 ----> reset general
/   command: 0x02 ----> channel
/                       data[0]:enable_tx
/                       data[1]:enable_rx
/                       data[3:2]:phase_sel
/   command: 0x03 ----> guardo los valores del BER_Q(contador de bit y error)  
/                       data[0]:solicito la parte baja de ber_samp
/                       data[1]:solicito la parte alta de ber_samp
/                       data[2]:solicito la parte baja de ber_error
/                       data[3]:solicito la parte alta de ber_error                     
/   command: 0x04 ----> memlog run_log                      
/   command: 0x05 ----> memlog read_log
/   command: 0x06 ----> guardo los valores del BER_I(contador de bit y error)  
/                       data[0]:solicito la parte baja de ber_samp
/                       data[1]:solicito la parte alta de ber_samp
/                       data[2]:solicito la parte baja de ber_error
/                       data[3]:solicito la parte alta de ber_error
/   command: 0x07 ----> data[14:0]addr_log_to_men
/   command: 0x08 ----> reset of register file
/   command: 0x09 ----> confirmacion de memoria completa
/   command: 0x10 ----> saco i_data_log_from_mem por el gpio
/   command: 0x11 ----> escriber el BER o ERROR el gpio canal Q
/   command: 0x12 ----> escriber el BER o ERROR el gpio canal I
////////////////////////////////////////////////////////////////////////////*/
/*////////////////////////////////////////////////////////////////////////////
/   inicializacion de memoria modificar con un reset general
/   consultar funcionamiento de generate y del bloque initial dentro!!
////////////////////////////////////////////////////////////////////////////*/
// integer ram_index;
// always@(posedge clock, negedge i_reset)begin
//   if(registers[0][0])begin
//     for (ram_index = 0; ram_index < N_REG; ram_index = ram_index + 1)
//       registers[ram_index] = {NB_GPIOS{1'b0}};
//   end
// end
/*////////////////////////////////////////////////////////////////////////////
/   detector de flanco para el enable
////////////////////////////////////////////////////////////////////////////*/
reg reg_enable;
always@(posedge clock)begin
  reg_enable <= i_gpio[23];
end
/*////////////////////////////////////////////////////////////////////////////
/   toma de desiciones
////////////////////////////////////////////////////////////////////////////*/
integer ram_index;
always@(posedge clock)begin
  if(!enable&&reg_enable) begin     //llego un nuevo comando
    case(command)
        8'h01:  registers[0]          <= {registers[0][31:1] ,  data[0]};         //reset
        8'h02:  registers[1]          <= {registers[1][31:4] ,  data[3:0]};       //command channel
        8'h03:  begin
                registers[2]          <= i_ber_count_Q[NB_GPIOS-1:0];             //guardo la parte baja
                registers[3]          <= i_ber_count_Q[2*(NB_GPIOS)-1:NB_GPIOS];  //guardo la parte alta
                registers[4]          <= i_ber_error_Q[NB_GPIOS-1:0];             //guardo la parte baja
                registers[5]          <= i_ber_error_Q[2*(NB_GPIOS)-1:NB_GPIOS];   //guardo la parte alta
        end    
        8'h04:  registers[6]          <= {registers[6][31:1] , 1'b1};             //run memory
        8'h05:  registers[6]          <= {registers[6][31:2] , 2'b10};            //read memory   
        8'h06:  begin
                registers[7]         <= i_ber_count_I[NB_GPIOS-1:0];             //guardo la parte baja
                registers[8]         <= i_ber_count_I[2*(NB_GPIOS)-1:NB_GPIOS];  //guardo la parte alta
                registers[9]         <= i_ber_error_I[NB_GPIOS-1:0];             //guardo la parte baja
                registers[10]         <= i_ber_error_I[2*(NB_GPIOS)-1:NB_GPIOS];  //guardo la parte alta
        end
        8'h07:  registers[11]          <= {registers[11][31:15],data[14:0]};      //direccion para leer la memoria   
        8'h08:begin                                                               //reset de register file
          for (ram_index = 0; ram_index < N_REG; ram_index = ram_index + 1)begin
            registers[ram_index] = {NB_GPIOS{1'b0}};
          end
        end
    endcase
  end
end

reg [NB_GPIOS-1:0] r_gpio;
always @(posedge clock) begin
  if(!enable&&reg_enable)begin
      if (command==8'h09)begin
        if(!i_mem_full) r_gpio <= {NB_GPIOS{1'b0}};                     //no se lleno la memoria
        else            r_gpio <= {{NB_GPIOS-1{1'b0}}, i_mem_full};     //memoria llena se puede leer
      end
      else if(command==8'h10)begin          
        if(i_mem_full)begin
          if(registers[6][1])       r_gpio <= {{8{1'b0}},i_data_log_from_mem};  //saco el dato por el gpio y relleno con ceros los bits faltantes
        end
      end
      //solicitud de BER_Q
      else if(command==8'h11)begin     //parte baja de i_ber_count_Q
        if(data[0])       r_gpio <= registers[2];
        else if(data[1])  r_gpio <= registers[3];
        else if(data[2])  r_gpio <= registers[4];
        else if(data[3])  r_gpio <= registers[5];
      end
        //solicitud de BER_I
      else if(command==8'h12)begin     //parte baja de i_ber_count_I
        if(data[0])       r_gpio <= registers[7];
        else if(data[1])  r_gpio <= registers[8];
        else if(data[2])  r_gpio <= registers[9];
        else if(data[3])  r_gpio <= registers[10];
      end
  end
end

/*////////////////////////////////////////////////////////////////////////////
/ salidas
/////////////////////////////////////////////////////////////////////////////*/
assign o_gpio       = r_gpio;

assign o_enable_tx  = registers[1][0];
assign o_enable_rx  = registers[1][1];
assign o_phase      = registers[1][3:2];

assign o_reset      = registers[0][0];

assign o_run_log    = registers[6][0];
assign o_read_log   =registers[6][1];   
assign o_addr_log_to_men=registers[11][14:0];



// assign O_GPIO = (registers[3][1])       ? i_data_log_from_mem >> 11 :
//                 (registers[6][1])       ? (32'h000007FF & i_data_log_from_mem):
//                 (reg_ber_low_Q)         ? registers[7] :
//                 (reg_ber_high_Q)        ? registers[8] :
//                 (reg_ber_error_low_Q)   ? registers[9] :
//                 (reg_ber_error_high_Q)  ? registers[10] :
//                 (reg_ber_low_I)         ? registers[11] :
//                 (reg_ber_high_I)        ? registers[12] :
//                 (reg_ber_error_low_I)   ? registers[13] :
//                 (reg_ber_error_high_I)  ? registers[14] : 32'h00000000;


/*
/ sacas los datos como output y agregar memfull para que permita leer
*/



endmodule