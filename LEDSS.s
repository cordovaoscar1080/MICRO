; OSCAR CORDOVA RODRIGUEZ
; ACTIVIDAD 3

    AREA RESET, CODE
    EXPORT  Reset_Handler
    ENTRY

Reset_Handler

; primero hay que prender los relojes para los puertos
    LDR R0, =0x40021018     ; RCC_APB2ENR
    LDR R1, [R0]
    ORR R1, R1, #0x10       ; prender reloj del puerto C
    STR R1, [R0]
    LDR R1, [R0]
    ORR R1, R1, #0x04       ; prender reloj del puerto A
    STR R1, [R0]

; configurar los pines de entrada (PA0 y PA1)
    LDR R0, =0x40010800     ; GPIOA_CRL
    LDR R1, [R0]
    ORR R1, R1, #0x44       ; PA0 y PA1 como entrada
    STR R1, [R0]

; configurar el pin del led (PC13)
    LDR R0, =0x40011004     ; GPIOC_CRH
    LDR R1, [R0]
    BIC R1, R1, #0x00F00000  ; limpiar los bits de PC13
    ORR R1, R1, #0x00200000  ; PC13 como salida
    STR R1, [R0]

; apagar el led al inicio (poner PC13 en 1)
apagar_led
    LDR R0, =0x4001100C     ; GPIOC_ODR
    LDR R1, [R0]
    ORR R1, R1, #8192       ; el bit 13
    STR R1, [R0]

; inicializar banderas a cero
    LDR R5, =0x20000000     ; direccion de la bandera 1 (generado)
    MOV R6, #0
    STR R6, [R5]
    LDR R5, =0x20000004     ; direccion de la bandera 2 (ordenado)
    STR R6, [R5]

; === BUCLE PRINCIPAL ===
bucle_principal
    LDR R0, =0x40010808     ; GPIOA_IDR, para leer los pines
    LDR R1, [R0]            ; leer el puerto
    AND R1, R1, #3          ; solo me importan los pines 0 y 1

    CMP R1, #0              ; es la combinacion 00?
    BEQ es_cero

    CMP R1, #1              ; es la combinacion 01?
    BEQ es_uno

    CMP R1, #2              ; es la combinacion 10?
    BEQ es_dos

    B bucle_principal       ; si no es ninguna, volver a checar

es_cero
    ; apagar el led
    LDR R0, =0x4001100C     ; GPIOC_ODR
    LDR R1, [R0]
    ORR R1, R1, #(1 << 13)
    STR R1, [R0]

    ; limpiar banderas
    LDR R5, =0x20000000     ; bandera generado
    MOV R6, #0
    STR R6, [R5]
    LDR R5, =0x20000004     ; bandera ordenado
    STR R6, [R5]
    B bucle_principal

es_uno
    ; checar si ya se generaron los numeros
    LDR R5, =0x20000000     ; cargar bandera
    LDR R6, [R5]
    CMP R6, #1
    BEQ esperar_en_uno      ; si ya se generaron, no hacer nada

    BL generar_numeros      ; llamar a la funcion que genera numeros
    
    ; encender el led (poner PC13 en 0)
    LDR R0, =0x4001100C     ; GPIOC_ODR
    LDR R1, [R0]
    BIC R1, R1, #(1 << 13)
    STR R1, [R0]
    
    ; poner la bandera de generado en 1
    LDR R5, =0x20000000
    MOV R6, #1
    STR R6, [R5]

esperar_en_uno
    ; aqui se queda esperando hasta que pongan "00"
    LDR R0, =0x40010808
    LDR R1, [R0]
    AND R1, R1, #3
    CMP R1, #0
    BEQ es_cero             ; si es 00, ir al inicio
    B esperar_en_uno        ; si no, seguir esperando

es_dos
    ; primero checar si los numeros ya se generaron
    LDR R5, =0x20000000     ; cargar bandera generado
    LDR R6, [R5]
    CMP R6, #0
    BEQ bucle_principal     ; si la bandera es 0, no hacer nada y volver al inicio

    ; ahora checar si ya se ordenaron
    LDR R5, =0x20000004     ; cargar bandera ordenado
    LDR R6, [R5]
    CMP R6, #1
    BEQ esperar_en_dos      ; si ya se ordenaron, no volver a hacerlo

    BL ordenar_numeros      ; llamar a la funcion que ordena

    ; poner la bandera de ordenado en 1
    LDR R5, =0x20000004
    MOV R6, #1
    STR R6, [R5]
    
    ; prender el led por si acaso
    LDR R0, =0x4001100C
    LDR R1, [R0]
    BIC R1, R1, #(1 << 13)
    STR R1, [R0]
    
esperar_en_dos
    ; se queda esperando hasta que pongan "00"
    LDR R0, =0x40010808
    LDR R1, [R0]
    AND R1, R1, #3
    CMP R1, #0
    BEQ es_cero             ; si es 00, ir al inicio
    B esperar_en_dos

; === SUBRUTINAS ===

generar_numeros
    ; genera 100 numeros y los guarda en 0x20000100
    PUSH {LR}
    LDR R0, =0x20000100     ; donde guardar los numeros
    MOV R1, #100            ; contador
    MOV R2, #42             ; semilla

loop_generar
    ; X_n+1 = (a * X_n + c)
    MOV R3, #11035          ; multiplicador 'a' (simplificado)
    MUL R4, R2, R3
    MOV R5, #12345          ; incremento 'c'
    ADD R2, R4, R5          ; nuevo numero es el nuevo R2

    STR R2, [R0]            ; guardar el numero
    ADD R0, R0, #4          ; mover a la siguiente direccion

    SUB R1, R1, #1          ; restar 1 al contador
    CMP R1, #0
    BNE loop_generar
    
    POP {PC}

ordenar_numeros
    ; ordena los 100 numeros de menor a mayor
    PUSH {LR}
    LDR R0, =0x20000100     ; direccion de los numeros
    MOV R1, #99             ; contador de pasadas

loop_externo
    LDR R0, =0x20000100     ; reiniciar puntero en cada pasada
    MOV R2, #99

loop_interno
    LDR R3, [R0]            ; numero actual
    LDR R4, [R0, #4]        ; numero siguiente

    CMP R3, R4              ; comparar
    BGT intercambiar        ; si R3 > R4, saltar
    
continuar_interno
    ADD R0, R0, #4          ; mover puntero
    SUB R2, R2, #1
    CMP R2, #0
    BNE loop_interno

    SUB R1, R1, #1
    CMP R1, #0
    BNE loop_externo

    B fin_ordenar
    
intercambiar
    STR R4, [R0]            ; guardar el menor primero
    STR R3, [R0, #4]        ; guardar el mayor despues
    B continuar_interno

fin_ordenar
    POP {PC}

    END