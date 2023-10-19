//--------DEFINICIÓN DE FUNCIONES-----------//
    .global inputRead    
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
