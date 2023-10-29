.global app
.extern inputRead

// Configuraciones
    .equ SNAKE_LONGITUD_MAX, 15
    .equ SNAKE_LONGITUD_MIN, 2
    .equ TABLERO_ANCHO, 10
    .equ TABLERO_ALTO, 10
    .equ TABLERO_OUT_RANGE, (TABLERO_ALTO * TABLERO_ANCHO) + 1
    .equ LEFT, 0x08000
    .equ RIGHT, 0x20000
    .equ UP, 0x04000
    .equ DOWN, 0x40000
       
app:

//---------------- Inicialización GPIO --------------------

	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.		
	
	// Configurar GPIO 17 como input:
	mov X21, #0
	str w21,[x20,GPIO_GPFSEL1] 		// Coloco 0 en Function Select 1 (base + 4)  


  	// Configuro GPIO 2 y 3 como Output (001 6-8 y 9-11)
	mov x21,#0x240
    str w21,[x20, GPIO_GPFSEL1] // (direccion base)

    
    // X0 contiene la dirección base del framebuffer (NO MODIFICAR)
	
	mov w3, 0x001F    		
	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
//---------------- Main code --------------------
	bl pintarFondo

    mov x2, 208
    mov x1, 16
    lsl x2, x2, 9
    add x13, x2, x1
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado

    add x1, x13, xzr
    add x1, x1, 384

    ldr x19, =ARRAY_START
    str x1, [x19]

    bl pintarSerpienteInicio

    add x10, x0, 0		// X10 contiene la dirección base del framebuffer
    
    mov x22, 208
    mov x21, 16
    lsl x22, x22, 9
    add x13, x22, x21
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado
    add x11, x13, 0
    add x11, x11, 576

    str x11, [x19, #16]

    bl inicializarManzanas

    bl dibujarManzana

    mov x6, 0  // x6 nos dice la direccion actual de la serpiente

loopGame: 

    bl actualizarDireccion

    bl desplazarPosicion

    mov x21, 0

    bl checkBodyCollision

    cmp x21, 1
    beq endGame

    bl checkBorderCollision

    cmp x21, 1
    beq endGame
    
    bl checkAppleCollision

    cmp x21, 1
    beq extendSnake

continuePlaying:

    bl delay

    bl pintarTablero

    bl pintarSerpiente

    bl dibujarManzana

    b loopGame

pintarSerpienteInicio: 
    mov x28, x30

    mov x2, 2
    mov w3, 0x07E0

    ldr x11, [x19] 
loopSerpiente: // A x11 le paso el valor de x1 (valor del framebuffer con la pos de la serpiente)
    bl rectangulo
    add x11, x1, xzr   
    sub x11, x11, 96
    subs x2, x2, 1
    cmp x2, 0
    bne loopSerpiente

    add x11, x11, 96
    str x11, [x19, #8]  // Guardo pos de la siguiente pos de la snake en el array pos 1.
    mov x2, 2

    br x28

pintarFondo: 
    mov x28, x30

    add x10, x0, 0
    mov w3, 0x001F 

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

pintarTablero:
    mov x28, x30
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

    cmp x8, 11   // Si el contador de cantidad de filas es 10, salteo la instruccion de sumarle 64
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

    br x28

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

    mov x28, x30

    bl inputRead

    sub x27, x3, RIGHT
    cbz x27, derecha
    sub x27, x23, LEFT
    cbz x27, izquierda
    sub x27, X21, DOWN
    cbz x27, abajo
    sub x27, x22, UP
    cbz x27, arriba

return:

    br x28

izquierda:
    mov x6, 1

    b return

arriba:
    mov x6, 2

    b return

abajo:
    mov x6, 3

    b return

derecha:
    mov x6, 0

    b return


test:

    mov w3, 0x001F

	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
	mov x22,512         	// Tamaño en Y
loop6:
	mov x21,512         	// Tamaño en X
loop10:
	sturh w3,[x10]	   	// Setear el color del pixel N
	add x10,x10,2	   	// Siguiente pixel
	sub x21,x21,1	   		// Decrementar el contador X
	cbnz x21,loop10	   	// Si no terminó la fila, saltar
	sub x22,x22,1	   		// Decrementar el contador Y
	cbnz x22,loop6	  	// Si no es la última fila, saltar

    b endGame

desplazarPosicion:

    mov x28, x30

    mov x15, x2 // En x2 tengo la longitud actual de la serpiente
    sub x15, x15, 1 // Le resto 1 porque tengo que cambiar todas las pos menos la pos 0
    mov x16, x2
    lsl x16, x16, 3
    sub x16, x16, 8 // x16 = Longitud*8 - 8

    ldr x4, [x19, x16] // Guardo en x4 el valor de cola antes de cambiar, por si despues entra en el extend snake

    for:
    cmp x15, 0 // para comparar i con la pos base del array (CABEZA)
    beq forCont

    // hace lo que esta dentro del for snake_posiciones[i] = snake_posiciones[i-1];
    sub x16, x16, 8 // Le resto 8 a x16 para tener la pos [i - 1]
    ldr x13, [x19, x16] // x13 = snake_posiciones[i-1]
    add x16, x16, 8 // Le sumo 8 para volver al offset de la pos i
    str x13, [x19, x16] // snake_posiciones[i] = snake_posiciones[i-1]
    sub x16, x16, 8 // Le resto 8 para pasar al offset de la pos siguiente

    sub x15, x15, 1

    b for
forCont:

    cmp x6, 0
    beq movDerecha
    cmp x6, 1
    beq movIzquierda
    cmp x6, 2
    beq movArriba
    cmp x6, 3
    beq movAbajo

continuar:

    br x28


    movDerecha:
        ldr x1, [x19]
        add x1, x1, 96  // Muevo la pos de la cabeza a la derecha y la guardo en el array
        str x1, [x19]
        b continuar

    movIzquierda:
        ldr x1, [x19]
        sub x1, x1, 96  // Muevo la pos de la cabeza a la izquierda y la guardo en el array
        str x1, [x19]
        b continuar

     movArriba:
        ldr x1, [x19]
        mov x21, 49152
        sub x1, x1, x21  // Muevo la pos de la cabeza para arriba y la guardo en el array
        str x1, [x19]
        b continuar
    
     movAbajo:
        ldr x1, [x19]
        mov x21, 49152
        add x1, x1, x21  // Muevo la pos de la cabeza para abajo y la guardo en el array
        str x1, [x19]
        b continuar


pintarSerpiente:
    mov x28, x30

    mov x15, x2
    mov x16, 0
    mov w3, 0x07E0

paintLoop:
    cmp x15, 0
    beq finishPaint

    ldr x11, [x19, x16]
    bl rectangulo
    add x16, x16, 8
    sub x15, x15, 1

    b paintLoop

finishPaint:

    br x28

checkAppleCollision:

    mov x28, x30  
    ldr x17, [x19]  // Traigo la cabeza de la serpiente
    mov x15, x2
    lsl x15, x15, 3
    ldr x9, [x19, x15] // Traigo la manzana
    cmp x17, x9  // Comparo la cabeza con la manzana
    beq collisionDetected5  // Si son iguales, colision
    mov x21, 0  
    b return2

collisionDetected5:

    mov x21, 1  

return2:

    br x28  

extendSnake:

    add x2, x2, 1  // Aumento la longitud de la serpiente en 1
    mov x15, x2    // x15 = longitud de la serpeinte
    lsl x15, x15, 3 // x15 * 8
    sub x15, x15, 8 // X15 - 8 = posiciones-1 --> porque tengo q tener en cuenta que la cabeza esta en la pos0

    cmp x2, 15
    beq win

    // Yo se que en x4 siempre voy tener el valor de cola antes de desplazarPosicion, me aseguro de que la nuevos pos no pise otra pos.

    str x4, [x19, x15] // Cargo la nueva posicion al array

    b continuePlaying

checkBodyCollision:

    mov x28, x30
    mov x15, x2  // Load the length of the snake
    cmp x15, 2  // If the snake length is 0, no collision
    beq noCollision
    sub x15, x15, 1
    ldr x16, [x19]  // Load the current position of the snake's head

    mov x22, 8

checkLoop:

    ldr x17, [x19, x22]  // Load a body segment's position
    cmp x17, x16  // Compare it with the head position
    beq collisionDetected  // If they are the same, a collision occurred
    add x22, x22, 8  // Move to the next body segment
    subs x15, x15, 1  // Decrement the counter
    bne checkLoop

noCollision:

    mov x21, 0  // Set a flag for no collision
    b return3

collisionDetected:

    mov x21, 1  // Set a flag for collision

return3:

    br x28

checkBorderCollision:

    mov x28, x30

    ldr x17, [x19]  // Traigo la pos de la cabeza

    add x10, x0, 0 // X10 contiene la dirección base del framebuffer

    // Calculo direccion de inicio del primer cuadrado (x,y) = (16,16)

    mov x22, 16
    mov x21, 16
    lsl x22, x22, 9
    add x13, x22, x21
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado

    mov x23, 0


    // Ahora en x13 tengo el valor minimo para checkear limites

    cmp x17, x13     // Si la cabeza de la snake < que el minimo del tablero --> choco con el borde superior
    blt collisionDetected1
    
leftBoundCheck:

    mov x18, x17
    cmp x18, x13
    blt collisionLeftBound

    add x13, x13, 1024
    add x23, x23, 1

    cmp x23, 479
    bne leftBoundCheck

    b continueLeftCheck

collisionLeftBound:

    sub x13, x13, 96 // Me voy al pixel inmediato del borde de arriba
    cmp x18, x13
    bge collisionDetected1

    add x13, x13, 96 // Vuelvo el pixel a su pos original y sigo con el loop

    add x13, x13, 1024
    add x23, x23, 1

    cmp x23, 479
    bne leftBoundCheck

continueLeftCheck:

    mov x23, 0
    mov x22, 16
    mov x21, 16
    lsl x22, x22, 9
    add x13, x22, x21
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado

    add x13, x13, 960 // Le sumo 960 ( = 96*10) para irme a la direccion del primer punto del borde derecho

rightBoundCheck:

    mov x18, x17
    cmp x18, x13
    bge collisionRightBound

    add x13, x13, 1024
    add x23, x23, 1

    cmp x23, 479
    bne rightBoundCheck

    b continueRightCheck

collisionRightBound:    
    add x13, x13, 64 // Le sumo ambos borde para ir al pixel que sigue inmediatamente en la fila de abajo
    cmp x18, x13
    blt collisionDetected1

    sub x13, x13, 64
    
    add x13, x13, 1024
    add x23, x23, 1

    cmp x23, 479
    bne rightBoundCheck

 continueRightCheck:

    mov x23, 0
    mov x22, 16
    mov x21, 16
    lsl x22, x22, 9
    add x13, x22, x21
    lsl x13, x13, 1
    add x13, x13, x10 // En x13 tengo la direccion de inicio del framebuffer para el primer cuadrado

    mov x22, 491520      // Le sumo 491520 (48*1024*10) para irme al ultimo punto del tablero
    add x13, x13, x22 

    cmp x17, x13
    bge collisionDetected1
    
    mov x21, 0
    b return1

collisionDetected1:

    mov x21, 1

return1:

    br x28

dibujarManzana: 

    mov x28, x30

    mov w3, 0xF800
    mov x15, x2
    lsl x15, x15, 3
    ldr x11, [x19, x15]
    bl rectangulo

    br x28

inicializarManzanas:
    mov x28, x30

    add x11, x11, 49152
    str x11, [x19, #24]
    sub x11, x11, 288
    mov x15, 147456
    sub x11, x11, x15
    str x11, [x19, #32]
    add x11, x11, 480
    sub x11, x11, 49512
    str x11, [x19, #40]
    mov x15, 294912
    add x11, x11, x15
    str x11, [x19, #48]
    sub x11, x11, 384
    sub x11, x11, 49512
    str x11, [x19, #56]
    sub x11, x11, 288
    mov x15, 148536
    sub x11, x11, x15
    str x11, [x19, #64]
    ldr x11, [x19, #24]
    str x11, [x19, #72]
    add x11, x11, 49512
    sub x11, x11, 288
    str x11, [x19, #80]
    mov x15, 148536
    sub x11, x11, x15
    str x11, [x19, #88]

    br x28

delay:
	movz x21, 0x10, lsl #16
delay1: 
	sub x21,x21,#1
	cbnz x21, delay1
    
    ret

win:

    bl greenOn
    b win
    
    // Prender led verdes y terminar juego

endGame:
    bl redOn
    b endGame

    // Prender los led rojos y terminar el juego


