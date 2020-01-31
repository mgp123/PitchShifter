section.data:
	align 16
	;aca van las variables hardcodeadas
	pi: times 1 dd 3.141592654
	_pi_mask: dd 3.141592654, 3.141592654, 0.0, 0.0
	_pi_negmask: dd -3.141592654, -3.141592654, 0.0, 0.0
	_negmask: dd -1.0, -1.0, -1.0, -1.0
	_dos: times 4 dd 2.0
	_uno: times 1 dd 1.0
	_mask: dd 1.0, 1.0, -1.0, -1.0
	%define sizeof_float 4
	%define sizeof_complejo 8
	%define off_real 0
	%define off_img 4

section.text:
	global stretch_asm
	extern malloc
	extern free
	extern sin
	extern cos
	extern calloc
	extern sqrt
	extern atan2
	extern ditfft2
	extern iditfft2

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
	cvttss2si edi, xmm0
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

	mov ecx, size
	sub ecx, window_size
	sub ecx, hop
	cvtsi2ss xmm3, hop
	mulss xmm3, f   
	cvtss2si eax, xmm3     
	mov [espacio], rax
	%define fxhop rsp+64  
	;hay q restarle a i por la naturaleza de los ciclos en asm
	sub rcx, rax

	%define i rcx
	.ciclo:
		cmp i, 0
		jl .fin
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
		call ditfft2
		POP16 f
		add rsp, 8
		pop i
		
		mov rdi, [a2]
		mov esi, window_size
		mov rdx, [s2]
		
		push i
		sub rsp, 8
		PUSH16 f
		call ditfft2
		POP16 f
		add rsp, 8
		pop i

		mov r10d, window_size
		;%define j r10
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
		    ; xmm6: s2[j+1].real, s2[j+1].img, s2[j].real, s2[j].img

		    ; aprovecho acá para conseguir normas2
		    movdqu xmm2, xmm6
		    mulps xmm2, xmm2  ;j+1 r*r, j+1 i*i, j r*r, j i*i
		    movdqu xmm3, xmm2
		    pslldq xmm3, 4    ; 0.0   , j+1 r*r, j+1 i*i, j r*r
		    addps xmm2, xmm3  ; basura, norma**2 j+1, basura, norma**2 j
		    psllq xmm2, 8*sizeof_float
		    psrlq xmm2, 8*sizeof_float
		    sqrtps xmm2, xmm2    ; 0, normaj+1, 0, normaj
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
		    movdqu xmm7, [_mask] 
		    mulps xmm5, xmm7
		    ; xmm5: -[j+1]img*real, -[j]img*real, [j+1]img*img, [j]img*img
		    addps xmm4, xmm5
		    ; xmm4: frac[j+1].img, frac[j].img, frac[j+1].real, frac[j].real
		    shufps xmm4, xmm4, 11011000b
		    ; xmm4: frac(j+1).img, frac(j+1).real, frac(j).img, frac(j).real
		    cvtps2pd xmm5, xmm4  ;j.img, j.real (DOUBLE)
		    psrldq xmm4, 8
		    cvtps2pd xmm6, xmm4  ;j+1.img, j+1.real (DOUBLE)


		    .frac_calculadas:
		    ;hacer cosas de push y demas (ecx, r10, los xmm)
		    ;PUSH
		    push i
		    push j
		    PUSH16 f
		    PUSH16 XMM2
		    PUSH16 XMM5

		    movdqa xmm0, xmm6
		    psrldq xmm0, 8     ;frac.imaginaria (j)
		    movdqa xmm1, xmm6
		    pslldq xmm1, 8
		    psrldq xmm1, 8    ;frac.real (j)
		    call atan2
		    cvtsd2ss xmm6, xmm0
		    POP16 XMM5
		    PUSH16 XMM6
		    movdqa xmm0, xmm5
		    psrldq xmm0, 8     ;frac.imaginaria (j+1)
		    movdqa xmm1, xmm5
		    pslldq xmm1, 8	
		    psrldq xmm1, 8    ;frac.real (j+1)
		    call atan2
		    cvtsd2ss xmm5, xmm0

	 		POP16 XMM6
	 		POP16 XMM2
	 		POP16 f
	 		pop j
	 		pop i

	 		.v_ang:

		    ;xmm5: v_angular j float
		    ;xmm6: v_angular j+1 float
		    divss xmm5, f
		    divss xmm6, f
		    pslldq xmm5, 12   
		    psrldq xmm5, 12		
		    pslldq xmm6, 4
		    addps xmm5, xmm6  ;0,0,v_ang/f j+1, v_ang/f j    
		    pxor xmm6, xmm6

		    mov rax, [phase]
		    movq xmm6, [rax+j*sizeof_float]  ;bajo phase viejo
		    addps xmm5, xmm6   ;le sumo el phase viejo

		    ; xmm5: 0,0, phase[j+1]+v_angular/f, phase[j]+v_angular/f 

		    .compare_pi_great:
		    movdqu xmm4, xmm5
		    movdqu xmm7, [_pi_mask]
		    cmpps xmm4, xmm7, 0xE   ;phase... > pi?
		    psrld xmm4, 31         ;si la rta era 11111 me queda un uno
		    cvtdq2ps xmm4, xmm4
		    mulps xmm4, xmm7  
		    movdqu xmm3, [_dos]      
		    mulps xmm4, xmm3   ;entonces si era mayor a pi, le resto dos pi

		    ;me falta chequear si era menor a -pi antes de modificar:
		    movdqu xmm6, xmm5
		    movdqu xmm3, [_negmask]
		    mulps xmm7, xmm3  ;chequear q ande
		    cmpps xmm6, xmm7, 1H   ;phase... < -pi?
		    psrld xmm6, 31         ;si la rta era 11111 me queda un uno
		    cvtdq2ps xmm6, xmm6
		    mulps xmm7, xmm3
		    mulps xmm6, xmm7   ;me queda pi donde tenga q sumarlo   
		    movdqu xmm3, [_dos]
		    mulps xmm6, xmm3   ;entonces si era mayor a pi, le sumo dos pi

		    subps xmm6, xmm4
		    addps xmm5, xmm6     ; 0.0, 0.0, phase[j+1], phase[j]    

		    .nuevo:
		    mov rax, [phase]
		    movq [rax+j*sizeof_float], xmm5 ;guardo nuevos phase
		    
		    .rephased:
		    ;xmm5: 0,0,phase[j+1],phase[j]
		    PUSH16 f
		    push i
		    push j

		    PUSH16 XMM5
		    PUSH16 XMM2

		    cvtss2sd xmm0, xmm5 ;phase[j]
		    call cos
		    cvtsd2ss xmm0, xmm0
		    POP16 XMM2
		    mulss xmm0, xmm2 ;*normaj
		    pslldq xmm0, 12
		    psrldq xmm0, 12
		    movdqu xmm3, xmm0
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
		    psrldq xmm0, 8
		    POP16 XMM3
		    addps xmm3, xmm0   ;xmm3: 0.0,0.0,img,real   
		    POP16 XMM5
		    PUSH16 XMM5  ;la voy despues del prox call
		    PUSH16 XMM3
		    PUSH16 XMM2

		    ;ya no necesito mas phase[j]
		    psrldq xmm5, 4 ;phase[j+1]

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
		    movdqu [rax+j*sizeof_complejo], xmm3  ;vacio s1 (para que..?)
			sub j, 2
			
			jmp .ciclo_3


		.fin_3:
		mov rdi, [s2]
		mov esi, window_size
		mov rdx, [s1]
		push i
		sub rsp, 8
		PUSH16 f
		call iditfft2
		POP16 f
		add rsp, 8
		pop i

		.debug3:
		mov rdi, [s1]
		mov rsi, [s2]

		mov r10d, window_size
		sub r10, 4          ;trabaja de a 4 (C es de a 1)
		;%define j r10
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
		mov rax, [fxhop]
		sub i, rax
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







	