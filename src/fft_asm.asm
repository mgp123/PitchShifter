section.data:
numeros: times 1024 dq 0  
rotacion1: db 0
rotacion2: db 0

%define precalculados numeros


section.text:
global ditfft2_asm

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
	cmp rcx, 2
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
	mov rsi, precalculados
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


	.2elementos:
	movss xmm0, [ARREGLO] ; xmm0 =  Arr 0
	mov rdx, HOP
	shl rdx, 2
	add rdx, ARREGLO   ; xmm1 = Arr 1
	movss xmm1, [rdx]

	movss xmm2, xmm0
	addss xmm2, xmm0
	movsd xmm0, [BUFFER]
	subss xmm0, xmm1
	movsd xmm0, [BUFFER + 8]

	.fin:
	pop r15
	pop r14
	pop r13
	pop r12
	ret









