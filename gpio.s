//--------DEFINICIÓN DE FUNCIONES-----------//
    .global inputRead    
	//DESCRIPCION: Lee el boton en el GPIO17. 
//------FIN DEFINICION DE FUNCIONES-------//

inputRead: 	
	ldr w22, [x20, GPIO_GPLEV0] 	// Leo el registro GPIO Pin Level 0 y lo guardo en X22
	and X23,X2,0x40000
	and X22,X2,0x20000
	and X3,X2,0x08000
	and X2,X2,0x04000
	
    br x30 		//Vuelvo a la instruccion link
