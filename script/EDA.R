# =============================================================
# PROYECTO FINAL - ANÁLISIS EXPLORATORIO DE DATOS (EDA)
# Tema: Tipo de cambio e inflación en el Perú (series mensuales)
# Fuente: BCRP - Banco Central de Reserva del Perú (BCRPData)
#         https://estadisticas.bcrp.gob.pe
#
# NOTA: este proyecto de RStudio usa las carpetas data/, script/ y
# collage/. Al subir a GitHub, la consigna pide llamarlas data/,
# scripts/ y figures/ (con collage_graficos.png dentro) — basta con
# renombrar las carpetas script -> scripts y collage -> figures antes
# de subir el repositorio.
# =============================================================

# -------------------------------------------------------------
# 1. CONTEXTO DEL CONJUNTO DE DATOS
# -------------------------------------------------------------
# Institución: Banco Central de Reserva del Perú (BCRP), a través de
#   su plataforma BCRPData (Plataforma Nacional de Datos Abiertos).
# Datasets:
#   - PN01210PM: Tipo de cambio - promedio del periodo (S/ por US$),
#     Bancario - Promedio. Mensual, Ene-1995 a Jun-2026.
#   - PN01271PM: Índice de precios Lima Metropolitana (var% mensual) -
#     IPC (inflación mensual, fuente INEI). Mensual, Feb-1949 a
#     Jun-2026 (se usará solo desde 1995 para que calce con el tipo
#     de cambio).
# Objetivo/temática: analizar la evolución del tipo de cambio y de la
#   inflación mensual en el Perú, y explorar si existe relación entre
#   la depreciación del sol y la inflación.
# Principales variables analizadas:
#   - fecha           : mes-año de cada observación
#   - tipo_cambio      : S/ por US$ (promedio bancario del mes)
#   - inflacion_mensual: variación % mensual del IPC de Lima Metropolitana
#   - variacion_tc     : variación % mensual del tipo de cambio (calculada)

# -------------------------------------------------------------
# 0. LIBRERÍAS
# -------------------------------------------------------------
# Instala automáticamente los paquetes que falten (solo la primera
# vez que corras el script; si ya están instalados, no hace nada)
paquetes <- c("tidyverse", "janitor", "scales", "patchwork")
faltantes <- paquetes[!paquetes %in% installed.packages()[, "Package"]]
if (length(faltantes) > 0) install.packages(faltantes)

library(tidyverse)
library(janitor)
library(scales)
library(patchwork)  # para combinar gráficos en el collage

# -------------------------------------------------------------
# 2. IMPORTACIÓN DE DATOS
# -------------------------------------------------------------
# Ambos CSV de BCRPData tienen 2 líneas de encabezado (código y
# descripción de la serie) antes de los datos, con el periodo en
# formato texto abreviado en español (ej. "Ene95", "Feb95").

tipo_cambio_raw <- read_csv(
  "data/tipo_cambio.csv", 
  skip = 2,
  col_names = c("periodo", "tipo_cambio"),
  locale = locale(encoding = "UTF-8")
)

inflacion_raw <- read_csv(
  "data/inflacion.csv",
  skip = 2,
  col_names = c("periodo", "inflacion_mensual"),
  locale = locale(encoding = "ISO-8859-1")   # el archivo viene en Latin-1
)

glimpse(tipo_cambio_raw)
glimpse(inflacion_raw)

# -------------------------------------------------------------
# 3. LIMPIEZA Y PREPARACIÓN
# -------------------------------------------------------------

# Función para convertir "Ene95", "Feb95", etc. a fecha real
meses_es <- c(Ene = 1, Feb = 2, Mar = 3, Abr = 4, May = 5, Jun = 6,
              Jul = 7, Ago = 8, Sep = 9, Oct = 10, Nov = 11, Dic = 12)

parsear_periodo <- function(periodo) {
  mes_abrev <- str_sub(periodo, 1, 3)
  anio_2d   <- as.integer(str_sub(periodo, 4, 5))
  anio      <- ifelse(anio_2d >= 50, 1900 + anio_2d, 2000 + anio_2d)
  mes       <- meses_es[mes_abrev]
  as.Date(paste(anio, mes, "01", sep = "-"))
}

tipo_cambio <- tipo_cambio_raw %>%
  mutate(fecha = parsear_periodo(periodo)) %>%
  select(fecha, tipo_cambio)

inflacion <- inflacion_raw %>%
  mutate(fecha = parsear_periodo(periodo)) %>%
  select(fecha, inflacion_mensual)

# Unir ambas series por fecha (solo el periodo en que ambas existen:
# desde Ene-1995, que es cuando empieza el tipo de cambio)
datos <- inner_join(tipo_cambio, inflacion, by = "fecha") %>%
  arrange(fecha) %>%
  mutate(
    anio   = year(fecha),
    decada = paste0(floor(anio / 10) * 10, "s"),
    # variación % mensual del tipo de cambio, para que quede en la
    # misma unidad que la inflación (ambas en % mensual)
    variacion_tc = (tipo_cambio - lag(tipo_cambio)) / lag(tipo_cambio) * 100,
    # índices normalizados (Ene-1995 = 100) para comparar tendencias
    tipo_cambio_idx = tipo_cambio / first(tipo_cambio) * 100,
    inflacion_acum_idx = cumprod(1 + replace_na(inflacion_mensual, 0) / 100) * 100
  )

