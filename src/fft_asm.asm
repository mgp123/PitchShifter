section.data:
extern rotaciones
extern calloc
conjugador: dd 1.0, -1.0, 1.0, -1.0
%define precalculados rotaciones


section.text:
global ditfft2_asm
global iditfft2_asm
global convolucion_circular_asm
global convolucion_lineal_directa

; supone que el tamaño es potencia de 2 y <= 2048
; en precalculados estaria un puntero a los complejos precalculados
%define MAX_WINDOW_SIZE 2048
%define MAX_WINDOW_POWER 11

ditfft2_asm:
	mov rcx, rdx
	mov rdx, 1
	call ditfft2_aux_asm
	ret

ditfft2_aux_asm:
	cmp rsi, 2
	je .2elementos

	push r12
	push r13
	push r14
	push r15

	mov r12, rdi
	shr rsi, 1  ; size = size / 2
	mov r13, rsi
	mov r14, rdx
	mov r15, rcx

	%define ARREGLO r12
	%define SIZE_2 r13
	%define HOP r14
	%define BUFFER r15

	shl rdx, 1
	call ditfft2_aux_asm

	mov rdi, HOP
	shl rdi, 2 ; un float son 4 bytes
	add rdi, ARREGLO
	mov rsi, SIZE_2
	mov rdx, HOP
	shl rdx, 1
	mov rcx, SIZE_2
	shl rcx, 3 ;un complejo son 8 bytes
	add rcx, BUFFER
	call ditfft2_aux_asm

	; logaritmo en base 2 de size del arreglo, en rsi
	mov rdi, SIZE_2
	mov rsi, 1
	.ciclo_log:
	cmp rdi, 1
	je .log_encontrado
	add rsi, 1
	shr rdi, 1
	jmp .ciclo_log
	.log_encontrado:

	; esto se usa para poder saber que tan espaciados estan los valores precalculados
	mov rcx, MAX_WINDOW_POWER
	sub rcx, rsi
	mov rsi, 8 ; un complejo son 8 bytes
	shl rsi, cl
	%define espaciado rsi
	mov rdi, precalculados
	%define rotacion_actual rdi


	mov rax, 0
	%define indice rax

	.ciclo:
	cmp rax, SIZE_2
	je .fin
	;-------
	;cuerpo
	;-------

	;las rotaciones complejas estaran en xmm0
	movsd xmm0, [rotacion_actual]
	add rotacion_actual,espaciado
	movsd xmm1, [rotacion_actual]
	movlhps xmm0, xmm1  ; xmm0 = | rot1.im | rot1.re | rot0.im | rot0.re |
	add rotacion_actual,espaciado

	; cargado de buffer[i+size/2]
	mov rdx, indice
	add rdx, SIZE_2
	shl rdx, 3 ; un complejo son 8 bytes
	add rdx, BUFFER
	movdqu xmm1, [rdx] ; xmm1 = | buf1.im | buf1.re | buf0.im | buf0.re |

	; multiplicacion compleja de buffer con rotaciones
	movdqa xmm2, xmm1
	mulps xmm2, xmm0
	; xmm2 = | rot1.im * buf1.im | rot1.re * buf1.re | rot0.im * buf0.im | rot0.re * buf0.re |
	hsubps xmm2, xmm2
	; xmm2 = |..|..| rot1.re * buf1.re - rot1.im * buf1.im | rot0.re * buf0.re  - rot0.im * buf0.im |
	pshufd xmm3, xmm1, 10110001b
	; xmm3 = | buf1.re | buf1.im | buf0.re | buf0.im |
	mulps xmm3, xmm0
	; xmm3 = | rot1.im * buf1.re | rot1.re * buf1.im | rot0.im * buf0.re | rot0.re * buf0.im |
	haddps xmm3, xmm3
	; xmm3 = |..|..| rot1.im * buf1.re + rot1.re * buf1.im | rot0.im * buf0.re + rot0.re * buf0.im |
	punpckldq xmm2, xmm3
	; xmm2 contiene ahora la mul compleja
	; xmm2 = |rot1.im * buf1.re + rot1.re * buf1.im | rot1.re * buf1.re - rot1.im * buf1.im | rot0.im * buf0.re + rot0.re * buf0.im | rot0.re * buf0.re  - rot0.im * buf0.im |

	mov rdx, indice
	shl rdx, 3 ; un complejo son 8 bytes
	add rdx, BUFFER
	movdqu xmm1, [rdx] ; xmm1 = | buf_p1.im | buf_p1.re | buf_p0.im | buf_p0.re |
	movdqa xmm3, xmm1
	addps xmm1, xmm2
	movdqu [rdx], xmm1

	subps xmm3, xmm2
	mov rdx, indice
	add rdx, SIZE_2
	shl rdx, 3 ; un complejo son 8 bytes
	add rdx, BUFFER
	movdqu [rdx], xmm3
	add rax, 2
	jmp .ciclo

	.fin:
	pop r15
	pop r14
	pop r13
	pop r12
	ret

	.2elementos:
	movss xmm0, [rdi] ; xmm0 =  Arr 0
	shl rdx, 2
	add rdx, rdi   ; xmm1 = Arr 1
	movss xmm1, [rdx]

	movdqa xmm2, xmm0
	addss xmm2, xmm1
	movsd [rcx], xmm2 
	subss xmm0, xmm1
	movsd [rcx + 8], xmm0
	ret


