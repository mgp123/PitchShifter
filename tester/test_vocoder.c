#include "../src/efectos.h"
#include "../src/tiempo.h"

#include <stdio.h>



void compC() {
		precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/vocoder_data.txt","a");

	unsigned long start, end;

	int tamanios = 500;
	int repeticiones = 10;

	float a[tamanios*1024];
	float b[tamanios*1024];
	float c[tamanios*1024];

	unsigned int window_size = 1024;
	// void vocoder(float* modulator, float* carrier, unsigned int window_size, float* buffer, unsigned int size);


	for (int i = 0; i < tamanios; i+= 10)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int sizeA = (i+1)*1024;

		printf("size A = %d\n", sizeA);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			vocoder_asm(a,b,window_size,c,sizeA);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 
}


void distintos_windows() { 
		precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/vocoder_window.txt","w");

	unsigned long start, end;

	int tamanios = 10;
	int repeticiones = 50;

	float a[250*1024];
	float b[250*1024];
	float c[250*1024];
	for (int k = 0; k < 4; ++k)
	{
		unsigned int sizeA = (k+1)*250*1024/4;

	for (int i = 0; i < tamanios; ++i)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int window_size = 4<<(i);

		printf("window_size  = %d\n", window_size);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			vocoder_asm(a,b,window_size,c,sizeA);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");
	}
	
	fclose(fptr); 
}

void distintas_windows_compC() {
	precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/vocoder_window_compC.txt","a");

	unsigned long start, end;

	int tamanios = 10;
	int repeticiones = 50;

	float a[250*1024];
	float b[250*1024];
	float c[250*1024];

	unsigned int sizeA = 250*1024; //fijo

	for (int i = 0; i < tamanios; ++i)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int window_size = 4<<(i);

		printf("window_size  = %d\n", window_size);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			vocoder_asm(a,b,window_size,c,sizeA);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 
}



int main()
{
	distintas_windows_compC();
	return 0;
}

