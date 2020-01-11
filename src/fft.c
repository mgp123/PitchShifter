#include "fft.h"
#include <stdio.h>

complejo* complejizar(float* r, unsigned int size) {
	complejo* res =  malloc(size*sizeof(complejo));
	complejizar_buff(r,size,res);
	return res;
}

void complejizar_buff(float* r, unsigned int size, complejo* buffer) {
	for (int i = 0; i < size; ++i)
	{
		buffer[i].real = r[i];
		buffer[i].imaginaria = 0;
	}
}


float* parte_real(complejo* c, unsigned int size) {
	float* res = malloc(size*sizeof(float));
	parte_real_buff(c,size,res);
	return res;
}

void parte_real_buff(complejo* c, unsigned int size, float* buffer){
	for (int i = 0; i < size; ++i)
	{
		buffer[i] = c[i].real;
	}
}

unsigned int siguiente_potencia(unsigned int x){
	unsigned int temp = x;
	unsigned int res = 1;
	while(x != 1) {
		x = x >> 1;
		res = res << 1;
	}

	if (res < temp)
	{
		res = res << 1;
	} 
	return res;
}


void ditfft2(float* c, unsigned int size, complejo* buffer){
	ditfft2_aux(c,size,1,buffer);
}
// se puede pasar un arreglo de numeros reales y se genera el complejo en el caso base
void ditfft2_aux(float* c, unsigned int size, unsigned int hop, complejo* buffer) {
	if (size == 1)
	{
		buffer[0].real = c[0];
		buffer[0].imaginaria = 0; 
	}
	else {
		ditfft2_aux(c,size>>1,hop<<1,buffer);
		ditfft2_aux(&c[hop],size>>1,hop<<1,&buffer[size>>1]);

		for (int i = 0; i < size/2; ++i)
		{
			float frac = (float) i;
			frac = frac / ((float) size);

			// rotacion podria/deberia tenerse precalculado en lugar de 
			// hacerlo de esta forma.
			// Puede usarse un arreglo directamente con todas los elemntos y acceder como queramos. Usando un archivo de precalculados.
			complejo rotacion;
			rotacion.real =  cos(-2*M_PI*frac);
			rotacion.imaginaria = sin(-2*M_PI*frac);



			complejo t = buffer[i];


			complejo c_ref;
			c_ref.real = buffer[i+size/2].real*rotacion.real - buffer[i+size/2].imaginaria*rotacion.imaginaria;
			c_ref.imaginaria = buffer[i+size/2].real*rotacion.imaginaria + buffer[i+size/2].imaginaria*rotacion.real;

			buffer[i].real += c_ref.real;
			buffer[i].imaginaria += c_ref.imaginaria;

			buffer[i+size/2].real = t.real - c_ref.real;
			buffer[i+size/2].imaginaria = t.imaginaria - c_ref.imaginaria;
		}
	}
}

void ditfft2_stereo(float* c, unsigned int size, complejo* buffer){
	ditfft2_aux(c,size>>1,2,buffer);
	ditfft2_aux(&c[1],size>>1,2,&buffer[size>>1]);
}


void iditfft2(complejo* c, unsigned int size, complejo* buffer){
	iditfft2_aux(c,size,1,buffer);
	for (int i = 0; i < size; ++i)
	{
		buffer[i].real /= (float) size;
		buffer[i].imaginaria /= (float) size;

	}
}

void iditfft2_aux(complejo* c, unsigned int size, unsigned int hop, complejo* buffer) {
	if (size == 1)
	{
		buffer[0] = c[0];
	}
	else {
		iditfft2_aux(c,size>>1,hop<<1,buffer);
		iditfft2_aux(&c[hop],size>>1,hop<<1,&buffer[size>>1]);

		for (int i = 0; i < size/2; ++i)
		{
			float frac = (float) i;
			frac = frac / ((float) size);

			// rotacion podria/deberia tenerse precalculado en lugar de 
			// hacerlo de esta forma.
			complejo rotacion;
			rotacion.real =  cos(2*M_PI*frac);
			rotacion.imaginaria = sin(2*M_PI*frac);



			complejo t = buffer[i];

			complejo c_ref;
			c_ref.real = buffer[i+size/2].real*rotacion.real - buffer[i+size/2].imaginaria*rotacion.imaginaria;
			c_ref.imaginaria = buffer[i+size/2].real*rotacion.imaginaria + buffer[i+size/2].imaginaria*rotacion.real;

			buffer[i].real += c_ref.real;
			buffer[i].imaginaria += c_ref.imaginaria;

			buffer[i+size/2].real = t.real - c_ref.real;
			buffer[i+size/2].imaginaria = t.imaginaria - c_ref.imaginaria;

		}
	}
}

void convolucion_circular(complejo* c1, complejo* c2, unsigned int size, complejo* buffer) {
	complejo producto[size];
	for (int i = 0; i < size; ++i)
	{
		producto[i].real = c1[i].real*c2[i].real - c1[i].imaginaria*c2[i].imaginaria;
		producto[i].imaginaria = c1[i].real*c2[i].imaginaria + c1[i].imaginaria*c2[i].real;
	}

	iditfft2_asm(producto,size,buffer);
}



float* convolucion_lineal(float* audio, unsigned int size1, float* IR, unsigned int size2) {

	int branch_size = 1024;
	float* ouput =  calloc(size1+size2-1,  sizeof(complejo));

	unsigned int branchs = size2/branch_size;

	complejo FIR[branchs][branch_size*2];


	// Fft de los pedazos de la IR
	for (int i = 0; i < branchs; ++i)
	{
		float padded[branch_size*2];
		for (int j = 0; j < branch_size; ++j)
		{
			padded[j] = IR[ i*branch_size + j ];
			padded[j+branch_size] =  0.0;
		}

		ditfft2_asm(padded, branch_size*2,FIR[i]);
	}

	
	for (int i = 0; i < size1-branch_size+1; i+=branch_size)
	{
		// printf("Completado %f\n", (i*1.0)/size1);

		// Fft del pedazo del audio
		float padded[branch_size*2];
		for (int j = 0; j < branch_size; ++j)
		{
			padded[j] = audio[ i + j ];
			padded[j+branch_size] =  0.0;

		}


		complejo Faudio[branch_size*2];
		ditfft2_asm(padded,branch_size*2,Faudio);

		complejo Fconv[branch_size*2];
		complejo IFconv[branch_size*2];


		for (int j = 0; j < branchs; ++j)
		{
			convolucion_circular_asm(Faudio,FIR[j],branch_size*2,IFconv);
			for (int k = 0; k < branch_size*2-1; ++k)
			{ 
				ouput[i+j*branch_size+k] +=  IFconv[k].real;
			}
		}
	}

	return ouput;
}
	

void precalcular_rotaciones() {
	for (int i = 0; i < PRECALCULADOS; ++i)
	{	
		rotaciones[i].real =  cos(-M_PI*i/PRECALCULADOS);
		rotaciones[i].imaginaria = sin(-M_PI*i/PRECALCULADOS);
	}
}

