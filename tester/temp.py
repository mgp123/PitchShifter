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

