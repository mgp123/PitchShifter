section.data:
	align 16
	;aca van las variables hardcodeadas
	pi: times 1 dd 3.141592654
	_dospi: dd 6.283185308
	_dospi_mask: times 4 dd 6.283185308
	_dos: times 4 dd 2.0
	_uno: times 1 dd 1.0
	_mask: dd 1.0, 1.0, -1.0, -1.0
	%define sizeof_float 4
	%define sizeof_complejo 8
	%define off_real 0
	%define off_img 4

section.text:
	global stretch_asm
	global ciclo_4_asm
	extern malloc
	extern free
	extern sin
	extern cos
	extern calloc
	extern sqrt
	extern atan2
	extern ditfft2_asm
	extern iditfft2_asm

;obs: push16 y pop16 no desalinean la pila porque son movimientos de 16 bytes
%macro PUSH16 1
sub rsp, 16
movdqu [rsp], %1
%endmacro

%macro POP16 1
movdqu %1, [rsp]
add rsp, 16
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
	mov r14d, ecx

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
	PUSH16 f       ;lo dejamos abajo de todos los push que vamos a hacer ahora
	call calloc    ;lo inicializo en ceros

	push rax  	   ;phase en [rsp]

	xor rax, rax   ;para q no se rompa malloc (?)
	lea edi, [window_size*sizeof_float]
	sub rsp, 8	   ;alineo para el call
	call malloc    ;no necesito q esté en 0
	add rsp, 8
	push rax       ;pila alineada
	
	; Mi pila ahora:
	; rsp: hanning (array de *windows_size* floats)
	; rsp+8: phase (array de *windows_size* floats)
	; rsp+16: f

	xor rax, rax
	lea edi, [window_size*sizeof_float]
	call malloc
	push rax       ;a1 (pila desalineada)  +24
	xor rax, rax
	lea edi, [window_size*sizeof_float]
	sub rsp, 8
	call malloc
	add rsp, 8
	push rax       ;a2 (pila alineada)     +32
	xor rax, rax
	lea edi, [window_size*sizeof_complejo]
	call malloc
	push rax       ;s1 (pila desalineada)  +40
	xor rax, rax
	lea edi, [window_size*sizeof_complejo]
	sub rsp, 8
	call malloc
	add rsp, 8
	push rax       ;s2 (pila alineada)	   +48

	.anda:
	movdqu f, [rsp+48]   ;restauramos f brevemente

	cvtsi2ss xmm0, size
	divss xmm0, f
	cvtsi2ss xmm2, window_size
	addss xmm0, xmm2      ;size/f + window_size (nuevo_largo)
	cvtss2si edi, xmm0
	xor rsi, rsi
	mov rsi, 4
	call calloc
	push rax      ; output                +56
	sub rsp,8     ; (pila alineada)

	;la pila entonces queda:
	.definopila:
	%define output rsp+8
	%define s2 rsp+16
	%define s1 rsp+24
	%define a2 rsp+32
	%define a1 rsp+40
	%define hanning rsp+48
	%define phase rsp+56
	%define espacio rsp+64
	;en rsp+64 mi xmm0/f.... tengo que acomodar la pila cuando termina todo

	movdqu f, [espacio]   ;restauramos f definitivamente

	;necesito window_size-1 para la sgte parte (tenia window_size en xmm2)
	movdqu xmm5, [_uno] 
	subss xmm2, xmm5    

	mov ecx, window_size  ;i
	dec ecx
	.init_hanning:
		cmp ecx, 0
		jl .fin_h
		movss xmm0, [pi]
		cvtsi2ss xmm3, ecx
		mulss xmm0, xmm3  ;pi*i
		divss xmm0, xmm2  ;/window_size-1
		cvtss2sd xmm0, xmm0
		
		PUSH16 xmm2
		PUSH16 f
		push rcx
		sub rsp, 8
		
		call sin
		
		add rsp, 8
		pop rcx
		POP16 f
		POP16 xmm2

		cvtsd2ss xmm0, xmm0
		mulss xmm0, xmm0
		.debug2:
		mov rax, [hanning]
		movss [rax+rcx*sizeof_float], xmm0
		dec ecx
		jmp .init_hanning

	.fin_h:
	;necesito:
	; size-window_size-hop
	; f*hop

	xor rcx, rcx
    %define i rcx
    .ciclo:
        mov eax, size
        sub eax, window_size
        sub eax, hop
        cmp i, rax
        jge .fin
        
		mov r10d, window_size
		sub r10d, 4
		%define j r10
		.ciclo_a:
			cmp j, 0
			jl .fin_a
			mov r11, i
			add r11, j
			movdqu xmm4, [audio+r11*sizeof_float]
			mov rax, [hanning]
			mulps xmm4, [rax+j*sizeof_float]
			mov rax, [a1]
			movdqu [rax+j*sizeof_float], xmm4
			add r11d, hop
			movdqu xmm4, [audio+r11*sizeof_float]
			mov rax, [hanning]
			mulps xmm4, [rax+j*sizeof_float]
			mov rax, [a2]
			movdqu [rax+j*sizeof_float], xmm4
			sub j, 4
			jmp .ciclo_a

		.fin_a:
		;preparo todo para llamar ditfft2
		mov rdi, [a1]
		mov esi, window_size
		mov rdx, [s1]

		push i
		sub rsp, 8
		PUSH16 f
		call ditfft2_asm
		POP16 f      
		add rsp, 8
		pop i        ;si restauro la pila puedo usar mis defines (a2 y s2)
		
		mov rdi, [a2]
		mov esi, window_size
		mov rdx, [s2]
		
		push i
		sub rsp, 8
		PUSH16 f
		call ditfft2_asm
		POP16 f
		add rsp, 8
		pop i

		mov r10d, window_size
		%define j r10
		sub j, 2    ;mi ciclo hace de a 2 (la de C es de a 1)
					;window_size es potencia de 2 asi que anda

		.ciclo_3:
			cmp j, 0
			jl .fin_3

			mov rax, [s1]
		    movdqu xmm4, [rax+j*sizeof_complejo]  ;el float mas bajo es la parte real de s1[j]
		    ; xmm4: s1[j+1].img, s1[j+1].real, s1[j].img, s1[j].real
		    mov rax, [s2]
		    movdqu xmm5, [rax+j*sizeof_complejo]
		    ; xmm5: s2[j+1].img, s2[j+1].real, s2[j].img, s2[j].real

		    .norma2:
		    movdqa xmm6, xmm5
		    mulps xmm6, xmm6
		    movdqa xmm2, xmm6
		    psrldq xmm2, 4
		    addps xmm2, xmm6
		    psllq xmm2, 8*sizeof_float
		    psrlq xmm2, 8*sizeof_float
		    sqrtps xmm2, xmm2
		    ; xmm2: 0, norma**2 j+1, 0, norma**2 j

		    .realimg:
		    pxor xmm6, xmm6
		    pshufd xmm6, xmm5, 10110001b
		    ; xmm6: s2[j+1].real, s2[j+1].img, s2[j].real, s2[j].img

		    mulps xmm5, xmm4
		    mulps xmm6, xmm4
		    ; xmm5: [j+1]img*img, [j+1]real*real, [j]img*img, [j]real*real
		    ; xmm6: [j+1]s1img*s2real, [j+1]s1real*s2img, [j]s1img*s2real, [j]s1real*s2img
		    movdqu xmm4, xmm5
		    psrldq xmm4, 4
		    addps xmm5, xmm4   ;ahora hablamos de frac.real
		    psllq xmm5, 8*sizeof_float
		    psrlq xmm5, 8*sizeof_float ;0.0, realj+1, 0.0, realj
		    
		    movdqa xmm4, xmm6
		    psrldq xmm4, 4
		    subps xmm6, xmm4   ;ahora hablamos de frac.img
		    psllq xmm6, 8*sizeof_float  ;imgj+1, 0.0, imgj, 0.0
		    
		    addps xmm5, xmm6   ;imgj+1, realj+1, imgj, realj
		    movdqa xmm6, xmm5
		    psrldq xmm6, 8
		    cvtps2pd xmm5, xmm5  ;j.img, j.real (DOUBLE)
		    cvtps2pd xmm6, xmm6  ;j+1.img, j+1.real (DOUBLE)


		    .frac_calculadas:
		    ;hacer cosas de push y demas (ecx, r10, los xmm)
		    ;PUSH
		    push i
		    push j
		    PUSH16 f
		    PUSH16 XMM2
		    PUSH16 XMM6

		    movdqa xmm0, xmm5
		    psrldq xmm0, 8     ;frac.imaginaria (j)
		    movdqa xmm1, xmm5
		    pslldq xmm1, 8
		    psrldq xmm1, 8    ;frac.real (j)
		    call atan2
		    cvtsd2ss xmm5, xmm0
		    POP16 XMM6
		    PUSH16 XMM5
		    movdqa xmm0, xmm6
		    psrldq xmm0, 8     ;frac.imaginaria (j+1)
		    movdqa xmm1, xmm6
		    pslldq xmm1, 8  
		    psrldq xmm1, 8    ;frac.real (j+1)
		    call atan2
		    cvtsd2ss xmm6, xmm0

		    POP16 XMM5
		    POP16 XMM2
		    POP16 f
		    pop j
		    pop i

		    ;xmm5: v_angular j float
		    ;xmm6: v_angular j+1 float

		    .omega:
		    pxor xmm3, xmm3
		    movd xmm3, [_dospi]
		    cvtsi2ss xmm4, hop
		    mulss xmm3, xmm4    ;hop*2pi
		    cvtsi2ss xmm4, window_size
		    divss xmm3, xmm4    ;xmm3: hop*2pi/window_size 
		    cvtsi2ss xmm4, j
		    movdqa xmm7, xmm3
		    mulss xmm3, xmm4    ;xmm3: omegaj
		    
		    subss xmm5, xmm3    ;xmm5: v_angular j -omegaj
		    inc j
		    cvtsi2ss xmm4, j
		    dec j
		    mulss xmm7, xmm4    ;xmm7: omegaj+1
		    subss xmm6, xmm7    ;xmm6: v_angular j+1 -omegaj+1

		    ;xmm3: omega
		    ;xmm5: delta_phi j
		    ;xmm6: delta_phi j+1

		    .nuevo:
		    pslldq xmm5, 12   
		    psrldq xmm5, 12     
		    pslldq xmm6, 4
		    addps xmm5, xmm6  ;0,0,d_phi j+1, d_phi j    
		    movdqu xmm6, [_dospi_mask]
		    movdqu xmm4, xmm5
		    
		    .modulo:
		    divps xmm4, xmm6
		    cvttps2dq xmm4, xmm4   ;convierto truncando
		    cvtdq2ps xmm4, xmm4
		    mulps xmm4, xmm6
		    subps xmm5, xmm4 ; delta_phi % 2pi

		    shufps xmm3, xmm7, 0 ;omegaj1, omegaj1, omegaj, omegaj
		    shufps xmm3, xmm3, 00001000b
		    addps xmm5, xmm3   ;d_phi + omega = d_phi(nuevo)

		    movdqu xmm4, f
		    shufps xmm4, xmm4, 0
		    divps xmm5, xmm4    ;d_phi(nuevo)/f
		    ;xmm5: basura, basura ,d_phi/f j+1, d_phi/f j  

		    mov rax, [phase]
		    movq xmm6, [rax+j*sizeof_float]  ;bajo phase viejo
		    addps xmm5, xmm6   ;le sumo el phase viejo

		    .modulo_de_nuevo:
		    movdqu xmm6, [_dospi_mask]
		    movdqu xmm4, xmm5
		    divps xmm4, xmm6
		    cvttps2dq xmm4, xmm4   ;convierto a int truncando
		    cvtdq2ps xmm4, xmm4
		    mulps xmm4, xmm6
		    subps xmm5, xmm4 ; phase = phase - phase % 2pi
		    pslldq xmm5, 8
		    psrldq xmm5, 8   ; limpio los dos de arriba

		    ;phase lo hace bien
		    
		    .bajo_a_mem:
		    mov rax, [phase]
		    movq [rax+j*sizeof_float], xmm5 ;guardo nuevos phase
		    
		    .rephased:
		    ;xmm5: 0,0,phase[j+1],phase[j]
		    PUSH16 f
		    push i
		    push j

		    PUSH16 XMM5  ;phase j y j+1
		    PUSH16 XMM2  ;normas

		    cvtss2sd xmm0, xmm5 ;phase[j]
		    call cos
		    cvtsd2ss xmm0, xmm0
		    POP16 XMM2
		    mulss xmm0, xmm2 ;*normaj
		    pslldq xmm0, 12    
		    psrldq xmm0, 12     ;limpié parte alta de xmm0
		    movdqu xmm3, xmm0   ;voy guardando los rephased en xmm3
		    POP16 XMM5
		    PUSH16 XMM5
		    PUSH16 XMM3
		    PUSH16 XMM2

		    cvtss2sd xmm0, xmm5 ;phase[j]
		    call sin
		    cvtsd2ss xmm0, xmm0
		    POP16 XMM2
		    mulss xmm0, xmm2  ;*normaj
		    pslldq xmm0, 12
		    psrldq xmm0, 8    ;limpio y dejo en xmm0[1]
		    POP16 XMM3
		    addps xmm3, xmm0   ;xmm3: 0.0,0.0,img,real   
		    POP16 XMM5
		    ;ya no necesito mas phase[j]
		    psrldq xmm5, 4 ;phase[j+1]
		    PUSH16 XMM5  ;la necesito despues del prox call
		    PUSH16 XMM3
		    PUSH16 XMM2


		    cvtss2sd xmm0, xmm5 ;phase[j+1]
		    call cos
		    cvtsd2ss xmm0, xmm0
		    POP16 XMM2
		    ;necesito *normaj+1
		    psrldq xmm2, 8   ; 0,0,0,normaj+1
		    mulss xmm0, xmm2
		    pslldq xmm0, 12
		    psrldq xmm0, 4
		    POP16 XMM3
		    addps xmm3, xmm0   ;xmm3: 0.0, realj+1, imgj, realj
		    POP16 XMM5
		    PUSH16 XMM3
		    PUSH16 XMM2

		    cvtss2sd xmm0, xmm5 ;phase[j+1], ya no la voy a necesitar mas despues
		    call sin
		    cvtsd2ss xmm0, xmm0
		    POP16 XMM2
		    mulss xmm0, xmm2
		    pslldq xmm0, 12
		    POP16 XMM3
		    addps xmm3, xmm0   ;xmm3: imgj+1, realj+1, imgj, realj

		    pop j
		    pop i
		    POP16 f

		    ;ya no necesito mas las normas (xmm2), ni xmm5
		    ;todo quedó en xmm3

		    .corrupcion:
		    mov rax, [s2]
		    movdqu [rax+j*sizeof_complejo], xmm3  ;pongo los val en s2
		    pxor xmm3, xmm3
		    mov rax, [s1]
		    movdqu [rax+j*sizeof_complejo], xmm3  ;vacio s1 
			sub j, 2
			
			jmp .ciclo_3


		.fin_3:
		mov rdi, [s2]
		mov esi, window_size
		mov rdx, [s1]
		push i
		sub rsp, 8
		PUSH16 f
		call iditfft2_asm
		POP16 f
		add rsp, 8
		pop i


		mov r10d, window_size
		sub r10, 4          ;trabaja de a 4 (C es de a 1)
		;%define j r10

		;ciclo_4_asm(j, i, f, s1, hanning, output)
		; CICLO 4 VERIFICADO
		.ciclo_4:
			cmp j, 0
			jl .fin_4
			pxor xmm2, xmm2
			cvtsi2ss xmm2, ecx ;ecx=i 
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

			add r11, j    ;inicio+j
			mov rax, [output]
			.check:
			movdqu xmm4, [rax+r11*sizeof_float]
			addps xmm3, xmm4 
			movdqu [rax+r11*sizeof_float], xmm3

			sub j, 4
			jmp .ciclo_4
		
		.fin_4:
		mov eax, hop
        add i, rax
        jmp .ciclo
	
	.fin:
	;la pila estaba asi:
	;%define output rsp+8
	;%define s2 rsp+16
	;%define s1 rsp+24
	;%define a2 rsp+32
	;%define a1 rsp+40
	;%define phase rsp+48
	;%define hanning rsp+56
	;%define espacio rsp+64

	mov r15, [output]   ;tengo que guardarme este puntero
	add rsp, 16        ;no tengo que hacerle free a output! la pila sigue alineada
	mov rbx, 5
	
	.frees:
	cmp rbx, 0
	jl .fin_free
	mov rdi, [rsp+rbx*8]  ;traigo a rdi el puntero a liberar
	call free
	dec rbx
	jmp .frees

	.fin_free:
	add rsp, 48
	add rsp, 16  ;vacio espacio (q mide 16 bytes)

	mov rax, r15 

	ADD RSP, 8
	POP R15
	POP R14
	POP R13
	POP R12
	POP RBX
	POP RBP

	ret


;ciclo_4_asm(j, i, f, s1, hanning, output)
;TESTEADO: FUNCIONA
ciclo_4_asm:
	push rbp
	mov rbp, rsp
	%define j rdi
	;i rsi
	movdqa xmm1, xmm0
	%define f xmm1
	;s1 rdx
	;hanning rcx
	;output r8
	push rdx
	push rcx
	push r8
	%define output rsp
	%define hanning rsp+8
	%define s1 rsp+16
	mov rcx, rsi
	%define i rcx

	sub j, 4
	.ciclo_4:
	cmp j, 0
	jl .fin_4
	pxor xmm2, xmm2
	cvtsi2ss xmm2, ecx ;ecx=i 
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

	add r11, j    ;inicio+j
	mov rax, [output]
	.check:
	movdqu xmm4, [rax+r11*sizeof_float]
	addps xmm3, xmm4 
	movdqu [rax+r11*sizeof_float], xmm3

	sub j, 4
	jmp .ciclo_4

	.fin_4:
	pop r8
	pop rcx
	pop rdx
	pop rbp
	ret
