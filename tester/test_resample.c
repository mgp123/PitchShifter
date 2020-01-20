#include "../src/efectos.h"
#include "../src/tiempo.h"

#include <stdio.h>


void estiramiento() { 
	FILE *fptr;
	fptr = fopen("tester/data_resample_estir.txt","a");
	float audio[1024*250];
	unsigned long start, end;


	int repeticiones = 5;
	float step = 0.1;
	int top = 50; // osea f = 0.1*50 = 5
	for (int i = 0; i < top; ++i)
	{
		unsigned long mean = 0;

		printf("Estiramiento: Completado %f\n", (100.0*i)/top);

		float f = 1.0 + step*i;
		f = 1.0/f;

		for (int j = 0; j < repeticiones; ++j)
		{

			MEDIR_TIEMPO_START(start);
			float* res = resample_asm(audio, 1024*250, f);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
			free(res);
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 

}
void compresion() {
	FILE *fptr;
	fptr = fopen("tester/data_resample_compres.txt","a");
	float audio[1024*250];

	int repeticiones = 5;
	float step = 0.1;
	int top = 50; // osea f = 0.1*50 = 5
	unsigned long start, end;

	for (int i = 0; i < top; ++i)
	{
		unsigned long mean = 0;
		float f = 1.0 + step*i;
		printf("Compresion: Completado %f. f actual: %f\n", (100.0*i)/top,f);
		for (int j = 0; j < repeticiones; ++j)
		{
			MEDIR_TIEMPO_START(start);
			float* res = resample_asm(audio, 1024*250, f);
			MEDIR_TIEMPO_STOP(end);
			mean += end - start;
			free(res);
		}

		mean = mean/repeticiones;
		fprintf(fptr, "%lu ", mean );
	}

	fprintf(fptr,"\n");	
	fclose(fptr); 
}


int main(int argc, char const *argv[])
{
	estiramiento();
	compresion();
	return 0;
}