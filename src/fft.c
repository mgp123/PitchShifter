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


complejo* iditfft2(complejo* c, unsigned int size){
	complejo* res = malloc(size*sizeof(complejo));
	iditfft2_buff(c,size,res);
	return res;

}

void iditfft2_buff(complejo* c, unsigned int size, complejo* buffer){
	iditfft2_buff_aux(c,size,1,buffer);
	for (int i = 0; i < size; ++i)
	{
		buffer[i].real /= (float) size;
		buffer[i].imaginaria /= (float) size;

	}
}

void iditfft2_buff_aux(complejo* c, unsigned int size, unsigned int hop, complejo* buffer) {
	if (size == 1)
	{
		buffer[0] = c[0];
	}
	else {
		iditfft2_buff_aux(c,size>>1,hop<<1,buffer);
		iditfft2_buff_aux(&c[hop],size>>1,hop<<1,&buffer[size>>1]);

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

float* convolucion(float* audio, unsigned int size1, float* IR, unsigned int size2) {
	unsigned int len = siguiente_potencia(size1);

	complejo* fftAudio = calloc(len,  sizeof(complejo));
	complejo* fftIR = calloc(len, sizeof(complejo));
	complejo* temp = calloc(len, sizeof(complejo));

	// F(audio)
	complejizar_buff(IR,size2,temp);
	ditfft2_buff(temp,len,fftIR);

	// F(IR)
	complejizar_buff(audio,size1,temp);
	ditfft2_buff(temp,len,fftAudio);

	// temp =  F(audio) * F(IR)
	for (int i = 0; i < len; ++i)
	{
		temp[i].real = fftAudio[i].real*fftIR[i].real - fftAudio[i].imaginaria*fftIR[i].imaginaria;
		temp[i].imaginaria = fftAudio[i].real*fftIR[i].imaginaria + fftAudio[i].imaginaria*fftIR[i].real;
	}

	// res = F-1(temp). Se reusan buffers
	float* res = (float*) temp;
	iditfft2_buff(temp,len,fftAudio);
	parte_real_buff(fftAudio,len,res);
	free(fftAudio);
	free(fftIR);

	return res;
}