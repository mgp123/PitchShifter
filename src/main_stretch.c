#include "rw_audio.h"
#include "efectos.h"


int main(int argc, char *argv[])
{	

	precalcular_rotaciones();
	//float* carrier = read_wav("impulse_response/ir5.wav");
	//unsigned int size_ir =  audio_in_info.frames;
	//float* modulator = read_wav("sonidos/maca.wav");
	//efecto_reverb(modulator,carrier, size_ir);
	float* audio = read_wav("sonidos/Maple.wav");
	unsigned int size =  audio_in_info.frames;
	float f = 0.75;
	unsigned int window_size = 2048;
	unsigned int hop = 256;
	// 0 = false, 1 = true
	int repit = 1;
	int stre = 0;

	if(repit)
		printf("repitch... \n");
		efecto_repitch_asm(audio,size,f);
	if(!repit && stre){
		printf("stretch...\n");
		float* nuevo = stretch(audio, size, f, window_size, hop);
		save_wav_len("stretch.wav",nuevo, size/f + window_size);
		free(nuevo);
	}
	free(audio);

	//free(carrier);
	//free(modulator);
	return 0;
}
