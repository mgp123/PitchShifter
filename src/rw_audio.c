#include "rw_audio.h"

float* read_wav(char* path) {
	audio_in_info.format = 0;
	audio_in = sf_open(path,SFM_READ,&audio_in_info);
	if (audio_in == NULL)
	{
		printf("No se pudo abrir el archivo %s\n",path);
		return NULL;
	}

	int size = audio_in_info.frames*audio_in_info.channels;    

	// supone channel = 1, es decir mono.
	float* res = (float *) malloc(size*sizeof(float));
	sf_read_float(audio_in,res,size);

	sf_close(audio_in);

	return res;
}


void save_wav(char* name, float* audio) {
	int size = audio_in_info.frames*audio_in_info.channels;

	audio_out_info = audio_in_info;
	audio_out = sf_open(name, SFM_WRITE, &audio_out_info);
	sf_write_float(audio_out, audio, size);
	sf_close(audio_out);
}


void save_wav_len(char* name, float* audio, unsigned int size) {
	audio_out_info = audio_in_info;
	audio_out = sf_open(name, SFM_WRITE, &audio_out_info);
	sf_write_float(audio_out, audio, size);
	sf_close(audio_out);
}