iditfft2_asm:
	push rsi
	push rdx

	mov rcx, rdx
	mov rdx, 1
	movdqu xmm4, [conjugador]
	call iditfft2_aux_asm

	pop rdx
	pop rsi

	mov rax, 0
	cvtsi2ss xmm0, esi
	pshufd xmm0, xmm0, 0
	; xmm0 = | N | N | N | N | con N el tamaño del buffer
	.ciclo:
	cmp rax, rsi
	je .fin
	movdqu xmm1, [rdx]
	divps xmm1, xmm0
	movdqu [rdx], xmm1
	add rdx, 16 ; aumenta el puntero del buffer 2 complejos. (16 bytes)
	add rax, 2
	jmp .ciclo
	.fin:
	ret

iditfft2_aux_asm:
	cmp rsi, 2
	je .2elementos

	push r12
	push r13
	push r14
	push r15

	mov r12, rdi
	shr rsi, 1  ; size = size / 2
	mov r13, rsi
	mov r14, rdx
	mov r15, rcx

	shl rdx, 1
	call iditfft2_aux_asm

	mov rdi, HOP
	shl rdi, 3 ;un complejo son 8 bytes
	add rdi, ARREGLO
	mov rsi, SIZE_2
	mov rdx, HOP
	shl rdx, 1
	mov rcx, SIZE_2
	shl rcx, 3 ;un complejo son 8 bytes
	add rcx, BUFFER
	call iditfft2_aux_asm

	; logaritmo en base 2 de size del arreglo, en rsi
	mov rdi, SIZE_2
	mov rsi, 1
	.ciclo_log:
	cmp rdi, 1
	je .log_encontrado
	add rsi, 1
	shr rdi, 1
	jmp .ciclo_log
	.log_encontrado:

	; esto se usa para poder saber que tan espaciados estan los valores precalculados
	mov rcx, MAX_WINDOW_POWER
	sub rcx, rsi
	mov rsi, 8 ; un complejo son 8 bytes
	shl rsi, cl
	mov rdi, precalculados

	mov rax, 0

	.ciclo:
	cmp rax, SIZE_2
	je .fin
	;-------
	;cuerpo
	;-------

	;las rotaciones complejas estaran en xmm0
	movsd xmm0, [rotacion_actual]
	add rotacion_actual,espaciado
	movsd xmm1, [rotacion_actual]
	movlhps xmm0, xmm1  ; xmm0 = | rot1.im | rot1.re | rot0.im | rot0.re |
	; como es la inversa se realiza el conjugado.
	; xmm4 = | -1  |  1  |  -1  |  1  |
	mulps xmm0, xmm4
	add rotacion_actual,espaciado

	; cargado de buffer[i+size/2]
	mov rdx, indice
	add rdx, SIZE_2
	shl rdx, 3 ; un complejo son 8 bytes
	add rdx, BUFFER
	movdqu xmm1, [rdx] ; xmm1 = | buf1.im | buf1.re | buf0.im | buf0.re |

	; multiplicacion compleja de buffer con rotaciones
	movdqa xmm2, xmm1
	mulps xmm2, xmm0
	; xmm2 = | rot1.im * buf1.im | rot1.re * buf1.re | rot0.im * buf0.im | rot0.re * buf0.re |
	hsubps xmm2, xmm2
	; xmm2 = |..|..| rot1.re * buf1.re - rot1.im * buf1.im | rot0.re * buf0.re  - rot0.im * buf0.im |
	pshufd xmm3, xmm1, 10110001b
	; xmm3 = | buf1.re | buf1.im | buf0.re | buf0.im |
	mulps xmm3, xmm0
	; xmm3 = | rot1.im * buf1.re | rot1.re * buf1.im | rot0.im * buf0.re | rot0.re * buf0.im |
	haddps xmm3, xmm3
	; xmm3 = |..|..| rot1.im * buf1.re + rot1.re * buf1.im | rot0.im * buf0.re + rot0.re * buf0.im |
	punpckldq xmm2, xmm3
	; xmm2 contiene ahora la mul compleja
	; xmm2 = |rot1.im * buf1.re + rot1.re * buf1.im | rot1.re * buf1.re - rot1.im * buf1.im | rot0.im * buf0.re + rot0.re * buf0.im | rot0.re * buf0.re  - rot0.im * buf0.im |

	mov rdx, indice
	shl rdx, 3 ; un complejo son 8 bytes
	add rdx, BUFFER
	movdqu xmm1, [rdx] ; xmm1 = | buf_p1.im | buf_p1.re | buf_p0.im | buf_p0.re |
	movdqa xmm3, xmm1
	addps xmm1, xmm2
	movdqu [rdx], xmm1

	subps xmm3, xmm2
	mov rdx, indice
	add rdx, SIZE_2
	shl rdx, 3 ; un complejo son 8 bytes
	add rdx, BUFFER
	movdqu [rdx], xmm3
	add rax, 2
	jmp .ciclo

	.fin:
	pop r15
	pop r14
	pop r13
	pop r12
	ret

	.2elementos:
	movsd xmm0, [rdi] ; xmm0 =  Arr 0
	shl rdx, 3 ;un complejo son 8 bytes
	add rdx, rdi   ; xmm1 = Arr 1
	movsd xmm1, [rdx]

	movdqa xmm2, xmm0
	addps xmm2, xmm1
	movsd [rcx], xmm2 
	subps xmm0, xmm1
	movsd [rcx + 8], xmm0
	ret

