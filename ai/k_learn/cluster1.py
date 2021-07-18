#Aplicar k-menas a un csv de prueba.
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sb
from sklearn.cluster import KMeans
from sklearn.metrics import  pairwise_distances_argmin_min
from mpl_toolkits.mplot3d import Axes3D

plt.rcParams['figure.figsize'] = (16, 9)
plt.style.use('ggplot')

dataframe = pd.read_csv("analisis.csv")
# -----------------------------------------------------------------------------------
# Cargamos dentro del array los datos de entrada para K
X = np.array(dataframe[["op","ex","ag"]])
y = np.array(dataframe['categoria'])
X.shape #(140,3)


# Plot de la grafica para ver Elbow Curve
"""Nc = range(1, 20)
kmeans = [KMeans(n_clusters=i) for i in Nc]
kmeans
score = [kmeans[i].fit(X).score(X) for i in range(len(kmeans))]
score
plt.plot(Nc,score)
plt.xlabel('Number of Clusters')
plt.ylabel('Score')
plt.title('Elbow Curve')
plt.show() #5 Seria un idoneo dentro de la grafica"""


# Grafica con 3 columnas relacionadas entre si	
#sb.pairplot(dataframe.dropna(), hue='categoria',height=4,vars=["op","ex","ag"],kind='scatter')
#plt.show()


#Muestra las graficas para ver la dispersion de los datos
#dataframe.drop(['categoria'],1).hist()
#plt.show()



# Muestra en grupos una columna
#print(dataframe.groupby('categoria').size())

#df = pd.DataFrame()
#print(df)