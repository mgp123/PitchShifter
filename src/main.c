#include "rw_audio.h"
#include "efectos.h"
#include <string.h>

void help();
int mono();
int main(int argc, char *argv[])
{	
	precalcular_rotaciones();

	if (argc < 3 ) {
		help();
		return 0;
	}

	if (strcmp(argv[1], "stretch") == 0) {
		if (argc >= 4) {
			float* audio = read_wav(argv[2]);
			unsigned int size =  audio_in_info.frames;
			float f = atof(argv[3]);

			if (audio == NULL)
			{
				return 0;
			}

			if (! mono()){
				free(audio);
				return 0;
			}

			unsigned int window_size;
			unsigned int hop;
			// parametros del stretch por default si no se colocan en la consola
			if (argc < 6)
			{
				window_size = 2048;
				hop = window_size/16;
			}

			else {
				window_size = atoi(argv[4]);
				// chequear que window size sea potencia de 2.
				hop = atoi(argv[5]);
			}

			efecto_stretch(audio,f, window_size, hop);
			free(audio);
			return 0;
		}

		else  {
			help();
			return 0;
		}
	}

	else if (strcmp(argv[1], "reverb") == 0)
	{
		if (argc != 4) {
			help();
			return 0;
		}

		float* ir = read_wav(argv[3]);
		unsigned int ir_size =  audio_in_info.frames;

		if (ir == NULL)
		{
			return 0;
		}

		if (! mono()){
			free(ir);
			return 0;
		}

		float* audio = read_wav(argv[2]);

		if (audio == NULL) {
			free(ir);
			return 0;
		}

		if (! mono()){
			free(audio);
			free(ir);
			return 0;
		}

		efecto_reverb(audio, ir, ir_size);
		free(audio);
		free(ir);

		return 0;
		
	}

	else if (strcmp(argv[1], "vocoder") == 0) {

		if (argc < 4)
		{
			help();
			return 0;
		}

		float* carrier = read_wav(argv[3]);
		unsigned int carrier_size =  audio_in_info.frames;

		if (carrier == NULL)
		{
			return 0;
		}

		if (! mono()){
			free(carrier);
			return 0;
		}

		float* modulator = read_wav(argv[2]);

		if (modulator == NULL)
		{
			free(carrier);
			return 0;
		}

		if (! mono()){
			free(carrier);
			free(modulator);
			return 0;
		}

		unsigned int modulator_size = audio_in_info.frames;

		if (modulator_size > carrier_size)
		{
			free(carrier);
			free(modulator);

			printf("%s\n","Se necesita que el modulator sea de menor duracion que el carrier");
			printf("Pero %s es mas largo que %s\n",argv[2], argv[3]);
			return 0;
		}

		unsigned int window_size = 2048;

		if (argc > 4)
		{
			window_size = atoi(argv[5]);
			// chequear potencia de 2
		}

		efecto_vocoder(modulator, carrier, window_size);
		free(modulator);
		free(carrier);
	}

	else if (strcmp(argv[1], "repitch") == 0)
	{

		if (argc < 4)
		{
			help();
			return 0;
		}

		float* audio = read_wav(argv[2]);


		if (audio == NULL ){
			return 0;
		}

		if (! mono()){
			free(audio);
			return 0;
		}

		float f = atof(argv[3]);

		efecto_repitch(audio,f);
		free(audio);
	}

	return 0;
	
}

void help() {
	printf("Todas las entradas de audio deben ser mono y de formato wav\n");
	printf("\n");

	printf("stretch: escala la duracion del audio por el float pasado pero conservando las frecuencias\n");
	printf("	./main stretch <audio> <float> \n");
	printf("	./main stretch mi_audio.wav 0.75 \n");
	printf("\n");
	printf("	tambien puede agregarse parametros opcionales window_size y hop para mayor control\n");
	printf("	- window_size debe ser potencia de 2 y <= 2048\n");
	printf("	- hop debe ser  menor a window_size\n");
	printf("	./main stretch <audio> <float> <window_size> <hop> \n");
	printf("	./main stretch mi_audio.wav 0.75 2048 512\n");
	printf("\n");

	printf("repitch: escala el tono del audio con el float pasado por parametro.\n");
	printf("	./main repitch <audio> <float> \n");
	printf("	./main repitch mi_audio.wav 0.5  	(una octava mas grave) \n");
	printf("\n");

	printf("reverb: aplica una reverberacion dada por la impulse_response pasada por parametro\n");
	printf("	./main reverb <audio> <impulse>\n" );
	printf("	./main reverb mi_audio.wav impulse.wav\n");
	printf("\n");

	printf("vocoder: utiliza la primera entrada como modulator y la segunda como carrier.  \n");
	printf("         modulator debe tener menor duracion que el carrier\n");
	printf("	./main vocoder <modulator> <carrier>\n" );
	printf("	./main vocoder modulator.wav carrier.wav\n");
	printf("\n");
	printf("	tambien puede agregarse parametro opcional window_size\n");
	printf("	- window_size debe ser potencia de 2 y <= 2048\n");	
	printf("	./main vocoder <modulator> <carrier> <window_size>\n" );
	printf("	./main vocoder modulator.wav carrier.wav 2048\n");



}

int mono() {
	if (audio_in_info.channels != 1 ) {
		printf("%s\n","Entrada de audio no es mono.");
		return 0;
	}
	return 1;
}
