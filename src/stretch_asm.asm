section.data
	align 16
	;aca van las variables hardcodeadas
	pi: times 1 dd 3.141592654
	_pi_mask: dd 0.0,0.0, 3.141592654, 3.141592654
	_pi_negmask: dd 0.0,0.0, -3.141592654, -3.141592654
	_dos: times 4 dd 2.0
	_uno: times 1 dd 1.0
	_mask: dd 1.0, 1.0, -1.0, -1.0
	%define sizeof_float 4
	%define sizeof_complejo 8
	%define off_real 0
	%define off_img 4

section.text
	global stretch_asm
	extern malloc
	extern free
	extern sin
	extern calloc
	extern sqrt
	extern atan2

stretch_asm:
;float* stretch(float* audio, unsigned int size, float f, unsigned int window_size, unsigned int hop){
	;RDI -> audio (float* - 8B)
	;ESI -> size (uint - 4B)
	;XMM0 -> f (float - 4B)
	;EDX -> window_size (uint - 4B)
	;ECX -> hop (uint - 4B)

	PUSH RBP
	MOV RBP, RSP
	PUSH RBX
	PUSH R12
	PUSH R13
	PUSH R14
	PUSH R15
	SUB RSP, 8  ; Pila alineada
 
	; MUEVO TODO A REGISTROS Q SE PRESERVEN
	mov rbx, rdi
	mov r12d, esi
	movdqa xmm1, xmm0
	mov r13d, edx
	r14d, ecx

	%define audio rbx
	%define size r12d
	%define f xmm1
	%define window_size r13d
	%define hop r14d

	; Hago todos los pedidos de memoria que necesitaré:
	xor rax, rax   ;para q no se rompa malloc (?)
	xor rdi, rdi
	mov edi, window_size
	mov rsi, sizeof_float
	call calloc   ;lo inicializo en ceros

	push rax  
	;esp+8 tiene ahora phase
	xor rax, rax   ;para q no se rompa malloc (?)
	mov edi, window_size*sizeof_float
	sub rsp, 8
	call malloc    ;no necesito q esté en 0
	add rsp, 8
	push rax       ;pila alineada

	; Mi pila ahora:
	; esp+8: hanning (array de *windows_size* floats)
	; esp+16: phase (array de *windows_size* floats)

	xor rax, rax
	mov edi, window_size*sizeof_float
	call malloc
	push rax       ;a1 (pila desalineada)
	xor rax, rax
	mov edi, window_size*sizeof_float
	sub rsp, 8
	call malloc
	add rsp, 8
	push rax       ;a2 (pila alineada)
	xor rax, rax
	mov edi, window_size*sizeof_float*2
	call malloc
	push rax       ;s1 (pila desalineada)
	xor rax, rax
	mov edi, window_size*sizeof_float*2
	sub rsp, 8
	call malloc
	add rsp, 8
	push rax       ;s2 (pila alineada)

	cvtsi2ss xmm0, size
	divss xmm0, f
	cvtsi2ss xmm2, window_size
	addss xmm0, xmm2      ;size/f + window_size (nuevo_largo)
	cvttss2si edi, xmm0
	xor rsi, rsi
	mov rsi, 4
	call calloc
	push rax      ; output
	sub esp,8     ; (pila alineada)

	;la pila entonces queda:
	%define output esp+16
	%define s2 esp+24
	%define s1 esp+32
	%define a2 esp+40
	%define a1 esp+48
	%define phase esp+56
	%define hanning esp+62

	;necesito window_size-1 para la sgte parte (tenia window_size en xmm2)
	subss xmm2, [_uno]     ;chequear que esto ande

	mov ecx, window_size  ;i
	.init_hanning:
		movss xmm0, [pi]
		mov eax, ecx
		dec eax       ;necesito i-1 por invariante de ciclos en asm
		mulss xmm0, eax  ;pi*(i-1)
		divss xmm0, xmm2
		cvtss2sd xmm0, xmm0
		call sin
		cvtsd2ss xmm0, xmm0
		mulss xmm0, xmm0
		mov eax, ecx
		dec eax
		movss [hanning+eax*sizeof_float], xmm0
		loop .init_hanning

	;necesito:
	; size-window_size-hop
	; f*hop

	mov ecx, size
	sub ecx, window_size
	sub ecx, hop
	cvtsi2ss xmm3, hop
	mulss xmm3, f

	%define i ecx
	.ciclo:
		cmp i, 0
		je .fin
		mov r10d, window_size
		%define j r10d
		.ciclo_a:
			cmp r10d, 0
			jl .fin_a
			mov r11d, i
			add r11d, j
			movdqu xmm4, [audio+r11d*sizeof_float]
			mulps xmm4, [hanning+j*sizeof_float]
			movdqu [a1+j*sizeof_float], xmm4
			add r11d, hop
			movdqu xmm4, [audio+r11d*sizeof_float]
			mulps xmm4, [hanning+j*sizeof_float]
			movdqu [a2+j*sizeof_float], xmm4
			add r10, 4
			dec r10d, 4
			jmp .ciclo_a

		.fin_a:
		;preparo todo para llamar ditfft2
		push ecx
		sub esp, 8
		movdqa xmm0, xmm6
		movdqa xmm3, xmm7   ;la funcion no usa xmm6 ni 7, aprovecho eso en vez de bajar los datos a memoria para guardarlos
		mov rdi, a1
		mov esi, window_size
		mov rdx, s1
		call ditfft2
		mov rdi, a2
		mov esi, window_size
		mov rdx, s2
		call ditfft2
		movdqa xmm7, xmm3
		movdqa xmm6, xmm0
		add esp, 8
		pop ecx

		mov window_size r10d
		;%define j r10d
		sub j, 2
		.ciclo_3:
			cmp j, 0
			jl .fin_3
				
			;chequear... probablemente me complique al pedo

			movdqu xmm4, [s1+j*sizeof_complejo]  ;el float mas bajo es la parte real de s1[j]
		    ; xmm4: s1[j+1].img, s1[j+1].real, s1[j].img, s1[j].real
		    movdqu xmm5, [s2+j*sizeof_complejo]
		    ; xmm5: s2[j+1].img, s2[j+1].real, s2[j].img, s2[j].real
		    pshufd xmm6, xmm5, 10110001b
		    ; s2[j+1].real, s2[j+1].img, s2[j].real, s2[j].img

		    ; aprovecho acá para conseguir normas2
		    movdqu xmm2, xmm6
		    mulps xmm2, xmm2  ;j+1 r*r, j+1 i*i, j r*r, j i*i
		    movdqu xmm3, xmm2
		    pslldq xmm3, 4    ; 0.0   , j+1 r*r, j+1 i*i, j r*r
		    addps xmm2, xmm3  ; basura, norma**2 j+1, basura, norma**2 j
		    psllq xmm2, 8*sizeof_float
		    psrlq xmm2, 8*sizeof_float
		    sqrtps xmm2
		    ; DEBO PRESERVAR XMM2 HASTA MAS ABAJO

		    mulps xmm5, xmm4
		    mulps xmm6, xmm4
		    ; xmm5: [j+1]img*img, [j+1]real*real, [j]img*img, [j]real*real
		    ; xmm6: [j+1]img*real, [j+1]real*img, [j]img*real, [j]real*img
		    movdqu xmm4, xmm5
		    shufps xmm4, xmm6, 10001000b
		    ; xmm4: [j+1]real*img, [j]real*img, [j+1]real*real, [j]real*real
		    shufps xmm5, xmm6, 11011101b
		    ; xmm5: [j+1]img*real, [j]img*real, [j+1]img*img, [j]img*img
		    mulps xmm5, [_mask]
		    ; xmm5: -[j+1]img*real, -[j]img*real, [j+1]img*img, [j]img*img
		    addps xmm4, xmm5
		    ; xmm4: frac[j+1].img, frac[j].img, frac[j+1].real, frac[j].real
		    shufps xmm4, xmm4, 11011000b
		    ; xmm4: frac(j+1).img, frac(j+1).real, frac(j).img, frac(j).real
		    cvtps2pd xmm5, xmm4  ;j
		    psrldq xmm4, 8
		    cvtps2pd xmm6, xmm4  ;j+1

		    ;hacer cosas de push y demas (ecx, r10, los xmm)
		    ;PUSH
		    movdqa xmm0, xmm6
		    call atan2
		    movdqa xmm6, xmm0
		    movdqa xmm0, xmm5
		    call atan2
		    movdqa xmm5, xmm0
	 		;PUSH

		    cvtpd2ps xmm5, xmm5 ;v_angular j float
		    cvtpd2ps xmm6, xmm6 ;v_angular j+1 float
		    divss xmm5, f
		    divss xmm6, f
		    psrldq xmm5, 12   
		    pslldq xmm5, 12		
		    pslldq xmm6, 4
		    addps xmm5, xmm6    
		    pxor xmm6, xmm6
		    movq xmm6, [phase+j*sizeof_float]
		    addps xmm5, xmm6 
		    ; xmm5: 0,0, phase[j+1]+v_angular/f, phase[j]+v_angular/f 

		    .compare_pi_great:
		    movdqu xmm4, xmm5
		    movdqu xmm7, [_pi_mask]
		    cmpps xmm4, xmm7, EH   ;phase... > pi?
		    psrld xmm4, 31         ;si la rta era 11111 me queda un uno
		    cvtdq2ps xmm4, xmm4
		    mulps xmm4, xmm7       
		    mulps xmm4, [_dos]   ;entonces si era mayor a pi, le resto dos pi
		    ;me falta chequear si era menor a pi antes de modificar
		    movdqu xmm6, xmm5
		    cmpps xmm6, xmm7, 1H   ;phase... < pi?
		    psrld xmm6, 31         ;si la rta era 11111 me queda un uno
		    cvtdq2ps xmm6, xmm6
		    mulps xmm6, xmm7       
		    mulps xmm6, [_dos]   ;entonces si era mayor a pi, le sumo dos pi

		    subps xmm6, xmm4
		    addps xmm5, xmm6     ; 0.0, 0.0, phase[j+1], phase[j]


		    .rephased:
		    movdqu xmm0, xmm5
		    pslldq xmm0, 12
		    psrldq xmm0, 12    ;phase[j]
		    ;PUSH
		    call cos
		    mulss xmm0, xmm2
		    movdqu xmm3, xmm0
		    ;POP

		    movdqu xmm0, xmm5
		    pslldq xmm0, 12
		    psrldq xmm0, 12    ;phase[j]
		    ;PUSH
		    call sin
			mulss xmm0, xmm2
		    pslldq xmm0, 4
		    addps xmm3, xmm0   ;xmm2: 0.0,0.0,img,real   
		    ;POP

		    movdqu xmm0, xmm5
		    psrldq xmm0, 4     ;phase[j+1]
		    ;PUSH
		    call cos
		    mulss xmm0, xmm2
		    pslldq xmm0, 8
		    addps xmm3, xmm0   ;xmm2: 0.0, realj+1, imgj, realj
		    ;POP

		    movdqu xmm0, xmm5
		    psrldq xmm0, 4     ;phase[j+1]
		    ;PUSH
		    call sin
		    mulss xmm0, xmm2
		    pslldq xmm0, 8
		    addps xmm3, xmm0   ;xmm2: imgj+1, realj+1, imgj, realj
		    ;POP

		    ;ya no necesito mas las normas

		    movdqu [s2+j*sizeof_complejo], xmm3
		    pxor xmm3, xmm3
		    movdqu [s1+j*sizeof_complejo], xmm3
			sub j, 2
			jmp .ciclo_3
		.fin_3:

		;PUSH
		mov rdi, s2
		mov rsi, window_size
		mov rdx, s1
		call iditfft2
		;POP

		mov r10d, window_size
		;%define j r10d
		.ciclo_4:
			cmp j, 0
			jl .fin_4
			pxor xmm2, xmm2
			cvtsi2ss xmm2, i
			divss xmm2, f
			cvtss2si r11d, xmm2  ;inicio

			movdqu xmm3, [s1+j*sizeof_complejo]
			psllq xmm3, sizeof_float*8  ;me quedo solo con los reales
			: xmm3: j+1real, 0, jreal, 0
			movdqu xmm4, [hanning+j*sizeof_float]
			pslldq xmm4, 2*sizeof_float ;me quedo solo con j y j+1
			shufps xmm3, xmm3, 10001101b
			mulps xmm3, xmm4

			add r11d, j
			movq [output+r11d*sizeof_float], xmm3

			add j, 2
			jmp .ciclo_4
		.fin_4:

		;CHEQUEAR
		inc ecx
		jmp .ciclo
	
	.fin:

	;la pila entonces queda:
	;%define output esp+16
	;%define s2 esp+24
	;%define s1 esp+32
	;%define a2 esp+40
	;%define a1 esp+48
	;%define phase esp+56
	;%define hanning esp+62

	mov r15, output   ;tengo que guardarme este puntero
	add esp, 16
	add esp, 8        ;no tengo que hacerle free a output!
	mov rcx, 6
	.frees:
	pop rax
	call free
	loop .frees
	
	mov rax, r15 

	ADD RSP, 8
	POP R15
	POP R14
	POP R13
	POP R12
	POP RBX
	POP RBP

	ret







	