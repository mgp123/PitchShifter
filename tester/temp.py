import seaborn as sns; sns.set()
import numpy as np
import matplotlib.pyplot as plt


data = np.loadtxt("convolucion_data.txt")
ax = sns.heatmap(data,cbar_kws={'label': 'ciclos'})

ax.set_xticks(np.arange(5)*10)
ax.set_xticklabels((np.arange(5))*10*1024 + 1024)
plt.xticks(rotation=0)
plt.xlabel("sizeA") 

ax.set_yticks(np.arange(5)*10)
ax.set_yticklabels((np.arange(5))*10*1024 + 1024)
plt.yticks(rotation=0)
plt.ylabel("sizeB") 

plt.tight_layout()
plt.show()


data = np.loadtxt("conv_directa.txt")
plt.plot((np.arange(50)*1.0+1) * 1024, data[0], label = "conv por bloques")
plt.plot((np.arange(50)*1.0+1) * 1024, data[1], label = "conv directa")
plt.legend()
plt.xlabel("sizeA") 
plt.ylabel("ciclos")
plt.tight_layout()
plt.show()


data = np.loadtxt("res_circ.txt")
plt.plot(2**(np.arange(10)+2), data[0], label = "O0")
plt.plot(2**(np.arange(10)+2), data[1], label = "O1")
plt.plot(2**(np.arange(10)+2), data[2], label = "O2")
plt.plot(2**(np.arange(10)+2), data[3], label = "O3")
plt.plot(2**(np.arange(10)+2), data[4], label = "asm")


plt.legend()
plt.xlabel("sizeA") 
plt.ylabel("ciclos")
plt.tight_layout()
plt.show()

data = np.loadtxt("res_circ2.txt")
#plt.plot(2**(np.arange(10)+2), data[0], label = "O0 con fft en asm")
plt.plot(2**(np.arange(10)+2), data[1], label = "O1 con fft en asm")
plt.plot(2**(np.arange(10)+2), data[2], label = "O2 con fft en asm")
plt.plot(2**(np.arange(10)+2), data[3], label = "O3 con fft en asm")
plt.plot(2**(np.arange(10)+2), data[4], label = "asm")


plt.legend()
plt.xlabel("sizeA") 
plt.ylabel("ciclos")
plt.tight_layout()
plt.show()