# -------------------------------------------------------------
# 4. ESTADÍSTICAS DESCRIPTIVAS
# -------------------------------------------------------------
summary(datos %>% select(tipo_cambio, inflacion_mensual, variacion_tc))

# Promedio y volatilidad por década
tabla_decadas <- datos %>%
  group_by(decada) %>%
  summarise(
    tipo_cambio_promedio = mean(tipo_cambio, na.rm = TRUE),
    inflacion_promedio   = mean(inflacion_mensual, na.rm = TRUE),
    volatilidad_tc        = sd(variacion_tc, na.rm = TRUE),
    n_meses               = n()
  )

print(tabla_decadas)

# Correlación simple entre variación del tipo de cambio e inflación
cor(datos$variacion_tc, datos$inflacion_mensual, use = "complete.obs")

# -------------------------------------------------------------
# 5. VISUALIZACIÓN DE DATOS (6 gráficos con ggplot2)
# -------------------------------------------------------------
dir.create("figuras", showWarnings = FALSE)

# Gráfico 1: Evolución del tipo de cambio
g1 <- datos %>%
  ggplot(aes(x = fecha, y = tipo_cambio)) +
  geom_line(color = "#2C7FB8", linewidth = 0.8) +
  labs(
    title    = "Evolución del tipo de cambio",
    subtitle = "Promedio bancario mensual (S/ por US$), 1995-2026",
    x        = "Año",
    y        = "S/ por US$"
  ) +
  theme_minimal(base_size = 11)

g1
ggsave("figuras/01_tipo_cambio.png", g1, width = 8, height = 5, dpi = 300)

# Gráfico 2: Evolución de la inflación mensual
g2 <- datos %>%
  ggplot(aes(x = fecha, y = inflacion_mensual)) +
  geom_line(color = "#D95F0E", linewidth = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  labs(
    title    = "Evolución de la inflación mensual",
    subtitle = "Variación % mensual del IPC, Lima Metropolitana, 1995-2026",
    x        = "Año",
    y        = "Inflación mensual (%)"
  ) +
  theme_minimal(base_size = 11)

g2
ggsave("figuras/02_inflacion_mensual.png", g2, width = 8, height = 5, dpi = 300)

# Gráfico 3: Distribución de la inflación mensual
g3 <- datos %>%
  ggplot(aes(x = inflacion_mensual)) +
  geom_histogram(bins = 30, fill = "#31A354", color = "white") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  labs(
    title    = "Distribución de la inflación mensual",
    subtitle = "Frecuencia de las variaciones % mensuales del IPC",
    x        = "Inflación mensual (%)",
    y        = "Número de meses"
  ) +
  theme_minimal(base_size = 11)

g3
ggsave("figuras/03_distribucion_inflacion.png", g3, width = 8, height = 5, dpi = 300)

# Gráfico 4: Volatilidad de la inflación mensual por década (boxplot)
g4 <- datos %>%
  ggplot(aes(x = decada, y = inflacion_mensual, fill = decada)) +
  geom_boxplot(show.legend = FALSE) +
  labs(
    title    = "Volatilidad de la inflación mensual por década",
    subtitle = "Dispersión y valores atípicos de la inflación mensual",
    x        = "Década",
    y        = "Inflación mensual (%)"
  ) +
  theme_minimal(base_size = 11)

g4
ggsave("figuras/04_inflacion_por_decada.png", g4, width = 8, height = 5, dpi = 300)

# Gráfico 5: Tipo de cambio vs. inflación acumulada, ambos indexados
# (Ene-1995 = 100), para comparar tendencias en una sola escala
g5 <- datos %>%
  select(fecha, tipo_cambio_idx, inflacion_acum_idx) %>%
  pivot_longer(-fecha, names_to = "serie", values_to = "indice") %>%
  mutate(serie = recode(serie,
                        tipo_cambio_idx = "Tipo de cambio (índice)",
                        inflacion_acum_idx = "Precios acumulados (índice)")) %>%
  ggplot(aes(x = fecha, y = indice, color = serie)) +
  geom_line(linewidth = 0.7) +
  labs(
    title    = "Tipo de cambio vs. precios acumulados",
    subtitle = "Ambas series indexadas a 100 en Ene-1995",
    x        = "Año",
    y        = "Índice (Ene-1995 = 100)",
    color    = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

g5
ggsave("figuras/05_indices_comparados.png", g5, width = 8, height = 5, dpi = 300)

# Gráfico 6: Volatilidad del tipo de cambio por década
g6 <- tabla_decadas %>%
  ggplot(aes(x = decada, y = volatilidad_tc)) +
  geom_col(fill = "#756BB1") +
  labs(
    title    = "Volatilidad del tipo de cambio por década",
    subtitle = "Desviación estándar de la variación % mensual del tipo de cambio",
    x        = "Década",
    y        = "Desviación estándar (%)"
  ) +
  theme_minimal(base_size = 11)

g6
ggsave("figuras/06_volatilidad_tc_decada.png", g6, width = 8, height = 5, dpi = 300)

# -------------------------------------------------------------
# COLLAGE DE GRÁFICOS (requerido: collage_graficos - parte 1.png)
# -------------------------------------------------------------
collage <- (g1 | g2) / (g3 | g4) / (g5 | g6) +
  plot_annotation(title = "EDA - Tipo de cambio e inflación en el Perú (BCRP, 1995-2026)")
ggsave("figuras/collage_graficos- del gráfico 1-6 (parte 1).png", collage, width = 14, height = 15, dpi = 300)

