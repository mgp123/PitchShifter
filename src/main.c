#include "rw_audio.h"
#include "efectos.h"

int main(int argc, char *argv[])
{	
	/*float* audio;
	audio = read_wav(argv[1]);

	float resample_coef = 1.10;
	efecto_repitch(audio, audio_in_info.frames,resample_coef);
	free(audio);*/

	precalcular_rotaciones();
	float c_in[64];
	complejo c_out[64];
	complejo c_out_C[64];
	float temp = -10;

	for (int i = 0; i < 64; ++i)
	{
		c_in[i] = i;
	}

	ditfft2_asm( c_in, 64, c_out);
	ditfft2( c_in, 64, c_out_C);


	for (int i = 0; i < 64; ++i)
	{
		printf("ASM : Real %f. Imaginaria %f\n",c_out[i].real, c_out[i].imaginaria);
		printf("C : Real %f. Imaginaria %f\n",c_out_C[i].real, c_out_C[i].imaginaria);
		printf("\n");

	}


	return 0;
}