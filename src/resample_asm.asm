section.data:
secuencia: dd 0.0, 1.0, 2.0, 3.0
section.text:
global resample_asm
extern malloc

resample_asm: ; float* resample(float* audio, int size, float f)
	push rdi
	%define f_resample xmm0

	cvtsi2ss xmm1, rsi
	divss xmm1, f_resample ; xmm1 = size/float = nuevo largo

	xor rdi,rdi
	cvttss2si edi, xmm1

	dec rdi
	cvtsi2ss xmm2, edi
	dec rsi 
	cvtsi2ss f_resample, esi
	divss f_resample, xmm2  ; f_resample = size-1 / nuevo largo-1


	inc rdi
	inc rsi
	shl edi, 2; un float son 4 bytes
	call malloc
	%define ARREGLO_NUEVO rax

	pop rdi
	%define ARREGLO_ORIGINAL rdi

	xor rsi,rsi
	cvtss2si esi, xmm1

	%define NUEVO_LARGO rsi
	mov rdx, 0
	mov rcx, 0
	%define indice_original rcx
	%define indice_nuevo rdx


	.ciclo:
	cmp indice_nuevo, NUEVO_LARGO
	je .fin
	inc indice_nuevo
	cmp indice_nuevo, NUEVO_LARGO
	je .un_elemento
	dec indice_nuevo



	cvtsi2ss xmm2, edx
	mulss xmm2, f_resample
	cvttss2si r8, xmm2  ; r8 = floor (i*f) = (int) a0
	cvtsi2ss xmm5, r8 ; xmm5 = |..|..|..| (float) a0 |

	shl r8, 2  ;un float son 4 bytes
	add r8, ARREGLO_ORIGINAL
	movsd xmm1, [r8]

	inc indice_nuevo
	cvtsi2ss xmm3, edx
	mulss xmm3, f_resample
	cvttss2si r8, xmm3 ; r8 = floor ((i+1)*f) = (int) a1
	cvtsi2ss xmm6, r8 ; xmm6 = |..|..|..| (float) a1 |

	shl r8, 2  ;un float son 4 bytes
	add r8, ARREGLO_ORIGINAL 
	movsd xmm4, [r8]
	dec indice_nuevo

	movlhps xmm1, xmm4  ; xmm1 = | Arr[b1] | Arr[a1] | Arr[b0] | Arr[a0] |
	movlhps xmm2, xmm3  ; xmm2 = | 0  | x1 | 0  | x0 |  ; con x = i*f

	movlhps xmm5, xmm6
	movdqa xmm3, xmm5 ; xmm3 = | 0 | a1 | 0  | a0 |
	subps xmm2, xmm3 ; xmm2 = | 0 | x1-a1 | 0  | x0-a0 |
	pshufd xmm2, xmm2, 1000b ; xmm2 = | .. | .. | x1-a1 | x0-a0 |

	pshufd xmm3, xmm1, 10110001b
	hsubps xmm3, xmm3 ; xmm3 |..|..| Arr[b1] - Arr[a1] | Arr[b0] - Arr[a0] |
	mulps xmm3, xmm2 ; xmm3  |..|..| Arr[b1] - Arr[a1] * (x1-a1) | Arr[b0] - Arr[a0]  * (x0-a0)|
	
	pshufd xmm1, xmm1, 1000b 
	addps xmm3, xmm1 
	; ; xmm3 |..|..|Arr[b1] - Arr[a1] * (x1-a1) + Arr[a1]| Arr[b0] - Arr[a0]  * (x0-a0) + Arr[a0]|

	mov r8, indice_nuevo
	shl r8, 2
	add r8, ARREGLO_NUEVO
	movsd [r8], xmm3


	add indice_nuevo, 2
	jmp .ciclo

	.un_elemento:
	dec indice_nuevo
	cvtsi2ss xmm2, edx
	mulss xmm2, f_resample
	cvttss2si r8, xmm2  ; r8 = floor (i*f) = (int) a0
	cvtsi2ss xmm3, r8 ; xmm3 = |..|..|..| (float) a0 |

	shl r8, 2  ;un float son 4 bytes
	add r8, ARREGLO_ORIGINAL
	movsd xmm1, [r8] 
	movdqa xmm0, xmm1

	pshufd xmm1, xmm1, 0001b ; xmm1 = |..|..| Arr[a0] | Arr[b0] |
	hsubps xmm1, xmm1 ; xmm1 |..|..| .. | Arr[b0] - Arr[a0] |

	subss xmm2, xmm3 ; xmm2 = |..|..|..| x0 -  a0 |
	mulss xmm2, xmm1
	addss xmm2, xmm0

	mov r8, indice_nuevo
	shl r8, 2
	add r8, ARREGLO_NUEVO
	movsd [r8], xmm2

	.fin:
	ret
