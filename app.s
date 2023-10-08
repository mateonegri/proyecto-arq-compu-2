.global app
.extern pintarFondo

// variables accesibles por el nombre creo, se pueden guardar valores
// usan el str, y traer el valor usando el ldr

    .section .bss

    .section .data
    snake_posiciones:
    .space SNAKE_LONGITUD_MAX * 4
    snake_posicionSiguiente:
    .space 4
    snake_direccionCola:
    .space 4
    snake_longitudActual:
    .space 4 
    snake_direccion:
    .space 4
    manzana_posicionActual:
    .space 4
    input:
    .space 4

// Configuraciones
    .equ SNAKE_LONGITUD_MAX, 15
    .equ SNAKE_LONGITUD_MIN, 2
    .equ TABLERO_ANCHO, 10
    .equ TABLERO_ALTO, 10
    .equ TABLERO_OUT_RANGE, (TABLERO_ALTO * TABLERO_ANCHO) + 1

app:

//---------------- Inicialización GPIO --------------------

	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.		
	
	// Configurar GPIO 17 como input:
	mov X21,#0
	str w21,[x20,GPIO_GPFSEL1] 		// Coloco 0 en Function Select 1 (base + 4)  
    
    // X0 contiene la dirección base del framebuffer (NO MODIFICAR)
	
	mov w3, 0x001F    		
	add x10, x0, 0		// X10 contiene la dirección base del framebuffer
//---------------- Main code --------------------
	bl pintarFondo

startGame:
    // Primero hay que inicializar la serpiente en el centro de la pantalla

    bl inicializarJuego

    // La cabeza empieza en el cuadrado 50. Tengo que sumarle 1024 10 veces a el cuadrado
    // 5 de la primer fila de cuadrados.

    add x11, x1, xzr

    bl pintarSerpienteInicio

    bl dibujarManzanas

loopGame: 



    b loopGame

inicializarJuego:

    mov x3, SNAKE_LONGITUD_MIN
    mov x4, snake_longitudActual
    str x3, [x4, 0]

    add x1, x10, xzr
    mov x5, 10816
    add x1, x1, x5 // Supuestamente en x1, tengo la pos inicial de la cabeza de la serpiente

    mov x3, x1
    mov x4, snake_posiciones
    str x3, [x4, 0]  // Lo guardo en la pos1 del array

    mov x3, 6119
    mov x4, manzana_posicionActual
    str x3, [x4, 0]

    mov x3, 0        // Initial direction (right)
    mov x4, snake_direccion
    str x3, [x3, 0]

    ret

dibujarManzanas:
    mov w3, 0xF800
    mov x4, manzana_posicionActual
    mov x5, 6114  // numero random para aparecer la primera manzana
    add x11, x4, x5

    str x11, [x4, 0]   // guardo en manzana_posicionActual el valor de la pos de la manzana actual
    
    bl rectangulo

    ret

pintarSerpienteInicio: 
    mov x2, 3
    mov w3, 0x07E0
loopSerpiente: // A x11 le paso el valor de x1 (valor del framebuffer con la pos de la serpiente)
    bl rectangulo
    add x11, x11, 1024   // Bajo una fila para pintar la cola
    sub x2, x2, 1
    bne loopSerpiente
    ret

pintarFondo: 
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
    add x10, x13, xzr // guardo en x10 la direccion del primer cuadrado

dibujarCuadrados:

    mov x7, 10 // Nueva fila vuelvo a empezar el contador

    cmp x8, 11   // Si el contador de cantidad de filas es 8, salteo la instruccion de sumarle 64
    beq cont1   // es decir, de bajar una fila. Si no es 8, le sumo 64 a la direccion de inicio y voy a bajar una fila

    mov x12, 48256   // ( Tamaño del cuadrado - 1 * 1024 ) + ( TamBorde * 2 ) + (TamCuadrado*2)
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
    b startGame

// funcion que le paso como parametro la direccion inicial de framebuffer en x11, y 
// dibuja el cuadrado a partir de esa direccion. Los cuadrados son de 48x48. Cuando
// termino una fila, le sumo 1024 a x11 para que baje a la siguiente y repito eso 48 veces.

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
