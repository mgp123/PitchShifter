#include "rw_audio.h"
#include "fft.h"

int main(int argc, char *argv[])
{
	float numeros[5] = {1,2,3,4,5};
	complejo c[5];
	float numeros2[5];
	complejizar_buff(numeros,5,c);
	parte_real_buff(c,5,numeros2);
	for (int i = 0; i < 5; ++i)
	{
		printf("Real: %f. Imaginaria: %f\n",c[i].real, c[i].imaginaria);
		printf("Parte real %f\n",numeros2[i]);
	}

	for (unsigned int x = 1; x < 64*2; ++x)
	{
		printf("x = %d. La menor potencia mayor es %d\n",x, siguiente_potencia(x));	
	}
	

	/*
	float* ptr;
	ptr = read_wav(argv[1]);
	efecto_phaser(ptr);
	free(ptr);
	*/
	return 0;
}