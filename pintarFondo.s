.global pintarFondo

// X0 contiene la dirección base del framebuffer (NO MODIFICAR)
	
	mov w3, 0xF800    	// 0xF800 = ROJO	
	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
    mov x3, 1024

	mov x2,512         	// Tamaño en Y 
loop1:
	mov x1,512         	// Tamaño en X 
loop2:
	sturh w3,[x10]	   	// Setear el color del pixel N
	add x10,x10,2	   	// Siguiente pixel
	sub x1,x1,1	   		// Decrementar el contador X
	cbnz x1,loop2	   	// Si no terminó la fila, saltar
	sub x2,x2,1	   		// Decrementar el contador Y
	cbnz x2,loop1	  	// Si no es la última fila, saltar

// Ya pinte toda la pantalla de un color, ahora cambio la direccion base, para ir pintando los cuadrados. 


    mov w3, 0xFFFF // Cambio de color a BLANCO
    add x10, x0, 0 // X10 contiene la dirección base del framebuffer
    mov x7, 8 // Contador cuadrados por fila
    mov x8, 9 // Contador cantidad de filas
    mov x9, 1 // Flag para color

// Calculo direccion de inicio del primer cuadrado (x,y) = (16,16)

    mov x12, 96 // Lo que le tengo que sumar al framebuffer cada vez que termino un cuadrado de una fila  

    mov x2, 16
    mov x1, 16
    lsl x2, x2, 9
    add x13, x2, x1
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado

dibujarCuadrados:

    mov x7, 10 // Nueva fila vuelvo a empezar el contador

    cmp x8, 11   // Si el contador de cantidad de filas es 8, salteo la instruccion de sumarle 64
    beq cont1   // es decir, de bajar una fila. Si no es 8, le sumo 64 a la direccion de inicio y voy a bajar una fila

    mov x12, 48288   // ( Tamaño del cuadrado - 1 * 1024 ) + ( TamBorde * 2 ) + (TamCuadrado*2)
    add x13, x13, x12
    mov x12, 120

cont1:

    sub x8, x8, 1
    cbz x8, end

dibujarCuadradosXFila:

    cmp x7, 10
    beq cont

    add x13, x13, x12

cont:
    add x11, x13, 0
    bl rectangulo
    sub x7, x7, 1
    cbz x7, dibujarCuadrados

    cmp x9, 1
    beq cambiarColorNegro
    bne cambiarColorBlanco

   cambiarColorNegro:
	mov w3, 0x0000 // Cambiamos el color a negro
	mov x9, 0
    b dibujarCuadradosXFila

   cambiarColorBlanco:
 	mov w3, 0xFFFF // Cambiamos el color a blanco
	mov x9, 1
	b dibujarCuadradosXFila

end:
    infLoop:
        b infLoop



// funcion que le paso como parametro la direccion inicial de framebuffer en x11, y 
// dibuja el cuadrado a partir de esa direccion. Los cuadrados son de 60x60. Cuando
// termino una fila, le sumo 1024 a x11 para que baje a la siguiente y repito eso 60 veces.

rectangulo: 
    mov x2, 48 // Tamaño en Y 
dibujarY:
    mov x1, 48 // Tamaño en X
dibujarX:
    sturh w3,[x11]	   	// Setear el color del pixel N
	add x11,x11,2	   	// Siguiente pixel
	sub x1,x1,1	   		// Decrementar el contador X
	cbnz x1,dibujarX	   	// Si no terminó la fila, saltar 
    sub x11, x11, 96    // Regresar x11 al inicio de la fila
    add x11, x11, 1024  // Avanzar a la siguiente fila
    sub x2,x2,1	   		// Decrementar el contador Y
	cbnz x2,dibujarY	  	// Si no es la última fila, saltar
    ret