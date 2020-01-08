#include "rw_audio.h"
#include "efectos.h"


int main(int argc, char *argv[])
{	

	precalcular_rotaciones();

	float* carrier = read_wav("impulse_response/ir5.wav");
	unsigned int size_ir =  audio_in_info.frames;
	float* modulator = read_wav("sonidos/maca.wav");
	efecto_reverb(modulator,carrier, size_ir);

	free(carrier);
	free(modulator);

	return 0;
}