#include "rw_audio.h"
#include "efectos.h"


int main(int argc, char *argv[])
{	

	precalcular_rotaciones();

	float* ir = read_wav("impulse_response/ir5.wav");
	unsigned int size_ir =  audio_in_info.frames;
	float* res = read_wav("sonidos/speech.wav");
	efecto_reverb(res,ir,size_ir);

	free(res);
	free(ir);

	return 0;
}