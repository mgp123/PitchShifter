#include "rw_audio.h"
#include "fft.h"

int main(int argc, char *argv[])
{
	float numeros[8] = {1,2,3,4,5,6,7,8};
	complejo c[8];
	complejo transform[8];
	complejizar_buff(numeros,8,c);

	printf("%s\n", "Previo fft");
	for (int i = 0; i < 8; ++i)
	{
		printf("Real: %f. Imaginaria: %f\n",c[i].real, c[i].imaginaria);
	}

	ditfft2_buff(c,8,transform);

	printf("%s\n", "Luego de fft");
	for (int i = 0; i < 8; ++i)
	{
		printf("Real: %f. Imaginaria: %f\n",transform[i].real, transform[i].imaginaria);
	}
	

	/*
	float* ptr;
	ptr = read_wav(argv[1]);
	efecto_phaser(ptr);
	free(ptr);
	*/
	return 0;
}