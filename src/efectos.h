#include "rw_audio.h"
#include "fft.h"

// Efecto de demo
void efecto_phaser(float* ptr);

// toma el audio , la IR y el la tamaño de la IR. Supone que audio info contiene la informacion necesaria de audio 
// supone MONO y que ambos audios tienen el mismo samplerate
// no anda todavia
void efecto_convolucion(float* audio, float* IR, unsigned int IR_size);