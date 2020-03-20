#include "../src/efectos.h"
#include "../src/tiempo.h"

#include <stdio.h>

void compC_audio_size() {
	precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/stretch_audio_size.txt","a");

	unsigned long start, end;

	int tamanios = 250;
	int repeticiones = 10;

	float a[tamanios*2048 + 2048*2];

	unsigned int window_size = 2048;
	unsigned int hop = window_size/16;
	float f = 0.5;


	for (int i = 0; i < tamanios; i+= 10)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int sizeA = (i+2)*2048;

		printf("size A = %d\n", sizeA);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			stretch(a,sizeA,f,window_size, hop);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 
}

void compC_f() {
	precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/stretch_f.txt","a");

	unsigned long start, end;

	int tamanios = 10;
	int repeticiones = 10;

	float a[250*1024];

	unsigned int window_size = 2048;
	unsigned int hop = window_size/16;
	unsigned int sizeA = 250*1024;


	for (int i = 0; i < tamanios; i+= 1)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);
		float f = (i+1)* 1.0/(tamanios/2);  // se va de 0.2 a 2 en f

		unsigned long mean = 0;

		printf("f  = %f\n", f);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			stretch(a,sizeA,f,window_size, hop);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 
}


void compC_hop() {
	precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/stretch_hop.txt","a");

	unsigned long start, end;

	int tamanios = 20;
	int repeticiones = 10;

	float a[250*1024];

	unsigned int window_size = 2048;
	unsigned int sizeA = 250*1024;
	float f = 0.5;


	for (int i = 0; i < tamanios; i+= 1)
	{
		unsigned int hop = (2048 * (i+1))/tamanios;
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;

		printf("hop  = %d\n", hop);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			stretch(a,sizeA,f,window_size, hop);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 
}

int main(int argc, char const *argv[])
{
	compC_hop();
	compC_f();
	compC_audio_size();
	return 0;
}