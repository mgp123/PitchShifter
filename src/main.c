#include "rw_audio.h"
#include "efectos.h"


int main(int argc, char *argv[])
{	
	/*float* audio;
	audio = read_wav(argv[1]);

	float resample_coef = 1.10;
	efecto_repitch(audio, audio_in_info.frames,resample_coef);
	free(audio);*/
	int size = 10;
	float numeros[size];
	for (int i = 0; i < size; ++i)
	{
		numeros[i] = i*1.0;
	}

	float f = 1.5;
	unsigned int nuevo_largo = size/f;
	float* res = resample_asm(numeros,size,f);
	float* resC = resample(numeros,size,f);


	for (int i = 0; i < nuevo_largo; ++i)
	{
		printf("%d:\n", i );
		printf("ASM: %f\n", res[i]);
		printf("C: %f\n", resC[i]);	
		printf("\n" );
	
	}

	free(res);
	free(resC);

	precalcular_rotaciones();

	return 0;
}