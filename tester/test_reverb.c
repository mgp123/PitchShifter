#include "../src/fft.h"
#include "../src/tiempo.h"

#include <stdio.h>

int main(int argc, char const *argv[])
{
	
	return 0;
}

void data_variarndo_size() {
	int tamanios = 50;
	int repeticiones = 5;

	float a[1024*tamanios];
	float b[1024*tamanios];

	unsigned long valCirc[tamanios][tamanios][repeticiones];

	unsigned long start, end;

	FILE *fptr;
	fptr = fopen("res.txt","w");


	for (int i = 0; i < tamanios; ++i)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);
		unsigned int sizeA = 1024*(i+1);
		for (int j = 0; j < tamanios; ++j)
		{
			unsigned int sizeB = 1024*(j+1);

			unsigned long mean = 0;

			for (int k = 0; k < repeticiones; ++k)
			{
				MEDIR_TIEMPO_START(start);
				float* temp = convolucion_lineal(a,sizeA,b,sizeB);
				free(temp);
				MEDIR_TIEMPO_STOP(end);
				valCirc[i][j][k] = end - start;
				mean += end - start;
			}
			mean = mean/tamanios;
			fprintf(fptr, "%lu ", mean );
		}

		fprintf(fptr,"\n");	
	}

	fclose(fptr); 
}

void data_comp_directa(){
	precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("res.txt","w");

	unsigned long start, end;

	int tamanios = 50;
	int repeticiones = 5;

	float a[1024*tamanios];
	float b[1024*tamanios];

	// se deja sizeB fijo
	unsigned int sizeB = 1024*10;



	for (int i = 0; i < tamanios; ++i)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int sizeA = 1024*(i+1);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			float* temp = convolucion_lineal(a,sizeA,b,sizeB);
			free(temp);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/tamanios;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	


	for (int i = 0; i < tamanios; ++i)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int sizeA = 1024*(i+1);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			float* temp = convolucion_lineal_directa(a,sizeA,b,sizeB);
			free(temp);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/tamanios;
		fprintf(fptr, "%lu ", mean );
	}

	fclose(fptr); 

}

// Este se corre varias veces, cambiando los flags de compilacion en cada una
// para data con asm, remplazar por convolucion_circular_asm.
void data_contra_C() {
	precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/res_circ2.txt","a");

	unsigned long start, end;

	int tamanios = 10;
	int repeticiones = 50;

	complejo a[4<<tamanios];
	complejo b[4<<tamanios];


	for (int i = 0; i < tamanios; ++i)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int sizeA = 4<<(i);

		printf("size A = %d\n", sizeA);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			convolucion_circular(a,b,sizeA,b);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/tamanios;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 

}