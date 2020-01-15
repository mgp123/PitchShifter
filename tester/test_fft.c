#include "../src/efectos.h"
#include "../src/tiempo.h"

#include <stdio.h>

void distintas_windows_compC();
int main(int argc, char const *argv[])
{
	distintas_windows_compC();
	return 0;
}

void distintas_windows_compC() {
	precalcular_rotaciones();

	FILE *fptr;
	fptr = fopen("tester/data_fft.txt","a");

	unsigned long start, end;

	int tamanios = 10;
	int repeticiones = 50;

	float a[2048];
	complejo b[2048];

	for (int i = 0; i < tamanios; ++i)
	{
		printf("Completado %f\n", (100.0*i)/tamanios);

		unsigned long mean = 0;
		unsigned int window_size = 4<<(i);

		printf("size  = %d\n", window_size);

		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			ditfft2_asm(a,window_size,b);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
		}

		mean = mean/tamanios;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 
}
