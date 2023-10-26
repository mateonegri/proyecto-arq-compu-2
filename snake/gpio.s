//--------DEFINICIÓN DE FUNCIONES-----------//
    .global inputRead    

	.equ GPIO_GPSET0, 	0x1C
	.equ GPIO_GPCLR0, 	0x28

	//DESCRIPCION: Lee el boton en el GPIO17. 
//------FIN DEFINICION DE FUNCIONES-------//

inputRead: 	
	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.	
	ldr w22, [x20, GPIO_GPLEV0] 	// Leo el registro GPIO Pin Level 0 y lo guardo en X22
	and x23,x22,0x40000
	and x21,x22,0x20000
	and x3,x22,0x08000
	and x22,x22,0x04000

    br x30 		//Vuelvo a la instruccion link

redOff:
  mov w20,#0b1000
  str w20,[x29,GPIO_GPSET0]
  br x30

redOn:
  mov w20,#0b1000
  str w20,[x29,GPIO_GPCLR0]
  br x30

greenOff:
  mov w20,#0b0100
  str w20,[x29,GPIO_GPSET0]
  br x30

greenOn:
  mov w20,#0b0100
  str w20,[x29,GPIO_GPCLR0]
  br x30

