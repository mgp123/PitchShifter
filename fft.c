#include "fft.h"

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


complejo* ditfft2(complejo* c, unsigned int size){
	complejo* res = malloc(size*sizeof(complejo));
	ditfft2_buff(c,size,res);
	return res;

}

void ditfft2_buff(complejo* c, unsigned int size, complejo* buffer){
	ditfft2_buff_aux(c,size,1,buffer);
}
void ditfft2_buff_aux(complejo* c, unsigned int size, unsigned int hop, complejo* buffer) {
	if (size == 1)
	{
		buffer[0] = c[0];
	}
	else {
		ditfft2_buff_aux(c,size>>1,hop<<1,buffer);
		ditfft2_buff_aux(&c[hop],size>>1,hop<<1,&buffer[size>>1]);

		for (int i = 0; i < size/2; ++i)
		{
			float frac = (float) i;
			frac = frac / ((float) size);

			// rotacion podria/deberia tenerse precalculado en lugar de 
			// hacerlo de esta forma.
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
