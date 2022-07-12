module top_tp8
#(
    parameter N_ADDR = 10,                   //cambiar los 32K
    parameter RAM_WIDTH_1 = 22,              //cambiar para guardar los 22 bits de los filtros
    parameter N_GPIO = 32
)
(
    input                       clk100,
    input                       in_reset,
    input                       in_rx_uart,
    output                      out_tx_uart,
    output  [2:0]               out_leds_rgb0,
    output  [2:0]               out_leds_rgb1,
    output  [3:0]               out_leds
    
    /*
    /señales de prueba para probar las memorias 
    */
    // input   [3:0]               i_sw,
    // input                       i_run_log,
    // input                       i_read_log,
    // input   [N_ADDR-1:0]        i_addr_log_to_mem,
    // output                      o_mem_full,
    // output  [RAM_WIDTH_1-1:0]   o_data_log_from_mem

    //input [31:0]    i_gpio,  
    /* señales de preba para el register file        
    input [63:0]    i_ber_count_Q,
    input [63:0]    i_ber_error_Q,
    input [63:0]    i_ber_count_I,
    input [63:0]    i_ber_error_I,
    input [21:0]    i_data_log_from_mem,
    input           i_mem_full,
    */
    //output[31:0]    o_gpio
); 

localparam N_BIT_FIR = 11;
/*------------------------------------------------------------------
/  variables register file
------------------------------------------------------------------*/
wire                enable_tx;
wire                enable_rx;
wire [1:0]          phase;
wire                reset;
wire                run_log;
wire                read_log;
/*------------------------------------------------------------------
/  variables memory
------------------------------------------------------------------*/
wire [N_ADDR-1:0]   addr;
wire [N_ADDR-1:0]   addr_log_to_men;
wire [RAM_WIDTH_1-1:0] data_log_from_mem;
wire                mem_full;

/*------------------------------------------------------------------
/  variables DSP
------------------------------------------------------------------*/
wire signed [N_BIT_FIR-1:0] fir_Q;
wire signed [N_BIT_FIR-1:0] fir_I;
wire [21:0] fir;
wire [63:0]bits_count_Q;
wire [63:0]bits_count_I;
wire [63:0]error_count_Q;
wire [63:0]error_count_I;

wire [3:0]  sw;
assign sw =  {phase,enable_rx,enable_tx};
assign fir = {fir_Q,fir_I};             //para concatener los 2 filtros y ir guardando 

/*------------------------------------------------------------------
/  variables Micro
------------------------------------------------------------------*/
wire [N_GPIO                 - 1 : 0]           gpo0;
wire [N_GPIO                 - 1 : 0]           gpi0;
wire                                            locked;
wire                                            soft_reset;
wire                                            clockdsp;

/*------------------------------------------------------------------
control de memoria
------------------------------------------------------------------*/
addres_count#(
    .count(N_ADDR)
)   u_addres_count(
    .clock(clockdsp),
    .i_reset(reset),
    .i_run_log(run_log),
    .i_read_log(read_log),
    .i_addr_log_to_mem(addr_log_to_men),
    .o_addr(addr),
    .o_mem_full(mem_full)
);
/*------------------------------------------------------------------
/   memoria 
/   una sola memoria de 22 bit de ancho la guardar la salida de 2 filtros
------------------------------------------------------------------*/
Memlog#(
    .RAM_WIDTH(RAM_WIDTH_1),                      
    .RAM_DEPTH(2**N_ADDR),                     
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), 
    .INIT_FILE("")     
)   u_Memlog(
    .addra(addr),                             // Address bus, width determined from RAM_DEPTH
    .dina(fir),                               // RAM input data
    .clka(clockdsp),                          // Clock
    .wea(run_log),                            // Write enable
    .ena(1'b1),                               // RAM Enable, for additional power savings, disable port when not in use
    .rsta(!reset),                            // Output reset (does not affect memory contents)
    .regcea(read_log),                        // Output register enable
    .douta(data_log_from_mem)                 // RAM output data
    );
/*------------------------------------------------------------------
DSP
------------------------------------------------------------------*/
DSP
    u_DSP(
        .clock(clockdsp),
        .i_reset(reset),
        .i_sw(sw),
        .fir_Q(fir_Q),
        .fir_I(fir_I),
        .o_bits_count_Q(bits_count_Q),
        .o_error_count_Q(error_count_Q),
        .o_bits_count_I(bits_count_I),
        .o_error_count_I(error_count_I)
    );
/*------------------------------------------------------------------
register file
------------------------------------------------------------------*/
Register_File
    u_Register_File(
        .clock(clockdsp),
        //.i_reset(i_reset),
        .i_gpio(gpo0),             
        .i_ber_count_Q(bits_count_Q),
        .i_ber_error_Q(error_count_Q),
        .i_ber_count_I(bits_count_I),
        .i_ber_error_I(error_count_I),
        .i_data_log_from_mem(data_log_from_mem),
        .i_mem_full(mem_full),
        .o_enable_tx(enable_tx),
        .o_enable_rx(enable_rx),
        .o_phase(phase),
        .o_reset(reset),
        .o_run_log(run_log),
        .o_read_log(read_log),    
        .o_addr_log_to_men(addr_log_to_men),
        .o_gpio(gpi0)
    );

/*------------------------------------------------------------------
Micro
------------------------------------------------------------------*/
Micro_2
    u_Micro_2(
        .clocl100(clockdsp), //error de tipeo 
        .gpio_rtl_tri_i(gpi0),
        .gpio_rtl_tri_o(gpo0),
        .gpio_rtl_tri_t(),
        .o_lock_clock(locked),
        .reset(in_reset),
        .sys_clock(clk100),
        .usb_uart_rxd(in_rx_uart),
        .usb_uart_txd(out_tx_uart)
    );

/*------------------------------------------------------------------
LEDS
------------------------------------------------------------------*/
assign out_leds[0] = locked;
assign out_leds[1] = reset;
assign out_leds[2] = enable_tx;
assign out_leds[3] = enable_rx;

assign out_leds_rgb0[0] = run_log; 
assign out_leds_rgb0[1] = read_log;
assign out_leds_rgb0[2] = mem_full;

assign out_leds_rgb1[0] = phase[0];
assign out_leds_rgb1[1] = phase[1];
assign out_leds_rgb1[2] = 1'b0;
/*------------------------------------------------------------------
VIO
------------------------------------------------------------------*/
vio
    u_vio(
        .clk_0(clockdsp),
        .probe_in0_0({enable_rx,enable_tx,reset,locked}),
        .probe_in1_0({mem_full,read_log,run_log}),
        .probe_in2_0({1'b0,phase[1],phase[0]})
        );

endmodule



/*
/ 
*/