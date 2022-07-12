module DSP
(
    input clock,
    input i_reset,
    input [3:0] i_sw,
    //output [3:0] o_led,
    //salidas para el tp8
    output signed [10:0] fir_Q,
    output signed [10:0] fir_I,
    output [63:0] o_bits_count_Q,
    output [63:0] o_error_count_Q,
    output [63:0] o_bits_count_I,
    output [63:0] o_error_count_I
    //input i_e_prbs //entrada auxiliar para generar un error en el tb del BER una vez que se sincroniza
);

wire o_prbs_Q;
wire o_prbs_I;
wire signed [10:0] o_fir_Q;
wire signed [10:0] o_fir_I;
wire BR_clock;
wire o_down_slice_Q;
wire o_down_slice_I;
wire reset_sinc_Q; //viene del dowslampling y slicer
wire reset_sinc_I;
wire [63:0]bits_count_Q;
wire [63:0]bits_count_I;
wire [63:0]error_count_Q;
wire [63:0]error_count_I;
//////////divisor de clock para el BR
enable_signal
    u_enable_signal(
        .clock(clock),
        .i_reset(i_reset),
        .i_sw(i_sw[1:0]),
        .BR_clock(BR_clock)
    );
////////////////////////CANAL Q
///////////PRBS
prbs#(.seed(9'h1AA))
    u_prbs_Q(
        .clock(clock),
        .i_enable(BR_clock),
        .i_reset(i_reset),
        .i_enb_tx(i_sw[0]),
        .o_output(o_prbs_Q)
    );
// /////////FIR_POLIFASICO
fir
    u_fir_Q(
        .clock(clock),
        .i_reset(i_reset),
        .i_sim(o_prbs_Q),
        .o_output(o_fir_Q),
        .i_enable(BR_clock),
        .i_enb_tx(i_sw[0]) 
    );

//////////dowsplamplig y slicer 
downsampling_slicer
    u_downsampling_slicer_Q(
        .i_fir_poli(o_fir_Q[10]),
        .clock(clock),
        .i_reset(i_reset),
        .o_reset_sinc(reset_sinc_Q),
        .i_enable(BR_clock),
        .i_sel_phase(i_sw[3:2]),
        .o_bit(o_down_slice_Q)
    );

///////////BER
BER
    u_BER_Q(
        .clock(clock),
        .i_reset(i_reset),
        .i_reset_sinc(reset_sinc_Q),
        .i_enable(BR_clock),
        .i_enb_rx(i_sw[1]),
        .i_PRBS(o_prbs_Q),
        .i_sim(o_down_slice_Q),
        .o_led(),
        .o_bits_count(bits_count_Q),
        .o_error_count(error_count_Q)
    );

//////CANAL I
///////////PRBS
prbs#(.seed(9'h1FE))
    u_prbs_I(
        .clock(clock),
        .i_enable(BR_clock),
        .i_reset(i_reset),
        .i_enb_tx(i_sw[0]),
        .o_output(o_prbs_I)
    );
fir
    u_fir_I(
        .clock(clock),
        .i_reset(i_reset),
        .i_sim(o_prbs_I),
        .o_output(o_fir_I),
        .i_enable(BR_clock),
        .i_enb_tx(i_sw[0]) 
    );

downsampling_slicer
    u_downsampling_slicer_I(
        .i_fir_poli(o_fir_I[10]),
        .clock(clock),
        .i_reset(i_reset),
        .o_reset_sinc(reset_sinc_I),
        .i_enable(BR_clock),
        .i_sel_phase(i_sw[3:2]),
        .o_bit(o_down_slice_I)
    );

BER
    u_BER_I(
        .clock(clock),
        .i_reset(i_reset),
        .i_reset_sinc(reset_sinc_I),
        .i_enable(BR_clock),
        .i_enb_rx(i_sw[1]),
        .i_PRBS(o_prbs_I),
        .i_sim(o_down_slice_I),
        .o_led(),
        .o_bits_count(bits_count_I),
        .o_error_count(error_count_I)
    );

assign fir_Q = o_fir_Q;
assign fir_I = o_fir_I;

// assign o_led[0]= (i_reset==1'b0) ? 1'b1 : 1'b0;
// assign o_led[1]= (i_sw[1]==1'b0) ? 1'b0 : 1'b1;
// assign o_led[2]= (i_sw[2]==1'b0) ? 1'b0 : 1'b1;

assign o_bits_count_Q = bits_count_Q;
assign o_bits_count_I = bits_count_I;
assign o_error_count_Q = error_count_Q;
assign o_error_count_I = error_count_I;

endmodule
