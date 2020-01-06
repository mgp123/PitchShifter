#include <stdlib.h> 
#include <math.h>

#define PRECALCULADOS 1024

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
void ditfft2(float* c, unsigned int size, complejo* buffer);
void ditfft2_aux(float* c, unsigned int size,unsigned int hop, complejo* buffer);

// toma un arreglo que representa el audio en estereo. es decir pares de floats. 
// devuelve la transformada de cada canal por separado, primero todo el canal 1 y luego todo el canal 2
void ditfft2_stereo(float* c, unsigned int size, complejo* buffer);

// inversa de transformada de fourier.
void iditfft2(complejo* c, unsigned int size, complejo* buffer);
void iditfft2_aux(complejo* c, unsigned int size,unsigned int hop, complejo* buffer);


// toma la transformada de dos arreglos del mismo tamaño
// realiza multiplicacion compleja, elemento a elemento y lo coloca en el buffer
// (la conv circular de los dos arreglos iniciales)
// supone size permite realizar idfft
void convolucion_circular(complejo* c1, complejo* c2, unsigned int size, complejo* buffer);
extern void convolucion_circular_asm(complejo* c1, complejo* c2, unsigned int size, complejo* buffer);

// convolucion de audio con IR. La salida tiene tamaño de size1 + size2 -1. 
// supone size1 >> size2
// realiza la convolucion LINEAL, NO LA CIRCULAR
// lo que devuelve esta en el heap asi que hay que utilizar free cuando se termine de usar
float* convolucion_lineal(float* audio, unsigned int size1, float* IR, unsigned int size2);

// rotaciones a usar por fft
// las rotaciones van de 0 a -pi avanzado de a -1/precalculados
void precalcular_rotaciones();
complejo rotaciones[PRECALCULADOS];


// fft y ifft en simd. Usa un arreglo precalculado de rotaciones por lo que debe llamarse a la 
// funcion precalcular_rotaciones antes de la primer llamada a esta funcion
// requiere que size sea potencia de 2 y size <= PRECALCULADOS*2
extern void ditfft2_asm(float* c, unsigned int size, complejo* buffer);
extern void iditfft2_asm(complejo* c, unsigned int size, complejo* buffer);
