; ------------------------------------------------------------
; fibonacci_estilo_gfg.s
; Autor: (OSCAR CORDOVA)
; Curso: Microprocesadores / Ensamblador
; Descripción:
;   Calcula la serie de Fibonacci F0..Fn (n entre 0 y 47).
;   Guarda todos los valores en SRAM (palabras 32 bits) en 0x20001000.
;   Incluye casos especiales (n = 0, n = 1).
;   Tiene puntos redundantes, algunos NOPs, etiquetas de prueba, etc.
; ------------------------------------------------------------

        AREA RESET, CODE, READONLY
        THUMB
        EXPORT __Vectors

__Vectors
        DCD __initial_sp
        DCD Reset_Handler
        ALIGN

; ------------------------------------------------------------
; Constantes
; ------------------------------------------------------------
FIB_BASE    EQU 0x20001000      ; dirección base en SRAM para guardar serie
MAX_N       EQU 47             ; máxima entrada permitida (para caber en uint32)

; ------------------------------------------------------------
; Variables (datos)
; ------------------------------------------------------------
        AREA |.data|, DATA, READWRITE

n_input     DCD 9               ; cámbialo si quieres otra n

; ------------------------------------------------------------
; Código principal
; ------------------------------------------------------------
        AREA |.text|, CODE, READONLY
        IMPORT __initial_sp
        EXPORT Reset_Handler

Reset_Handler
        PUSH    {r4-r7, lr}         ; protejo registros que usaré

        ; cargar n (entrada)
        LDR     r6, =n_input
        LDR     r0, [r6]             ; r0 = n_input

        ; caso especial: si n < 0 (no posible, pero lo checo)
        ; en práctica solo cuando n = 0 o 1 importa
        CMP     r0, #0
        BGE     ok_n1                ; si n >= 0 seguimos
        MOVS    r0, #0               ; si por error es negativo, lo pongo 0
ok_n1

        ; si n == 0 ? solo guardar F0
        CMP     r0, #0
        BEQ     caso_n0

        ; si n == 1 ? guardar F0, F1
        CMP     r0, #1
        BEQ     caso_n1

        ; si n > MAX_N, limitar
        CMP     r0, #MAX_N
        BLE     caso_general
        MOV     r0, #MAX_N
caso_general

        ; aquí empieza el flujo general (n >= 2 y <= MAX_N)
        ADDS    r1, r0, #1            ; r1 = número de términos = n + 1

        LDR     r2, =FIB_BASE         ; r2 apunta al buffer

        ; inicializar prev2, prev1
        MOVS    r4, #0                ; prev2 = F0
        MOVS    r3, #1                ; prev1 = F1

        ; guardar F0
        STR     r4, [r2], #4

        ; guardar F1
        STR     r3, [r2], #4

        ; contamos que ya guardamos 2 términos
        SUBS    r1, r1, #2

        ; loop para i = 3..(n+1)
loop_calc
        ADDS    r5, r4, r3            ; next = prev2 + prev1
        STR     r5, [r2], #4          ; guardar siguiente

        ; rotar
        MOV     r4, r3                ; prev2 = prev1
        MOV     r3, r5                ; prev1 = next

        ; instrucción "de choque" de estudiante
        NOP                           ; probando que no cause fallas

        SUBS    r1, r1, #1
        BNE     loop_calc

        B       fin

; ------------------------------------------------------------
; Casos especiales
; ------------------------------------------------------------
caso_n0
        ; si n = 0 ? solo F0
        LDR     r2, =FIB_BASE
        MOVS    r4, #0
        STR     r4, [r2], #4
        B       fin

caso_n1
        ; si n = 1 ? F0 y F1
        LDR     r2, =FIB_BASE
        MOVS    r4, #0
        STR     r4, [r2], #4
        MOVS    r3, #1
        STR     r3, [r2], #4
        B       fin

; ------------------------------------------------------------
fin
        POP     {r4-r7, lr}
bucle_fin
        B       bucle_fin             ; quedamos aquí para ver en Memoria y Debug

        END
