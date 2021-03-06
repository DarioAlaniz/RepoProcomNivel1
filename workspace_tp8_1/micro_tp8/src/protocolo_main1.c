
#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xgpio.h"
#include "platform.h"
#include "xuartlite.h"
#include "xil_printf.h"
#include "microblaze_sleep.h"

#define PORT_IN	 		XPAR_U_MICRO_2_AXI_GPIO_0_DEVICE_ID //XPAR_GPIO_0_DEVICE_ID
#define PORT_OUT 		XPAR_U_MICRO_2_AXI_GPIO_0_DEVICE_ID //XPAR_GPIO_0_DEVICE_ID
//como es el mismo puerto que lo uso como input/output le asigno la misma ID

//Device_ID Operaciones
#define def_SOFT_RST            0
#define def_ENABLE_MODULES      1
#define def_LOG_RUN             2
#define def_LOG_READ            3

XGpio GpioOutput; 		//referencia de salida
XGpio GpioParameter; 	//referencia de parametro
XGpio GpioInput; 		//referencia de entrada
u32 GPO_Value;
u32 GPO_Param;
XUartLite uart_module; 	//para inicializar el uart

//Funcion para recibir 1 byte bloqueante
//XUartLite_RecvByte((&uart_module)->RegBaseAddress)

int main()
{
	init_platform(); 	//inicializa la plataforma
	int Status;
	XUartLite_Initialize(&uart_module, 0); 			//como tenemos uno solo entonces hay un solo dispositivo
	//incializo el GPIO
	GPO_Value=0x00000000;
	GPO_Param=0x00000000;
	;

	Status=XGpio_Initialize(&GpioInput, PORT_IN); 	//la posicion de memoria y le asigno el ID
	if(Status!=XST_SUCCESS){
        return XST_FAILURE;
    }
	Status=XGpio_Initialize(&GpioOutput, PORT_OUT);
	if(Status!=XST_SUCCESS){
		return XST_FAILURE;
	}
	XGpio_SetDataDirection(&GpioOutput, 1, 0x00000000); 	//lo defino como salida con todos ceros
	XGpio_SetDataDirection(&GpioInput, 1, 0xFFFFFFFF); 		//lo defino como entrada

	u32 value;
	u32 gpio_w_c,gpio_w;
	u32 Ber_l,Error_l;
	u32* gpio_w_p;
	u64 Ber,Error;
	unsigned char trama;
	unsigned char trama_i_o[2]={0xA1,0x40};
	unsigned char data_output; //dato que envia para comprobar que llegaron los datos y sirve para enviar el dato pedido
	/*
	 * maximo de 15 bytes para trama corta pero solo transmito 4, 1 del comando
	 * y 3 para los leds
	 */
	u32 datos_rec[4];
	unsigned char s_size;	         //guardo el tama?o de los datos que siempre son 4 para trama corta
	unsigned char i;

	//trama_i_o[0] = 0xA1;
	//trama_i_o[2] = 0x40;
	void recivido(){                                    //para enviar un dato que llego el dato enviado
		//XUartLite_ResetFifos(&uart_module);
		//print(&trama_i_o[0]);
		xil_printf("%c",trama_i_o[0]);
		xil_printf("%c",data_output);
		xil_printf("%c",trama_i_o[1]);
//		while(XUartLite_IsSending(&uart_module)){}
//		XUartLite_Send(&uart_module, &trama_i_o[0], 1);
//		while(XUartLite_IsSending(&uart_module)){}
//		XUartLite_Send(&uart_module, &data_output, 1);
//		while(XUartLite_IsSending(&uart_module)){}
//		XUartLite_Send(&uart_module, &trama_i_o[1], 1);
//		return;
	}
	//-------------------------------------------------------------------------------
	//		funcion para escribir en el gpio
	//-------------------------------------------------------------------------------
	void write(){
		XGpio_DiscreteWrite(&GpioOutput, 1,(0xFF7FFFFF&(*gpio_w_p)));
		XGpio_DiscreteWrite(&GpioOutput, 1,(0x00800000|(*gpio_w_p)));
		XGpio_DiscreteWrite(&GpioOutput, 1,(0xFF7FFFFF&(*gpio_w_p)));
	}

	void send(u64 a,u32 b){
		int i;
		for(i=b;i>=0;i=i-8){
			data_output= (char) ((a >> i) & 0xFF);
			recivido();
		}
	}

	while(1){

		gpio_w_p=&gpio_w;

		read(stdin,&trama,1); 		//lee el registro de entrada del uart y lo guarda en la poscion de memoria de cabesera y lea un byte
									//sino funciona probar con "XUartLite_Recv() o XUartLite_RecvByte() "
//-------------------------------------------------------------------------------
//		recepcion de trama
//-------------------------------------------------------------------------------
		if((0xF0 & trama)== 0xA0 ){					// obtengo el inicio de la trama y si es trama corta o larga, 1010 inicio de trama y corta
			s_size= (0x0F & trama);                 //obtengo la cantidad de bytes
			for (i=0;i<s_size;i++){
				datos_rec[i]= XUartLite_RecvByte((&uart_module)->RegBaseAddress); 	//obtengo cada byte
			}
		}
		read(stdin,&trama,1);
		if ((0xF0 & trama)==0x40){
			data_output=0xF0;     	//comprueba que recivio bien la trama
			recivido();
		}
		else{
			data_output=0x2F;	 	//comprueba que no recivio bien la trama
			recivido();
		}
//		gpio_w_c = (datos_rec[1] << 24U);					//desplazo a los bit mas significativos el campo command
//0000_0001_0000_0000_0000_0000_0000_0001

//-------------------------------------------------------------------------------
//		funcionamiento
//-------------------------------------------------------------------------------
		switch(datos_rec[0]){
		case 'w':
			if(datos_rec[1]==1 || datos_rec[1]==2){
				gpio_w_c = (datos_rec[1] << 24U);
				gpio_w = gpio_w_c + datos_rec[2];
				write();
			}
			else if(datos_rec[1]==3 || datos_rec[1]==6){//pido BER_Error
				gpio_w_c = (datos_rec[1] << 24U);	//desplazo a los bit mas significativos el campo command
				gpio_w = gpio_w_c;
				write();					//escribo en el gpio con el comando para guardar el estado del BER y ERROR
				switch(datos_rec[2]){
				case 1:
					gpio_w_c = (datos_rec[1]==3) ? (0x11 <<24U) : (0x12 <<24U);	//comando para leer la parte baja del BER
					gpio_w = gpio_w_c | 0x01;
					write();
					Ber_l = XGpio_DiscreteRead(&GpioInput, 1); 	//guardo la parte baja del BER
					gpio_w = gpio_w_c | 0x02;		//pido la parte alta del BER
					write();
					Ber = ((u64) (XGpio_DiscreteRead(&GpioInput, 1)))<<32 ;	//guardo la parte alta del BER,consultar por que no guarda el valor!!!!
					//Ber_Q = 0xFFFFFFFFFFFFFFFF;
					Ber = Ber + Ber_l;
					send(Ber,56);									//mando los 64
					break;
				case 2:
					gpio_w_c = (datos_rec[1]==3) ? (0x11 <<24U) : (0x12 <<24U);	//comando para leer la parte baja del BER
					gpio_w = gpio_w_c | 0x04;
					write();
					Error_l = XGpio_DiscreteRead(&GpioInput, 1); 	//guardo la parte baja del BER
					gpio_w = gpio_w_c | 0x08;		//pido la parte alta del BER
					write();
					Error = ((u64)XGpio_DiscreteRead(&GpioInput, 1))<<32;	//guardo la parte alta del BER
					Error = Error + Error_l;
					send(Error,56);
					break;
				case 3:
					gpio_w_c = (datos_rec[1]==3) ? (0x11 <<24U) : (0x12 <<24U);	//comando para leer la parte baja del BER
					gpio_w = gpio_w_c | 0x01;
					write();
					Ber_l = XGpio_DiscreteRead(&GpioInput, 1); 	//guardo la parte baja del BER
					gpio_w = gpio_w_c | 0x02;		//pido la parte alta del BER
					write();
					Ber = ((u64) (XGpio_DiscreteRead(&GpioInput, 1)))<<32 ;	//guardo la parte alta del BER,consultar por que no guarda el valor!!!!
					//Ber_Q = 0xFFFFFFFFFFFFFFFF;
					Ber = Ber + Ber_l;
					send(Ber,56);
					//send(Q_error_l);
					break;
				case 4:
					gpio_w_c = (datos_rec[1]==3) ? (0x11 <<24U) : (0x12 <<24U);	//comando para leer la parte baja del BER
					gpio_w = gpio_w_c | 0x04;
					write();
					Error_l = XGpio_DiscreteRead(&GpioInput, 1); 	//guardo la parte baja del BER
					gpio_w = gpio_w_c | 0x08;		//pido la parte alta del BER
					write();
					Error = ((u64)XGpio_DiscreteRead(&GpioInput, 1))<<32;	//guardo la parte alta del BER
					Error = Error + Error_l;
					send(Error,56);
					break;
				}
			}
			break;
		case 'r':
			XGpio_DiscreteWrite(&GpioOutput,1, (u32) 0x00000000);	//apago para identificar que llego el comando r
			value = XGpio_DiscreteRead(&GpioInput, 1); 				//leo el GPIO de entrada y lo guardo en una variable
			data_output = (char)(value&(0x0000000F));
			recivido();
			break;
		default:
			XGpio_DiscreteWrite(&GpioOutput, 1, (u32)0x00000FFF);
			}
        }
	cleanup_platform();
	return 0;
}



