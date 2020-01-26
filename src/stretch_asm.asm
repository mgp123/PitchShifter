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

;obs: push16 y pop16 no desalinean la pila porque son movimientos de 16 bytes
%macro PUSH16 1
movdqu [rsp], %1
sub rsp, 16
%endmacro

%macro POP16 1
add rsp, 16
movdqu %1, [rsp]
%endmacro

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
	PUSH16 f   ;lo dejamos abajo de todos los push que vamos a hacer ahora
	call calloc   ;lo inicializo en ceros

	push rax  
	;rsp+8 tiene ahora phase
	xor rax, rax   ;para q no se rompa malloc (?)
	mov edi, window_size*sizeof_float
	sub rsp, 8
	call malloc    ;no necesito q esté en 0

	add rsp, 8
	push rax       ;pila alineada

	; Mi pila ahora:
	; rsp+8: hanning (array de *windows_size* floats)
	; rsp+16: phase (array de *windows_size* floats)

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
	sub rsp,8     ; (pila alineada)

	;la pila entonces queda:
	%define output rsp+16
	%define s2 rsp+24
	%define s1 rsp+32
	%define a2 rsp+40
	%define a1 rsp+48
	%define phase rsp+56
	%define hanning rsp+62
	;y en rsp+70 mi xmm0.... tengo que acomodar la pila cuando termina todo

	movdqu f, [rsp+70]   ;restauramos f

	;necesito window_size-1 para la sgte parte (tenia window_size en xmm2)
	subss xmm2, [_uno]     ;chequear que esto ande

	mov ecx, window_size  ;i
	dec ecx
	.init_hanning:
		cmp ecx, 0
		jl .fin
		movss xmm0, [pi]
		mulss xmm0, ecx  ;pi*i
		divss xmm0, xmm2
		cvtss2sd xmm0, xmm0
		
		PUSH16 f
		push rcx
		sub rsp, 8
		
		call sin
		
		add rsp, 8
		pop rcx
		POP16 f
		
		cvtsd2ss xmm0, xmm0
		mulss xmm0, xmm0
		mov rax, [hanning]
		movss [rax+ecx*sizeof_float], xmm0
		dec ecx

	.fin:
	;necesito:
	; size-window_size-hop
	; f*hop

	mov ecx, size
	sub ecx, window_size
	sub ecx, hop
	cvtsi2ss xmm3, hop
	mulss xmm3, f   
	cvtss2si eax, xmm3     
	movdqu [rsp+70], eax
	%define fxhop, rsp+70  

	%define i ecx
	.ciclo:
		cmp i, 0
		je .fin
		mov r10d, window_size
		dec r10d
		%define j r10d
		.ciclo_a:
			cmp j, 0
			jl .fin_a
			mov r11d, i
			add r11d, j
			movdqu xmm4, [audio+r11d*sizeof_float]
			mov rax, [hanning]
			mulps xmm4, [rax+j*sizeof_float]
			mov rax, [a1]
			movdqu [rax+j*sizeof_float], xmm4
			add r11d, hop
			movdqu xmm4, [audio+r11d*sizeof_float]
			mov rax, [hanning]
			mulps xmm4, [rax+j*sizeof_float]
			mov rax, [a2]
			movdqu [rax+j*sizeof_float], xmm4
			add r10, 4
			dec r10d, 4
			jmp .ciclo_a

		.fin_a:
		;preparo todo para llamar ditfft2
		push i
		sub rsp, 8
		PUSH16 f
		mov rdi, [a1]
		mov esi, window_size
		mov rdx, [s1]
		call ditfft2
		mov rdi, [a2]
		mov esi, window_size
		mov rdx, [s2]
		call ditfft2
		POP16 f
		add rsp, 8
		pop i

		mov window_size r10d
		;%define j r10d
		sub j, 2    ;mi ciclo hace de a 2 (la de C es de a 1)
					;window_size es potencia de 2 asi que anda
		.ciclo_3:
			cmp j, 0
			jl .fin_3
				
			;chequear... probablemente me complique al pedo

			mov rax, [s1]
			movdqu xmm4, [rax+j*sizeof_complejo]  ;el float mas bajo es la parte real de s1[j]
		    ; xmm4: s1[j+1].img, s1[j+1].real, s1[j].img, s1[j].real
		    mov rax, [s2]
		    movdqu xmm5, [rax+j*sizeof_complejo]
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
		    ; DEBO PRESERVAR XMM2 HASTA MAS ABAJO (tiene las normas)

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
		    push i
		    push j
		    PUSH16 f
		    PUSH16 XMM2
		    PUSH16 XMM5

		    movdqa xmm0, xmm6
		    psrldq xmm0, 4     ;frac.imaginaria (j)
		    movdqa xmm1, xmm6
		    pslldq xmm1, 12
		    psrldq xmm1, 12    ;frac.real (j)
		    call atan2
		    movdqa xmm6, xmm0
		    POP16 XMM5
		    PUSH16 XMM6
		    movdqa xmm0, xmm5
		    psrldq xmm0, 4     ;frac.imaginaria (j+1)
		    movdqa xmm1, xmm5
		    pslldq xmm1, 12
		    psrldq xmm1, 12    ;frac.real (j+1)
		    call atan2
		    movdqa xmm5, xmm0
	 		
	 		POP16 XMM6
	 		POP16 XMM2
	 		POP16 f
	 		pop j
	 		pop i

		    cvtpd2ps xmm5, xmm5 ;v_angular j float
		    cvtpd2ps xmm6, xmm6 ;v_angular j+1 float
		    divss xmm5, f
		    divss xmm6, f
		    psrldq xmm5, 12   
		    pslldq xmm5, 12		
		    pslldq xmm6, 4
		    addps xmm5, xmm6    
		    pxor xmm6, xmm6
		    mov rax, [phase]
		    movq xmm6, [rax+j*sizeof_float]
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
		    PUSH16 XMM2
		    PUSH16 f
		    push i
		    push j

		    movdqu xmm0, xmm5
		    pslldq xmm0, 12
		    psrldq xmm0, 12    ;phase[j]
		    call cos
		    mulss xmm0, xmm2
		    movdqu xmm3, xmm0

		    movdqu xmm0, xmm5
		    pslldq xmm0, 12
		    psrldq xmm0, 12    ;phase[j]
		    call sin
			mulss xmm0, xmm2
		    pslldq xmm0, 4
		    addps xmm3, xmm0   ;xmm3: 0.0,0.0,img,real   

		    movdqu xmm0, xmm5
		    psrldq xmm0, 4     ;phase[j+1]
		    call cos
		    mulss xmm0, xmm2
		    pslldq xmm0, 8
		    addps xmm3, xmm0   ;xmm3: 0.0, realj+1, imgj, realj

		    movdqu xmm0, xmm5
		    psrldq xmm0, 4     ;phase[j+1]
		    call sin
		    mulss xmm0, xmm2
		    pslldq xmm0, 8
		    addps xmm3, xmm0   ;xmm3: imgj+1, realj+1, imgj, realj

		    pop j
		    pop i
		    POP16 f
		    POP16 XMM2

		    ;ya no necesito mas las normas (xmm2)

		    mov rax, [s2]
		    movdqu [rax+j*sizeof_complejo], xmm3
		    pxor xmm3, xmm3
		    mov rax, [s1]
		    movdqu [rax+j*sizeof_complejo], xmm3
			sub j, 2
			jmp .ciclo_3
		.fin_3:

		push i
		sub rsp, 8
		PUSH16 f
		mov rdi, [s2]
		mov rsi, window_size
		mov rdx, [s1]
		call iditfft2
		POP16 f
		add rsp, 8
		pop i

		mov r10d, window_size
		sub r10d, 4          ;trabaja de a 4 (C es de a 1)
		;%define j r10d
		.ciclo_4:
			cmp j, 0
			jl .fin_4
			pxor xmm2, xmm2
			cvtsi2ss xmm2, i
			divss xmm2, f
			cvtss2si r11d, xmm2  ;inicio

			mov rax, [s1]
			movdqu xmm3, [rax+j*sizeof_complejo]
			psllq xmm3, sizeof_float*8  ;me quedo solo con los reales
			; xmm3: j+1real, 0, jreal, 0
			add j, 2
			movdqu xmm5, [rax+j*sizeof_complejo]
			psllq xmm5, sizeof_float*8  ;me quedo solo con los reales
			; xmm5: j+3real, 0, j+2real, 0
			shufps xmm3, xmm5, 11011101b
			; xmm3: j+3real, j+2real, j+1real, jreal
			sub j, 2
			mov rax, [hanning]
			movdqu xmm4, [rax+j*sizeof_float]
			mulps xmm3, xmm4   ;real*hanning

			add r11d, j    ;inicio+j
			mov rax, [output]
			movq [rax+r11d*sizeof_float], xmm3

			add j, 4
			jmp .ciclo_4
		
		.fin_4:
		mov rax, [fxhop]
		sub i, rax
		jmp .ciclo
	
	.fin:

	;la pila estaba asi:
	;%define output rsp+16
	;%define s2 rsp+24
	;%define s1 rsp+32
	;%define a2 rsp+40
	;%define a1 rsp+48
	;%define phase rsp+56
	;%define hanning rsp+62
	;y en rsp+70 mi xmm0

	mov r15, [output]   ;tengo que guardarme este puntero
	add rsp, 16
	add rsp, 8        ;no tengo que hacerle free a output!
	mov rcx, 6
	.frees:
	pop rax
	call free
	loop .frees
	add rsp, 16
	
	mov rax, r15 

	ADD RSP, 8
	POP R15
	POP R14
	POP R13
	POP R12
	POP RBX
	POP RBP

	ret







	