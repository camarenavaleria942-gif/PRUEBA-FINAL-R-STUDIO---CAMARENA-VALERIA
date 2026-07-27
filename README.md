# PRUEBA-FINAL-R-STUDIO---CAMARENA-VALERIA
Prueba para subir trabajo final de r studio
# Análisis Exploratorio de Datos: Tipo de Cambio e Inflación en el Perú (1995-2026)

**Curso:** Ofimática (R Studio)

**Docente:** Mirko Smith Caja Ventura

**Estudiante:** Valeria Rania Camarena Serpa

**Fecha:** 26 julio de 2026

## Resumen ejecutivo
 
Este trabajo analiza la evolución del tipo de cambio y la inflación mensual en el Perú entre 1995 y 2026, usando series oficiales del BCRP, y explora si existe una relación entre la depreciación del sol y la inflación (traspaso cambiario). Se encuentra una relación positiva pero débil (correlación = 0.108, p = 0.036) y no constante en el tiempo: negativa en los años 90, prácticamente nula en 2000-2010, y algo más visible en la década de 2020, coincidiendo con la mayor volatilidad cambiaria del periodo.
 
---
 
## Índice
 
1. [Objetivos](#1-objetivos)
2. [Datos](#2-datos)
3. [Metodología](#3-metodología)
4. [Marco teórico](#4-marco-teórico)
5. [Hallazgos del análisis exploratorio](#5-hallazgos-del-análisis-exploratorio)
6. [Relación entre el tipo de cambio y la inflación](#6-relación-entre-el-tipo-de-cambio-y-la-inflación)
7. [Conclusiones](#7-conclusiones)
8. [Importancia y contribución del hallazgo](#8-importancia-y-contribución-del-hallazgo)
9. [Recomendaciones y líneas futuras](#9-recomendaciones-y-líneas-futuras)
10. [Referencias](#10-referencias)
11. [Publicación](#11-publicación)
> El código completo de este análisis está en `scripts/EDA.R` (Parte 1) y `scripts/04_analisis_final.R` (Parte 2). Este documento resume el contexto, los hallazgos y las conclusiones; el detalle técnico está en esos archivos.
 
---
 
## 1. Objetivos
 
**Objetivo general**
 
Analizar la evolución del tipo de cambio y de la inflación mensual en el Perú entre 1995 y 2026, explorando si existe una relación entre la depreciación del sol y la inflación.
 
**Objetivos específicos**
 
1. Describir la evolución y distribución del tipo de cambio y de la inflación mensual.
2. Identificar diferencias de volatilidad entre décadas.
3. Determinar si existe una relación estadísticamente significativa entre la variación mensual del tipo de cambio y la inflación mensual, y si esta relación se mantiene constante a lo largo del tiempo.
---
 
## 2. Datos
 
Los datos provienen del **Banco Central de Reserva del Perú (BCRP)**, a través de su plataforma de datos abiertos **BCRPData** ([estadisticas.bcrp.gob.pe](https://estadisticas.bcrp.gob.pe)).
 
| Serie | Código | Descripción | Frecuencia | Periodo |
|---|---|---|---|---|
| Tipo de cambio | `PN01210PM` | Promedio del periodo (S/ por US$), Bancario - Promedio | Mensual | Ene-1995 a Jun-2026 |
| Inflación | `PN01271PM` | Índice de Precios al Consumidor de Lima Metropolitana (var% mensual), IPC general | Mensual | Ene-1995 a Jun-2026* |
| Inflación transables | `PN01280PM` | IPC Transables (var% mensual) — bienes susceptibles de comercio internacional | Mensual | Feb-1992 a May-2026 |
| Inflación no transables | `PN01282PM` | IPC No Transables (var% mensual) — bienes y servicios de precio determinado domésticamente | Mensual | Feb-1992 a May-2026 |
 
*\*Series de inflación disponibles desde antes de 1995; se utilizan desde 1995 para calzar con el tipo de cambio.*
 
**Variables analizadas:** fecha (mes-año), tipo de cambio (S/ por US$), inflación mensual (variación % del IPC), variación % mensual del tipo de cambio (calculada), e inflación mensual de bienes transables y no transables (para probar el mecanismo de traspaso cambiario).
 
> Los archivos originales descargados están en `data/tipo_cambio.csv`, `data/inflacion.csv`, `data/transables.csv` y `data/no_transables.csv`.
 
---
 
## 3. Metodología
 
El análisis se realizó en R (tidyverse, ggplot2). Se importaron y depuraron ambas series, calculando la variación % mensual del tipo de cambio para que ambas variables quedaran en la misma unidad. Se generaron estadísticas descriptivas y visualizaciones (evolución temporal, distribución, comparación por década). Para responder a la pregunta de análisis se calculó el coeficiente de correlación de Pearson, una regresión lineal simple, y el intervalo de confianza al 95% de la correlación en cada década, con el fin de evaluar tanto la magnitud como la solidez estadística de la relación.
 
---
 
## 4. Marco teórico
 
El fenómeno central de este análisis es el **traspaso cambiario** (*exchange rate pass-through*): la magnitud en que una depreciación de la moneda se traslada a los precios internos, debido al encarecimiento de insumos y bienes importados. La literatura económica señala que este traspaso es más fuerte en economías dolarizadas y con bajo compromiso antiinflacionario del banco central, y más débil cuando existe un ancla de expectativas creíble. En el caso peruano, el BCRP adoptó en 2002 un esquema de **Metas Explícitas de Inflación**, que ancla las expectativas de precios independientemente de los movimientos del tipo de cambio este marco es la referencia para interpretar los resultados de este trabajo.
 
---
 
## 5. Hallazgos del análisis exploratorio
 
El tipo de cambio pasó de S/ 2.18 en enero de 1995 a un promedio de S/ 3.20 en todo el periodo (máximo de S/ 4.11), mostrando una tendencia de depreciación sostenida del sol frente al dólar, con una fase de fuerte alza a fines de los 90, una relativa estabilidad y apreciación entre 2010 y 2013, y un nuevo repunte marcado desde 2020. La inflación mensual, en cambio, se comporta de forma mucho más errática mes a mes (rango de -0.54% a 2.38%, promedio de 0.31%), sin una tendencia definida, concentrada mayormente entre 0% y 1%, con algunos meses atípicos por encima de 1.5%.
 
Al comparar ambas variables por década, se observa lo siguiente:
 
**Tabla 1.** Tipo de cambio, inflación y volatilidad cambiaria por década
 
| Década | Tipo de cambio promedio (S/) | Inflación promedio (%) | Volatilidad del tipo de cambio (DE) |
|---|---|---|---|
| 1990s | 2.73 | 0.61 | 1.07 |
| 2000s | 3.30 | 0.20 | 1.19 |
| 2010s | 3.02 | 0.24 | 1.04 |
| 2020s | 3.69 | 0.34 | 1.62 |
 
La inflación promedio fue más alta en los años 90 (0.61%, aún en la etapa final de estabilización post-hiperinflación) y se redujo notablemente a partir de los 2000 tras la adopción del esquema de Metas Explícitas de Inflación del BCRP. La volatilidad del tipo de cambio, en cambio, es claramente más alta en la década de 2020 (desviación estándar de 1.62, frente a 1.0-1.2 en décadas previas), coincidiendo con shocks globales como la pandemia y el alza de tasas de interés internacionales, este es el hallazgo que motiva la pregunta de análisis de la siguiente sección.
 
---
 
## 6. Relación entre el tipo de cambio y la inflación
 
**Pregunta de análisis:** ¿existe relación entre la depreciación mensual del sol y la inflación mensual en el Perú, y esta relación se mantiene constante en el tiempo?
 
Los resultados muestran que sí existe una relación positiva, pero débil y estadísticamente significativa (correlación = 0.108; coeficiente de la regresión = 0.033, p = 0.036), con un poder explicativo muy bajo (R² = 1.2%), lo que indica que el tipo de cambio por sí solo explica muy poco de la variación de la inflación mensual un resultado consistente con la teoría del traspaso cambiario descrita en la sección 4: cuando la política monetaria es confiable, el traspaso tiende a ser bajo. Al desagregar por década, la correlación fue negativa en los 90 (-0.22), un periodo en que la inflación caía por el propio programa de estabilización post-hiperinflación, sin relación directa con el tipo de cambio; prácticamente nula en 2000 y 2010 (0.05 y 0.00), coincidiendo con la etapa de mayor estabilidad de precios bajo el esquema de Metas Explícitas de Inflación; y algo más visible en 2020 (0.14), en el periodo de mayor volatilidad cambiaria, lo que probablemente refleja shocks externos compartidos, como la pandemia o el alza de tasas internacionales, que movieron ambas variables a la vez, más que un traspaso cambiario directo. Sin embargo, al calcular el intervalo de confianza de la correlación en cada década, **ninguno excluye el cero** (las muestras de 60-120 meses por década son chicas): solo la correlación general, con los 377 meses juntos, es estadísticamente distinta de cero.
 
Esta lectura agregada se confirma, y se explica mejor, al desagregar por tipo de bien: la correlación entre la variación del tipo de cambio y la inflación es más del doble en **bienes transables** (0.175, p = 0.0006, estadísticamente significativa) que en **no transables** (0.062, p = 0.233, no significativa). Esto es exactamente lo que predice la teoría del traspaso cambiario: los bienes transables cuyo precio depende de precios internacionales convertidos a soles, sí trasladan la depreciación a sus precios de forma medible, mientras que los no transables determinados por condiciones domésticas de oferta y demanda, prácticamente no reaccionan al tipo de cambio.
 
---
 
## 7. Conclusiones
 
El periodo analizado confirma una depreciación sostenida del sol frente al dólar, acompañada de una inflación mensual comparativamente más alta y volátil en los años posteriores a la hiperinflación, que se estabiliza de forma notoria tras la adopción del esquema de Metas Explícitas de Inflación del BCRP (Parte 1). Sobre esa base, la Parte 2 muestra que la relación entre la depreciación del sol y la inflación mensual es positiva pero débil, y no se mantiene constante a lo largo del tiempo: fue negativa durante el proceso de estabilización de los años 90, se volvió prácticamente nula durante la etapa de mayor credibilidad monetaria de los 2000 y 2010, y solo se hace algo más perceptible en el periodo reciente de mayor volatilidad cambiaria.
 
La evidencia más concluyente, sin embargo, proviene de desagregar la inflación por tipo de bien: el traspaso cambiario resulta considerablemente mayor en los bienes transables que en los no transables, tal como anticipa la teoría económica, los precios ligados a mercados internacionales responden al tipo de cambio en mayor medida que aquellos determinados por condiciones domésticas. Esta distinción aísla el mecanismo económico subyacente y ofrece una evidencia más sólida que la correlación agregada o su variación por década.
 
En conjunto, los resultados sugieren que el Perú exhibe un traspaso cambiario bajo, consistente con la credibilidad de su régimen monetario: una depreciación puntual del sol no debería traducirse en expectativas de inflación generalizada, aunque sí incide de forma medible sobre los precios de bienes vinculados al comercio internacional.
 
**Limitaciones:** la correlación no implica causalidad, y el bajo poder explicativo del modelo indica que otros factores: precios internacionales, expectativas y política fiscal, entre otros también contribuyen a explicar la dinámica de la inflación.
 
---
 
## 8. Importancia y contribución del hallazgo
 
Este hallazgo aporta evidencia empírica concreta sobre el grado de traspaso cambiario en el Perú, un indicador clave para evaluar la credibilidad de la política monetaria del BCRP: un traspaso bajo confirma que el esquema de Metas Explícitas de Inflación ha logrado anclar las expectativas de precios, incluso en periodos de mayor volatilidad cambiaria como la década de 2020. Esto es relevante para al menos tres públicos:
 
- **BCRP y hacedores de política:** evidencia de que su marco de credibilidad sigue funcionando pese a shocks recientes.
- **Empresas e inversionistas:** una depreciación puntual del sol no debería anticiparse como detonante automático de alta inflación, reduciendo la necesidad de cobertura excesiva ante movimientos cambiarios.
- **Literatura económica local:** actualiza con datos hasta 2026 un patrón que en trabajos previos se documentaba solo hasta la década de 2010, incorporando evidencia del periodo pos-pandemia.
---
 
## 9. Recomendaciones y líneas futuras
 
1. Ampliar el análisis a un modelo multivariado que incluya precios internacionales de alimentos y combustibles, para aislar mejor el efecto propio del tipo de cambio sobre la inflación.
2. Explorar el traspaso cambiario con rezagos (ej. el efecto de la depreciación de un mes sobre la inflación de los meses siguientes), ya que el traspaso económico no siempre es instantáneo.
3. Extender la muestra por década con datos de mayor frecuencia (semanal) para robustecer los intervalos de confianza en los subperiodos.
---
 
## 10. Referencias
 
- Banco Central de Reserva del Perú (BCRP). *BCRPData - Estadísticas Económicas*. https://estadisticas.bcrp.gob.pe
- Series utilizadas: Tipo de cambio bancario promedio (`PN01210PM`), Índice de Precios al Consumidor de Lima Metropolitana - variación % mensual (`PN01271PM`).
---
 
## 11. Publicación
 
Captura de la publicación en LinkedIn/X con el hallazgo principal: *(https://www.linkedin.com/posts/valeria-camarena-aa1850243_rstats-datascience-economaeda-share-7486977306012467200-n_vx/?utm_source=share&utm_medium=member_desktop&rcm=ACoAADx1qxkBfTaGo8_A4Uo9IpKRSZvm0qz713w)*
