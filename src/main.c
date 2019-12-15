#include "rw_audio.h"
#include "efectos.h"

int main(int argc, char *argv[])
{	

	float numeros[16]  = {1,2,3,4,5,6,7,8,9,10,0,0,0,0,0,0};
	float numeros2[16] =  {1,2,3,4,0,0,0,0,0,0,0,0,0,0,0,0};
	float* res = convolucion(numeros,10,numeros2,10);
	for (int i = 0; i < 16; ++i)
	{
		printf("%f\n", res[i]);
	}
	free(res);
	/*
	float* audio;  float* IR;
	IR = read_wav("ir.wav");
	unsigned int size = audio_in_info.frames; 
	audio = read_wav(argv[1]);
	free(audio);
	efecto_convolucion(audio,IR, size);
	free(IR);
	*/


	
	return 0;
}