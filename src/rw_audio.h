#include <sndfile.h>
#include <stdlib.h>
#include <stdio.h>

#include <math.h>
#define PI 3.141592654

// robado partes de 
// https://stackoverflow.com/questions/35856499/how-to-read-an-audio-file-in-an-array-format-from-libsndfile-library-like-matlab
SNDFILE* audio_in;
SF_INFO audio_in_info;

SNDFILE* audio_out;
SF_INFO audio_out_info;

// Devuelve un arreglo de floats que corresponden al audio. Supone MONO
// Tambien modifica audio_in y audio_in_info para que coinsidan con la nueva informacion.
// lo que devuelve esta en el heap asi que hay que utilizar free cuando se termine de usar
float* read_wav(char* path);

// Guarda un nuevo audio con el nombre indicado por name y el arreglo de floats indicado por audio.
// Actualmente usa la configuracion (frames per second, channels, etc..) de audio_in_info.
void save_wav(char* name, float* audio);

void save_wav_len(char* name, float* audio, unsigned int size);


