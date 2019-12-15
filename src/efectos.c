#include "efectos.h"

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


void efecto_convolucion(float* audio, float* IR, unsigned int IR_size){
	unsigned int audio_size = audio_in_info.frames;
	float* conv =  convolucion(audio, audio_size, IR, IR_size);
	save_wav("output.wav",conv);
	free(conv);
	return;
}