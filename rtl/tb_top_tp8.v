`timescale 1ns/1ps // tiempo/presicion, 1ns/100ps valores estandar  
module tb_top_tp8();


reg         clock;
reg         i_reset;
/*
/ prueba de memoria
*/
// reg [3:0]   i_sw;
// reg         i_run_log;
// reg         i_read_log;
// reg [9:0]   i_addr_log_to_mem;
// wire        o_mem_full;
// wire [10:0] o_data_log_from_mem;

/*
/ prueba de register file
*/
localparam NB_GPIOS = 32;
reg   [NB_GPIOS-1:0]      I_GPIO;             //gpio de entrada
wire  [NB_GPIOS-1:0]      O_GPIO;
wire mem_full;
assign mem_full = tb_top_tp8.u_top_tp8.mem_full;

integer i;

initial begin
   clock               = 1'b0;
   #100 I_GPIO         = 32'h08800000;                  //prueba de reset
   #10 I_GPIO          = 32'h08000000;
   #10 I_GPIO          = 32'h01800001;                  //reset despues de 100 unidades de tiempo
   #10 I_GPIO          = 32'h01000001;

   #10 I_GPIO          = 32'h08800000;                  //prueba de reset
   #10 I_GPIO          = 32'h08000000;

   #10 I_GPIO          = 32'h01800001;                  //reset despues de 100 unidades de tiempo
   #10 I_GPIO          = 32'h01000001;

   #10 I_GPIO          = 32'h02800001;                  //habilito tx
   #10 I_GPIO          = 32'h02000001;

   #10 I_GPIO          = 32'h03800000;                  //guardo ber Q
   #10 I_GPIO          = 32'h03000000;

   #10 I_GPIO          = 32'h06800000;                  //guardo ber I
   #10 I_GPIO          = 32'h06000000;

   #10 I_GPIO          = 32'h04800001;                  //write        
   #10 I_GPIO          = 32'h04000001;
   for (i=0;i<=100000;i=i+1)begin
    #10I_GPIO           = 32'h04800000;
    #10I_GPIO           = 32'h04000000;                     
   end
   #10 I_GPIO           = 32'h05800000;                  //read        
   #10 I_GPIO           = 32'h05000000;
//tiempo para que llene la memoria
   for(i=0;i<1024;i=i+1)begin                           //direccion
     #10I_GPIO = 32'h07800000 + i;
     #10I_GPIO = 32'h07000000 + i;
   end
   #10 I_GPIO          = 32'h02800007;                  //habilito rx con phase 1
   #10 I_GPIO          = 32'h02000007;

   #1000000I_GPIO      =32'h03800000;                   //mando los errores
   #10I_GPIO           =32'h03000000;

   #10I_GPIO           =32'h03800001;
   #10I_GPIO           =32'h03000001;

   #10I_GPIO           =32'h03800002;
   #10I_GPIO           =32'h03000002;

   #10I_GPIO           =32'h03800004;
   #10I_GPIO           =32'h03000004;

   #10I_GPIO           =32'h03800008;
   #10I_GPIO           =32'h03000008;

  #100  $finish;

end

always #5 clock = ~clock;


/*
/prueba de memoria
*/
// always@(posedge clock)begin
//   if(o_mem_full)begin
//     i_run_log  <= 1'b0;
//     i_read_log <= 1'b1;
//     i_addr_log_to_mem <= i_addr_log_to_mem + 1'b1;
//   end
// end

// always@(posedge clock)begin
//   if(i_addr_log_to_mem==(2**10)-1) $stop;
// end


top_tp8
    u_top_tp8(
        .clock(clock),
        //.i_reset(i_reset),
        .i_gpio(I_GPIO),
        .o_gpio(O_GPIO)
    );

endmodule