#include "rw_audio.h"
#include "efectos.h"

int main(int argc, char *argv[])
{	

	
	float* audio;  
	audio = read_wav(argv[1]);
	stretch(audio, audio_in_info.frames,  2, 2048, (2048*3)/4);;
	free(audio);

	return 0;
}