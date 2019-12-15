#include "rw_audio.h"

float* read_wav(char* path) {
	audio_in_info.format = 0;
	audio_in = sf_open(path,SFM_READ,&audio_in_info);

	int size = audio_in_info.frames*audio_in_info.channels;    

	// supone channel = 1, es decir mono.
	float* res = (float *) malloc(size*sizeof(float));
	sf_read_float(audio_in,res,size);

	sf_close(audio_in);

	return res;
}


void save_wav(char* name, float* audio) {
	int size = audio_in_info.frames*audio_in_info.channels;
	printf("%d\n",audio_in_info.channels );  

	audio_out_info = audio_in_info;
	audio_out = sf_open(name, SFM_WRITE, &audio_out_info);
	sf_write_float(audio_out, audio, size);
	sf_close(audio_out);
}

void efecto_phaser(float* ptr) {
	int frames = audio_in_info.frames;

	float delay_milliseconds = 10.0;
	int delay = (int) (audio_in_info.samplerate *delay_milliseconds/1000.0);

	float period_milliseconds = 500.0;
	int period = (int) (audio_in_info.samplerate *period_milliseconds/1000.0);

	float amplitud_milliseconds = 10.0;
	int amplitud = (int) (audio_in_info.samplerate *amplitud_milliseconds/1000.0);

	float decay = 1.0;

	int size = audio_in_info.frames*audio_in_info.channels;    
	float* out = (float *) malloc(size*sizeof(float));

	for (int i = 0; i < frames; ++i)
	{
		out[i] = ptr[i];
	}

	for (int i = delay +  amplitud; i < frames - delay - amplitud; ++i)
	{
		int offset = (int) (cos((2*PI*i)/period)*amplitud + delay);
		out[i] = ptr[i] + ptr[i-offset]*decay;
	}
	save_wav("output.wav",out);
	free(out);

}

