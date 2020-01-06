#include "rw_audio.h"
#include "fft.h"

// Efecto de demo
void efecto_phaser(float* ptr);

// toma el audio , la IR y el la tamaño de la IR. Supone que audio info contiene la informacion necesaria de audio 
// supone MONO y que ambos audios tienen el mismo samplerate
// no anda todavia
void efecto_reverb(float* audio, float* IR, unsigned int IR_size);

// devuelve el audio cambiando la duracion por size/f pero manteniendo la frecuencia
// devuelve en el heap
float* stretch(float* audio, unsigned int size, float f, unsigned int window_size, unsigned int hop);

// devuelve el audio resampleado con velocidad f usando interpolacion
//Ej: si f = 2 entonces se devuelve un audio de mitad de duracion y con el doble de frecuencia.
// devuelve en el heap
float* resample(float* audio, unsigned int size, float f);

extern float* resample_asm(float* audio, int size, float f);


// genera el audio con el efecto de repitch multiplicando las frecuencias por f.
// utiliza strech y resample
void efecto_repitch(float* audio, unsigned int size, float f);