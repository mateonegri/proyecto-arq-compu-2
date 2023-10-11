.global app

// Configuraciones
    .equ SNAKE_LONGITUD_MAX, 15
    .equ SNAKE_LONGITUD_MIN, 2
    .equ TABLERO_ANCHO, 10
    .equ TABLERO_ALTO, 10
    .equ TABLERO_OUT_RANGE, (TABLERO_ALTO * TABLERO_ANCHO) + 1
    .equ LEFT, 0x40000
    .equ RIGHT, 0x08000
    .equ UP, 0x04000
    .equ DOWN, 0x20000
       
app:

//---------------- Inicialización GPIO --------------------

	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.		
	
	// Configurar GPIO 17 como input:
	mov X21, #0
	str w21,[x20,GPIO_GPFSEL1] 		// Coloco 0 en Function Select 1 (base + 4)  
    
    // X0 contiene la dirección base del framebuffer (NO MODIFICAR)
	
	mov w3, 0x001F    		
	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
//---------------- Main code --------------------
	bl pintarFondo

    mov x19, 0x20000

startGame:

    mov x2, 208
    mov x1, 16
    lsl x2, x2, 9
    add x13, x2, x1
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado

    add x1, x13, xzr
    add x1, x1, 384

    str x1, [x19, 0]  // Aca se "traba" el codigo. Deja de ejecutar

    bl pintarSerpienteInicio

   // bl dibujarManzanaInicio

   mov x18, 0

loopGame: 

    bl actualizarDireccion

    b loopGame

dibujarManzanaInicio:  // Esto anda mal
    mov w3, 0xF800
    mov x5, 6114  // numero random para aparecer la primera manzana
    add x11, x10, x5
    mov x9, x11  // Tengo en x9 la pos de la manzana

    bl rectangulo

    ret

pintarSerpienteInicio: 
    mov x2, 2
    mov w3, 0x07E0
    add x11, x1, xzr
loopSerpiente: // A x11 le paso el valor de x1 (valor del framebuffer con la pos de la serpiente)
    bl rectangulo
    add x11, x1, xzr   
    sub x11, x11, 96
    sub x2, x2, 1
    bne loopSerpiente

    add x11, x11, 96
    str x11, [x19, 8]  // Guardo pos de la siguiente pos de la snake en el array pos 1.

    ret

pintarFondo: 
	mov x22,512         	// Tamaño en Y 
loop1:
	mov x21,512         	// Tamaño en X 
loop2:
	sturh w3,[x10]	   	// Setear el color del pixel N
	add x10,x10,2	   	// Siguiente pixel
	sub x21,x21,1	   		// Decrementar el contador X
	cbnz x21,loop2	   	// Si no terminó la fila, saltar
	sub x22,x22,1	   		// Decrementar el contador Y
	cbnz x22,loop1	  	// Si no es la última fila, saltar

// Ya pinte toda la pantalla de un color, ahora cambio la direccion base, para ir pintando los cuadrados. 

    mov w3, 0xFFFF // Cambio de color a BLANCO
    add x10, x0, 0 // X10 contiene la dirección base del framebuffer
    mov x7, 10 // Contador cuadrados por fila
    mov x8, 11 // Contador cantidad de filas
    mov x9, 1 // Flag para color

// Calculo direccion de inicio del primer cuadrado (x,y) = (16,16)

    mov x12, 96 // Lo que le tengo que sumar al framebuffer cada vez que termino un cuadrado de una fila  

    mov x22, 16
    mov x21, 16
    lsl x22, x22, 9
    add x13, x22, x21
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado

dibujarCuadrados:

    mov x7, 10 // Nueva fila vuelvo a empezar el contador

    cmp x8, 11   // Si el contador de cantidad de filas es 8, salteo la instruccion de sumarle 64
    beq cont1   // es decir, de bajar una fila. Si no es 8, le sumo 64 a la direccion de inicio y voy a bajar una fila

    mov x12, 48288   // ( Tamaño del cuadrado - 1 * 1024 ) + ( TamBorde * 2 ) + (TamCuadrado*2)
    add x13, x13, x12
    mov x12, 96

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
    b startGame

// funcion que le paso como parametro la direccion inicial de framebuffer en x11, y 
// dibuja el cuadrado a partir de esa direccion. Los cuadrados son de 48x48. Cuando
// termino una fila, le sumo 1024 a x11 para que baje a la siguiente y repito eso 48 veces.

rectangulo: 
    mov x22, 48 // Tamaño en Y 
dibujarY:
    mov X21, 48 // Tamaño en X
dibujarX:
    sturh w3,[x11]	   	// Setear el color del pixel N
	add x11,x11,2	   	// Siguiente pixel
	sub x21,x21,1	   		// Decrementar el contador X
	cbnz x21,dibujarX	   	// Si no terminó la fila, saltar 
    sub x11, x11, 96    // Regresar x11 al inicio de la fila
    add x11, x11, 1024  // Avanzar a la siguiente fila
    sub x22,x22,1	   		// Decrementar el contador Y
	cbnz x22,dibujarY	  	// Si no es la última fila, saltar
    ret

actualizarDireccion:   
    // Lectura de puertos de entrada y devuelvo direccion 
    // 0 --> derecha, 1 --> izquierda, 2 --> arriba, 3 --> abajo

    bl inputRead

    sub x28, x3, RIGHT
    cbz x28, derecha
    sub x28, x23, LEFT
    cbz x28, izquierda
    sub x28, X21, DOWN
    cbz x28, abajo
    sub x28, x22, UP
    cbz x28, arriba

    ret

izquierda:
    mov x18, 1

    mov w3, 0xFFFF
    // bl test

    ret

arriba:
    mov x18, 2

    mov w3, 0xFFFF
    // bl test

    ret

abajo:
    mov x18, 3

    mov w3, 0xFFFF
    // bl test

    ret

derecha:
    mov x18, 0

    mov w3, 0xFFFF
    // bl test

    ret


test:
	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
	mov x2,512         	// Tamaño en Y
loop6:
	mov x1,512         	// Tamaño en X
loop10:
	sturh w3,[x10]	   	// Setear el color del pixel N
	add x10,x10,2	   	// Siguiente pixel
	sub x1,x1,1	   		// Decrementar el contador X
	cbnz x1,loop10	   	// Si no terminó la fila, saltar
	sub x2,x2,1	   		// Decrementar el contador Y
	cbnz x2,loop6	  	// Si no es la última fila, saltar

    ret