convolucion_circular_asm:
	shl rdx, 32
	shr rdx, 32
	%define SIZE rdx
	%define ARREGLOA rdi
	%define ARREGLOB rsi


	; se genera el espacio en el stack para los complejos
	mov rax, SIZE
	mov r8, rsp
	shl rax, 3
	sub rsp, rax
	mov r9, rsp

	xor rax, rax
	.ciclo:
	cmp rax, SIZE
	je .fin

	movdqu xmm0, [ARREGLOA] ; xmm0 = | bufA1.im | bufA1.re | bufA0.im | bufA0.re |
	movdqu xmm1, [ARREGLOB] ; xmm1 = | bufB1.im | bufB1.re | bufB0.im | bufB0.re |

	movdqu xmm2, [ARREGLOA + 16] ; xmm2 = | bufA3.im | bufA3.re | bufA2.im | bufA2.re |
	movdqu xmm3, [ARREGLOB + 16] ; xmm3 = | bufB3.im | bufB3.re | bufB2.im | bufB2.re |

	movdqa xmm4, xmm0
	mulps xmm4, xmm1

	movdqa xmm5, xmm2
	mulps xmm5, xmm3

	hsubps xmm4, xmm5

	pshufd xmm0, xmm0, 10110001b
	mulps xmm0, xmm1

	pshufd xmm2, xmm2, 10110001b
	mulps xmm2, xmm3

	haddps xmm0, xmm2

	; xmm4 = | A3.re*B3.re - A3.im*B3.im | A2.re*B2.re - A2.im*B2.im | A1.re*B1.re - A1.im*B1.im | A0.re*B3.re - A0.im*B3.im |
	; xmm0 = | A3.re*B3.im + A3.im*B3.re | A2.re*B2.im + A2.im*B2.re | A1.re*B1.im + A1.im*B1.re | A0.re*B3.im + A0.im*B3.re |

	movdqa xmm1, xmm4
	punpckldq xmm1, xmm0
	movdqu [r9], xmm1

	punpckhdq xmm4, xmm0
	movdqu [r9 + 16], xmm4

	; se aumenta 4 complejps
	add r9, 32

	add rax, 4
	add ARREGLOA, 32
	add ARREGLOB, 32

	jmp .ciclo

	.fin:
	mov rdi, rsp ; producto
	mov rsi, rdx ; size
	mov rdx, rcx ; buffer donde se coloca el resultado

	push r8
	call iditfft2_asm

	pop r8
	mov rsp, r8 ; desarmamos el espacio en el stack
	ret



