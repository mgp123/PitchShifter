#include "rw_audio.h"
#include "efectos.h"


int main(int argc, char *argv[])
{	

	precalcular_rotaciones();

	float* ir = read_wav("sonidos/ir.wav");
	unsigned int size_ir =  audio_in_info.frames;
	float* res = read_wav("sonidos/speech.wav");

	efecto_reverb(res,ir,size_ir);

	free(res);
	free(ir);


	return 0;
}