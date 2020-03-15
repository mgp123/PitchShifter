#include "rw_audio.h"
#include "fft.h"

// Efecto de demo
void efecto_phaser(float* ptr);

// toma el audio , la IR y el la tamaño de la IR. Supone que audio info contiene la informacion necesaria de audio 
// supone MONO y que ambos audios tienen el mismo samplerate
void efecto_reverb(float* audio, float* IR, unsigned int IR_size);

// supone que modulator_size <= carrier_size. 
// supone que la longitud del modulator se encuentra en audio info 
void efecto_vocoder(float* modulator, float* carrier, unsigned int window_size);
// funcion a ser llamada para el vocoder
void vocoder(float* modulator, float* carrier, unsigned int window_size, float* buffer, unsigned int size);
extern void vocoder_asm(float* modulator, float* carrier, unsigned int window_size, float* buffer, unsigned int size);


void efecto_stretch(float* audio, float f, unsigned int window_size, unsigned int hop);
// devuelve el audio cambiando la duracion por size/f pero manteniendo la frecuencia
// devuelve en el heap
float* stretch(float* audio, unsigned int size, float f, unsigned int window_size, unsigned int hop);

extern float* stretch_asm(float* audio, unsigned int size, float f, unsigned int window_size, unsigned int hop);

// devuelve el audio resampleado con velocidad f usando interpolacion
//Ej: si f = 2 entonces se devuelve un audio de mitad de duracion y con el doble de frecuencia.
// devuelve en el heap
float* resample(float* audio, unsigned int size, float f);

extern float* resample_asm(float* audio, int size, float f);


// genera el audio con el efecto de repitch multiplicando las frecuencias por f.
// utiliza strech y resample
void efecto_repitch(float* audio, float f);

// coloca en el buffer la funcion de hanning para ese size. 
//Para cosas con overlap
void precalcular_hanning(float* buff, unsigned int size);
