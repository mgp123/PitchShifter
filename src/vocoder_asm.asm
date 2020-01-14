section.data:
SIZE: dq 0
; punteros a la parte del stack donde se encuentan
hanning: dq 0
F1: dq 0
F2: dq 0
section.text:
global vocoder_asm
extern precalcular_hanning
extern ditfft2_asm
extern iditfft2_asm
vocoder_asm: ;void vocoder_asm(float* modulator, float* carrier, unsigned int window_size, float* buffer)
	push r12
	push r13
	push r14
	push r15
	push rbx

	mov r12, rdi
	mov r13, rsi
	mov edx, edx
	mov r14, rdx
	mov r15, rcx

	%define MODULATOR r12
	%define CARRIER r13
	%define OUTPUT r15
	%define WINDOW_SIZE r14

	shl r8, 32
	shr r8, 32
	sub r8, WINDOW_SIZE
	inc r8
	mov [SIZE], r8

	; generando espacio para hamming
	mov rdi, WINDOW_SIZE
	shl rdi, 2
	sub rsp, rdi


	; llamado a funcion de C que llena el arreglo con hanning
	mov rdi, rsp
	mov rsi , WINDOW_SIZE
	call precalcular_hanning
	mov [hanning], rsp


	; espacio en el stack para buffers
	mov rdi, WINDOW_SIZE
	shl rdi, 3
	sub rsp, rdi
	mov [F1], rsp
	sub rsp, rdi
	mov [F2], rsp

	xor rbx, rbx
	.ciclo:
	cmp rbx, [SIZE]; tamaño del modulator - windows size + 1
	jae .fin

	mov rdi, MODULATOR
	mov rsi, WINDOW_SIZE
	mov rdx, [F1]
	call ditfft2_asm

	mov rdi, CARRIER
	mov rsi, WINDOW_SIZE
	mov rdx, [F2]
	call ditfft2_asm

	xor rdi, rdi
	mov rsi, [F1]
	mov rdx, [F2]
	.aplicar_modulo:
		cmp rdi, WINDOW_SIZE
		je .antitransformar	

		movdqu xmm0, [rsi]
		mulps xmm0, xmm0
		haddps xmm0, xmm0
		sqrtps xmm0, xmm0
		pshufd xmm0, xmm0, 01010000b

		movdqu xmm1, [rdx]
		mulps xmm1, xmm0
		movdqu [rdx], xmm1

		add rsi, 16; avanzar  2 complejos
		add rdx, 16
		add rdi, 2
		jmp .aplicar_modulo


	.antitransformar:
	mov rdi, [F2]
	mov rsi, WINDOW_SIZE
	mov rdx, [F1]
	call iditfft2_asm


	xor rdi,rdi
	mov rsi, [F1]
	mov rdx, [hanning]
	.agregar_output:
		cmp rdi, WINDOW_SIZE
		je .fin_ciclo

		movdqu xmm0, [rsi]
		pshufd xmm0, xmm0, 1000b ; reordenamos la parte real abajo

		movsd xmm1, [rdx] ; multiplicacion por hannig
		mulps xmm0, xmm1

		movsd xmm1, [OUTPUT] ; agregar al output
		addps xmm1, xmm0
		movsd [OUTPUT], xmm1

		add OUTPUT, 8; se avanza 2 floats
		add rsi, 16; 2 complejos en F1
		add rdx, 8 ; 2 floats en hanning
		add rdi, 2
		jmp .agregar_output

	.fin_ciclo:
	mov rdi, WINDOW_SIZE
	shr rdi, 1; hop = window_size/2
	sub OUTPUT, rdi ; el OUTPUT esta desfazado adelante por el ultimo paso
	add MODULATOR, rdi
	add CARRIER, rdi
	add rbx, rdi
	jmp .ciclo

	.fin:
	mov rdi, WINDOW_SIZE
	shl rdi, 2
	add rsp, rdi ; el espacio por hanning
	shl rdi, 2
	sub rsp, rdi ; el espacio por F1 y F2

	pop rbx
	pop r15 
	pop r14 
	pop r13 
	pop r12
	ret


