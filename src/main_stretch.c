#include "rw_audio.h"
#include "efectos.h"


int main(int argc, char *argv[])
{	

	precalcular_rotaciones();
	//float* carrier = read_wav("impulse_response/ir5.wav");
	//unsigned int size_ir =  audio_in_info.frames;
	//float* modulator = read_wav("sonidos/maca.wav");
	//efecto_reverb(modulator,carrier, size_ir);
	float* audio = read_wav("sonidos/bowie.wav");
	unsigned int size =  audio_in_info.frames;
	float f = 1.5;
	unsigned int window_size = 1024;
	unsigned int hop = 32;
	float* nuevo = stretch_asm(audio, size, f, window_size, hop);
	//free(carrier);
	//free(modulator);
	save_wav_len("stretch.wav",nuevo, size/f + window_size);
	free(audio);
	free(nuevo);
	return 0;
}