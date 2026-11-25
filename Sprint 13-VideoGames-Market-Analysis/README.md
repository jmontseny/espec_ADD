# Análisis del mercado de videojuegos: características, reseñas y descuentos

## Descripción del proyecto

Proyecto de análisis de datos end-to-end que estudia el mercado de los
videojuegos mediante la integración de información procedente de tres APIs:

- **IGDB:** características de los videojuegos, géneros, plataformas,
  modos de juego, fechas de lanzamiento y clasificación Indie.
- **Steam:** volumen de reseñas y porcentaje de valoraciones positivas.
- **IsThereAnyDeal (ITAD):** precios, descuentos e históricos de precios
  de videojuegos en distintas tiendas.

El objetivo es investigar cómo se relacionan las características de los
videojuegos con su recepción entre los jugadores y con los descuentos
registrados a lo largo del tiempo.

La investigación combina procesos ETL, limpieza, análisis exploratorio
de datos (EDA), visualización y Machine Learning.

## Preguntas de investigación

1. ¿Cómo se distribuyen los videojuegos por género, plataforma y modo de juego?
2. ¿Cómo ha evolucionado la presencia de videojuegos clasificados como Indie?
3. ¿Qué características se relacionan con el volumen y las valoraciones
   de las reseñas de Steam?
4. ¿Qué relación existe entre la antigüedad de los videojuegos y los
   descuentos máximos observados?
5. ¿Los videojuegos mejor valorados tienden a registrar descuentos menores?

## Fuentes de datos

| Fuente | Información principal |
|---|---|
| IGDB | Metadatos y características de videojuegos |
| Steam | Reseñas y valoraciones |
| ITAD | Precios e históricos de descuentos |

Durante la extracción inicial se obtuvieron 386.706 registros de IGDB.

Tras el proceso de limpieza y selección de juegos principales,
el dataset utilizado en la EDA contiene 236.126 videojuegos.

Los datos de Steam e ITAD se relacionaron con IGDB mediante identificadores
de los videojuegos y correspondencias de Steam AppID.

### Cobertura de los datos procesados

| Dataset | Cobertura |
|---|---:|
| IGDB inicial | 386.706 registros |
| IGDB limpio para EDA | 236.126 videojuegos |
| Resumen de Steam | 27.795 AppIDs |
| Históricos ITAD disponibles | 21.088 AppIDs |
| Históricos Steam en EUR válidos | 18.443 AppIDs |
| Análisis conjunto de valoración y descuento | 4.375 AppIDs |

Las cifras corresponden a distintas etapas y filtros; no representan
el mismo universo de videojuegos.

## Metodología

### 1. Extracción (ETL)

Se consultaron las APIs de IGDB, Steam e ITAD mediante Python.

El proceso incluyó paginación, gestión de límites de las APIs,
tratamiento de errores, reintentos y almacenamiento incremental
de las respuestas.

### 2. Limpieza y preparación

Las principales operaciones incluyeron:

- Selección de videojuegos principales.
- Tratamiento de valores ausentes y fechas de lanzamiento.
- Normalización de géneros, plataformas y modos de juego.
- Identificación de videojuegos con correspondencias de Steam.
- Revisión de AppIDs múltiples, demos y versiones de prueba.
- Preparación de una muestra estratificada para la extracción.
- Transformación de datos JSON a Parquet.
- Comprobaciones de consistencia y cobertura de los datos.

### 3. Análisis exploratorio (EDA)

Se estudiaron las características de los videojuegos y su evolución,
el volumen de reseñas, los porcentajes de valoraciones positivas,
los descuentos históricos y las relaciones entre estas variables.

Para las comparaciones de precios históricos se utilizaron
registros válidos de Steam expresados en euros.

### 4. Machine Learning

Se desarrollaron dos experimentos principales.

**Experimento Steam**

Predicción del número de reseñas mediante características de IGDB.

Se aplicó una transformación `log1p` sobre la variable objetivo,
y se compararon un modelo base, regresión lineal y Random Forest.

**Experimento ITAD**

