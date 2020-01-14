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
	save_wav("phaser.wav",out);
	free(out);
}


void efecto_reverb(float* audio, float* IR, unsigned int IR_size){
	unsigned int audio_size = audio_in_info.frames;
	float* conv =  convolucion_lineal(audio, audio_size, IR, IR_size);

	//  para bajar el volumen un poco, la convolucion aumenta el volumen
	// esta reduccion es a ojo. Puede afectar demasiados a algunas ir.
	// reducirlo de manera que quede homogeneo para todas las ir
	// requiere analizar la ir de alguna forma, ni idea
	for (int i = 0; i < audio_size+IR_size-1; ++i)
	{
		conv[i] /= 15.0;
	}

	save_wav_len("convolucion.wav",conv,audio_size+IR_size-1);
	free(conv);
	return;
}

float* stretch(float* audio, unsigned int size, float f, unsigned int window_size, unsigned int hop){
	float phase[window_size];
	float hanning[window_size];
	unsigned int nuevo_largo = size/f + window_size;
	float* output = calloc(nuevo_largo, sizeof(float));

	for (int i = 0; i < window_size; ++i)
	{
		phase[i] = 0;

		hanning[i] = (float) sin((M_PI*i)/(window_size-1));
		hanning[i] *= hanning[i];
	}

	for (unsigned int i = 0; i < size - window_size - hop; i+=f*hop)
	{
		float a1[window_size];
		float a2[window_size];
		for (int j = 0; j < window_size; ++j)
		{
			a1[j] = audio[i+j]*hanning[j];
			a2[j] = audio[i+hop+j]*hanning[j];
		}

		complejo s1[window_size];
		complejo s2[window_size];

		ditfft2(a1,window_size,s1);
		ditfft2(a2,window_size,s2);

		for (int j = 0; j < window_size; ++j)
		{

			float normas2 = sqrt(s2[j].real*s2[j].real + s2[j].imaginaria*s2[j].imaginaria);

			complejo frac;
			frac.real = (s1[j].real*s2[j].real + s1[j].imaginaria*s2[j].imaginaria);
			frac.imaginaria = (s1[j].real*s2[j].imaginaria - s1[j].imaginaria*s2[j].real);

			float v_angular = (float) atan2((double) frac.imaginaria, (double) frac.real);

			phase[j] += v_angular/f;
			if (phase[j] > M_PI) {phase[j] -= 2*M_PI;}
			else if(phase[j] < - M_PI) {phase[j] += 2*M_PI;}

			complejo rephased;
			rephased.real = cos(phase[j])*normas2;
			rephased.imaginaria = sin(phase[j])*normas2;
			s2[j] = rephased;


			s1[j].real = 0;
			s1[j].imaginaria = 0;

		}

		iditfft2(s2,window_size,s1);

		for (int j = 0; j < window_size; ++j)
		{
			unsigned int inicio = (unsigned int) (i/f);
			output[inicio+j] += s1[j].real*hanning[j];
		}
	}

	/*save_wav_len("stretched.wav",output,nuevo_largo);
	free(output);*/
	return output;
}


float* resample(float* audio, unsigned int size, float f) {
	unsigned int nuevo_largo = size/f;
	float* output = malloc(nuevo_largo*sizeof(float));
	f = (size-1)*1.0/(1.0*nuevo_largo-1.0);


	for (int i = 0; i < nuevo_largo; ++i)
	{
		float x = floor(i*f);
		unsigned int a = x;
		unsigned int b = x+1;
		x = i*f;

		float fa = (float ) a;
		output[i] = audio[a] + (audio[b]- audio[a]) * (x-fa);
	}
	return output;
}


void efecto_repitch(float* audio, unsigned int size, float f) {
	float*  temp;  
	float* output;

	float resample_coef = f;

	temp = stretch(audio, audio_in_info.frames, 1./resample_coef, 512,512/2);
	output = resample(temp, (unsigned int)  audio_in_info.frames*resample_coef,  resample_coef);

	save_wav_len("repitch.wav",output,audio_in_info.frames);

	free(temp);
	free(output);
}



void efecto_vocoder(float* modulator, float* carrier, unsigned int window_size) {
	unsigned int size = audio_in_info.frames;
	float* output = calloc(size,sizeof(float));
	vocoder_asm(modulator,carrier,window_size,output,size);
	//  para bajar el volumen un poco
	for (int i = 0; i < size; ++i)
	{
		output[i] /= 50.0;
	}
	save_wav("vocoder.wav",output);
	free(output);
}


void vocoder(float* modulator, float* carrier, unsigned int window_size, float* output, unsigned int size) {
	float hanning[window_size];

	precalcular_hanning(hanning, window_size);
	complejo F1[window_size];
	complejo F2[window_size];

	for (int i = 0; i < size - window_size+1; i += window_size/2)
	{
		ditfft2_asm(&modulator[i],window_size,F1);
		ditfft2_asm(&carrier[i],window_size,F2);

		for(int j = 0; j < window_size; j++) {
			float modulo = sqrt(F1[j].real*F1[j].real + F1[j].imaginaria*F1[j].imaginaria); 
			F2[j].real *= modulo;
			F2[j].imaginaria *= modulo;
		}

		iditfft2_asm(F2,window_size,F1);

		for(int j = 0; j < window_size; j++) {
			output[i+j] += F1[j].real*hanning[j];
		}
	}	
}

void precalcular_hanning(float* hanning, unsigned int window_size) {
	for (int i = 0; i < window_size; ++i)
	{
		hanning[i] = (float) sin((M_PI*i)/(window_size-1));
		hanning[i] *= hanning[i];
	}
}
