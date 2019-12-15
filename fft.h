#include <stdlib.h> 
#include <math.h>

struct Complejo
{
    float real;
    float imaginaria;
};

typedef struct Complejo complejo;

// devuelve un arreglo de numeros complejos que son iguales a el arreglo de numeros reales pasados
// lo que devuelve esta en el heap asi que hay que utilizar free cuando se termine de usar
complejo* complejizar(float* r, unsigned int size);
// idem pero usando un buffer pasado por parametro
void complejizar_buff(float* r, unsigned int size, complejo* buffer);

// devuelve un arreglo de numeros que son la parte real del arreglo de numeros complejos pasados
// lo que devuelve esta en el heap asi que hay que utilizar free cuando se termine de usar
float* parte_real(complejo* c, unsigned int size);
// idem pero usando un buffer pasado por parametro
void parte_real_buff(complejo* c, unsigned int size, float* buffer);

// devuelve la  potencia de 2 >= x mas proxima. (el mas cercano por arriba)
// supone x != 0 
unsigned int siguiente_potencia(unsigned int x);


// transformada de Fourier probando Cooley–Tukey FFT algorithm segun 
// el algoritmo en https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm#Pseudocode.
// supone que size son potencias de 2.
// lo que devuelve esta en el heap asi que hay que utilizar free cuando se termine de usar
complejo* ditfft2(complejo* c, unsigned int size);
void ditfft2_buff(complejo* c, unsigned int size, complejo* buffer);
void ditfft2_buff_aux(complejo* c, unsigned int size,unsigned int hop, complejo* buffer);