Predicción del descuento máximo histórico mediante regresión lineal.

Se compararon dos modelos: uno basado en características del videojuego
y cobertura histórica, y otro que incorpora adicionalmente el
porcentaje de reseñas positivas.

Para las evaluaciones se utilizó una separación entrenamiento/test,
agrupando por identificador IGDB para evitar que un mismo videojuego
estuviera presente en ambos conjuntos.

## Principales resultados

### Características del mercado

En los datos de IGDB, Adventure figura entre los géneros más frecuentes
y PC (Microsoft Windows) destaca por su elevada presencia.

El análisis temporal muestra un aumento de la proporción de videojuegos
etiquetados como Indie en el catálogo estudiado.

Estos resultados describen la cobertura de IGDB y no deben
interpretarse directamente como cuotas del mercado global.

### Reseñas de Steam

Las reseñas presentan una distribución muy asimétrica:
una pequeña cantidad de videojuegos concentra un volumen
extraordinariamente elevado de opiniones.

En el análisis de juegos con al menos 100 reseñas, el porcentaje
mediano de valoraciones positivas fue aproximadamente del 82,75 %.

### Antigüedad y descuentos

Se identificó una asociación positiva entre la antigüedad y el
descuento máximo histórico observado (Spearman = 0,4049).

La duración del historial (0,6240) y el número de registros
disponibles (0,6572) presentaron asociaciones todavía más fuertes,
evidenciando la importancia de la cobertura histórica.

### Valoraciones y descuentos

En 4.375 videojuegos con datos válidos, la correlación de Spearman
entre porcentaje de reseñas positivas y descuento máximo fue -0,2965
(p < 0,001).

La mediana del descuento máximo fue:

- Valoraciones mixtas: 80 %.
- Valoraciones mayormente positivas: 70 %.
- Valoraciones muy positivas: 50 %.

Estos resultados muestran una asociación, no una relación causal.

## Resultados de Machine Learning

### Predicción de reseñas (Steam)

| Modelo | R² en escala log | MAE en escala original |
|---|---:|---:|
| Regresión lineal | 0,2051 | 1.141,38 reseñas |
| Random Forest | 0,2538 | 1.125,00 reseñas |

Random Forest obtuvo mejores resultados, aunque la capacidad
predictiva fue limitada.

El R² corresponde a la variable objetivo transformada mediante
`log1p`; el MAE se calculó después de deshacer esa transformación.

### Predicción del descuento máximo (ITAD)

| Modelo | MAE (puntos porcentuales) | R² |
|---|---:|---:|
| Sin valoraciones | 12,3731 | 0,5719 |
| Con valoraciones positivas | 11,6882 | 0,6117 |

Incorporar `positive_pct` mejoró la capacidad predictiva del modelo.

Su coeficiente fue -0,2970: condicionado a las demás variables,
10 puntos porcentuales adicionales de valoración positiva se asociaron
con 2,97 puntos porcentuales menos de descuento máximo estimado.

Las valoraciones positivas fueron la tercera variable más relevante
según la importancia por permutación, por detrás del número de
registros y de la duración del historial.

## Estructura del repositorio

```text
VideoGames-Market-Analysis/
├── igdb_client.ipynb
├── data_cleaning_and_sampling.ipynb
├── json_to_parquet.ipynb
├── EDA_Videogames.ipynb
├── ML_videogames.ipynb
├── igdb_genres_names.csv
├── igdb_platforms_names.csv
├── igdb_game_modes_names.csv
├── igdb_player_perspectives_names.csv
├── eda_data/
│   ├── games_clean.parquet
│   ├── igdb_clean.parquet
│   ├── sample_final.parquet
│   ├── steam_map_clean.parquet
│   ├── steam_reviews_summary.parquet
│   ├── steam_reviews_summary_table.parquet
│   ├── itad_steam_discounts_summary.parquet
│   └── itad_steam_igdb_ratings.parquet
├── reports/
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md

## Tecnologías

Python, pandas, NumPy, DuckDB, scikit-learn...
