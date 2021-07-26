# PitchShifter
<!--- Pitch shifter and other sound effects implemented using C and x86 ASM + SIMD for linux. --->
Pitch Shifter y otros efectos de sonido implementados utilizando C y ASM x86 + SIMD, para Linux.

## Descripción
Desarrollamos implementaciones en lenguaje ensamblador Intel de 64 bits de los efectos de audio Stretch, Reverb, Vocoder y Resample; este último no lo consideramos un efecto por su cuenta, pero en conjunto con Stretch construyen la implementación del Pitch-Shifter. 

`Stretch` permite aumentar o reducir la velocidad del audio manteniendo su tono original.

`Resample` simula un cambio de samplerate del audio por una constante (que en el caso del Pitch-Shifter estará relacionada con la constante a usar en la parte de Stretch del efecto) agregando y quitando samples según necesite. 

`Reverb` imita la reverberación que se generaría al escuchar al audio en un espacio cerrado amplio (por ejemplo una iglesia) basado en un audio impulse response.

`Vocoder` simula que el sintetizador (carrier) está hablando como lo hace la persona del audio introducido (modulator). 

`Pitch-Shifter` permite alterar el tono del audio sin alterar su velocidad, utilizando Resample y Stretch en conjunto.

Para cada efecto realizado proveemos una implementaci ́on en C y otra en ASM que hace uso de SIMD, para poder comparar y observar las ventajas que proporcionan las optimizaciones introducidas en la segunda implementación.

## Modo de uso
Para poder compilar el código provisto incluimos un archivo Makefile. El código que proveemos hace uso de la librería `sndfile`<sup>[1](#footnotes)</sup>, para instalarla se puede usar el comando `make install` en el directorio raíz. Estando ya instalada la librería se puede compilar el trabajo utilizando el comando `make`.

Se incluye el archivo `ejemplos.sh` que descarga la librería, compila el trabajo y crea ejemplos para cada uno de los filtros. Ejecutar con `./ejemplos.sh`

Una vez compilado el programa se ejecuta con el comando `./main` desde el directorio raíz. **Todos los audios** que se utilicen como parámetros deben ser de tipo mono y extensión `.wav`. Los parámetros disponibles para la utilización del programa son los siguientes:
- `stretch`: aplica el efecto `stretch` a un audio pasado por parámetro, con un factor de estiramiento `float`.
   
   `./main stretch <audio> <float> [window_size][hop]`
   
   `./main stretch mi_audio.wav 0.75`

donde `window_size` y `hop` son parámetros opcionales, donde el primero debe ser potencia de 2 y menor o igual a 2048, y el segundo debe ser menor al primero. Por default, sus valores son `2048` y `128` respectivamente. Para estiramientos grandes, el sonido dara un mejor resultado usando `hop` pequeños. `float` debe ser positivo.
- `Repitch`: aplica el efecto `Pitch-Shift` a un audio por el `float` dado.
   
   `./main repitch <audio> <float>`
   
   `./main repitch mi_audio.wav 0.5`

donde `float`=0.5 vuelve al audio una octava más grave y 2 lo vuelve una octava más agudo (2<sup>n</sup> vuelve al audio n octavas más agudo o grave, según si n es positivo o negativo). Aunque puede tomar como entrada cualquier `float` distinto de cero, un rango razonable de entrada para que funcione correctamente es una octava y media mas agudo o grave (aprox de 0.35 a 2.82)

- `Reverb`: aplica el efecto `Reverb` al audio, donde el eco está basado en un .wav `impulse_response`.
   
   `./main reverb <audio> <impulse> `
   
   `./main reverb mi_audio.wav impulse.wav`
- `Vocoder`: aplica el efecto `Vocoder` dados un audio `modulator` y otro `carrier` que debe ser más largo que `modulator`. Toma un parámetro opcional `window_size` que debe ser potencia de 2 y menor a 2048. Por default es 2048.
   
   `./main vocoder <modulator> <carrier> [window_size]`
   
   `./main vocoder modulator.wav carrier.wav 2048`



## Footnotes
<sup>1</sup> https://github.com/erikd/libsndfile