; float* convoucion lineal (float* a, unsigned int size_a, float* b , unsigned int size_b)

convolucion_lineal_directa:
	push r12
	push r13
	push r14
	push r15
	sub rsp, 8

	mov r12, rdi
	mov r13, rsi
	mov r14, rdx
	mov r15, rcx

	%define ARREGLO_A r12
	%define SIZE_A r13
	%define ARREGLO_B r14
	%define SIZE_B r15

	mov rdi, SIZE_A
	add rdi, SIZE_B
	mov rsi, 4

	; calloc (sizeA + sizeB, sizeof(float))
	call calloc

	; se ignoran los ultimos elementos si el size no es multiplo de 4
	sub SIZE_A, 3
	sub SIZE_B, 3


	mov rdx, rax
	%define OUTPUT rdx

	mov rcx, ARREGLO_B
	%define ARREGLO_B_inicio rcx

	xor rdi, rdi
	.cicloA:
		cmp rdi, SIZE_A
		jae .fin
		movdqu xmm0, [ARREGLO_A]	

		xor rsi, rsi
		.cicloB:
			cmp rsi, SIZE_B
			jae .finCicloA	

			movdqu xmm1, [ARREGLO_B]	

			pshufd xmm2, xmm0, 0 ; el primer elemento de xmm0
			mulps xmm2, xmm1
			movdqu xmm3, [OUTPUT]
			addps xmm2, xmm3
			movdqu [OUTPUT], xmm2
			add OUTPUT, 4 ; se mueve un solo delay	

			pshufd xmm2, xmm0, 01010101b ; el segundo elemento de xmm0
			mulps xmm2, xmm1
			movdqu xmm3, [OUTPUT]
			addps xmm2, xmm3
			movdqu [OUTPUT], xmm2
			add OUTPUT, 4 ; se mueve un solo delay	

			pshufd xmm2, xmm0, 10101010b ; el tercer elemento de xmm0
			mulps xmm2, xmm1
			movdqu xmm3, [OUTPUT]
			addps xmm2, xmm3
			movdqu [OUTPUT], xmm2
			add OUTPUT, 4 ; se mueve un solo delay	

			pshufd xmm2, xmm0, 11111111b ; el cuarto elemento de xmm0
			mulps xmm2, xmm1
			movdqu xmm3, [OUTPUT]
			addps xmm2, xmm3
			movdqu [OUTPUT], xmm2
			add OUTPUT, 4 ; se mueve un solo delay	

			add rsi, 4  
			add ARREGLO_B, 16 ;  4 elementos de B  	

			jmp .cicloB

	.finCicloA:
	add rdi, 4
	add ARREGLO_A, 16 ;  4 elementos de A 

	; reposicionamiento de OUTPUT
	mov OUTPUT, rdi
	shl OUTPUT, 2
	add OUTPUT, rax

	; reposicionamiento de ARREGLO_B
	mov ARREGLO_B, ARREGLO_B_inicio

	jmp .cicloA

	.fin:
	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	ret








