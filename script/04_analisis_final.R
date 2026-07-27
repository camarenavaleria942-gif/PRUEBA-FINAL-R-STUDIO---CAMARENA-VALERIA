# =============================================================
# ANÁLISIS FINAL (PARTE 2)
# A partir de los hallazgos del EDA (scripts/EDA.R), se profundiza
# en una pregunta de análisis específica.
# =============================================================

# Instala automáticamente los paquetes que falten (solo la primera
# vez que corras el script; si ya están instalados, no hace nada)
paquetes <- c("tidyverse", "janitor", "scales")
faltantes <- paquetes[!paquetes %in% installed.packages()[, "Package"]]
if (length(faltantes) > 0) install.packages(faltantes)

library(tidyverse)
library(janitor)
library(scales)

# -------------------------------------------------------------
# 1. PREGUNTA DE ANÁLISIS
# -------------------------------------------------------------
# "¿Existe relación entre la depreciación mensual del sol (variación %
#  del tipo de cambio) y la inflación mensual en el Perú, entre 1995
#  y 2026?"
#
# Hallazgo que motiva la pregunta: en el EDA (Parte 1) se observó que
# tanto el tipo de cambio como la inflación mensual muestran periodos
# de alta volatilidad (ver figures/01_tipo_cambio.png y
# figures/02_inflacion_mensual.png), lo que sugiere explorar si ambas
# series se mueven juntas.

# -------------------------------------------------------------
# 0. CARGA Y PREPARACIÓN (reutiliza la limpieza de EDA.R)
# -------------------------------------------------------------
meses_es <- c(Ene = 1, Feb = 2, Mar = 3, Abr = 4, May = 5, Jun = 6,
              Jul = 7, Ago = 8, Sep = 9, Oct = 10, Nov = 11, Dic = 12)

parsear_periodo <- function(periodo) {
  mes_abrev <- str_sub(periodo, 1, 3)
  anio_2d   <- as.integer(str_sub(periodo, 4, 5))
  anio      <- ifelse(anio_2d >= 50, 1900 + anio_2d, 2000 + anio_2d)
  mes       <- meses_es[mes_abrev]
  as.Date(paste(anio, mes, "01", sep = "-"))
}

tipo_cambio <- read_csv("data/tipo_cambio.csv", skip = 2,
                        col_names = c("periodo", "tipo_cambio"),
                        locale = locale(encoding = "UTF-8")) %>%
  mutate(fecha = parsear_periodo(periodo)) %>%
  select(fecha, tipo_cambio)

inflacion <- read_csv("data/inflacion.csv", skip = 2,
                      col_names = c("periodo", "inflacion_mensual"),
                      locale = locale(encoding = "ISO-8859-1")) %>%
  mutate(fecha = parsear_periodo(periodo)) %>%
  select(fecha, inflacion_mensual)

datos <- inner_join(tipo_cambio, inflacion, by = "fecha") %>%
  arrange(fecha) %>%
  mutate(
    anio = year(fecha),
    variacion_tc = (tipo_cambio - lag(tipo_cambio)) / lag(tipo_cambio) * 100
  ) %>%
  filter(!is.na(variacion_tc))

# -------------------------------------------------------------
# 2. ANÁLISIS DE LA RELACIÓN ENTRE VARIABLES
# -------------------------------------------------------------

# --- 2.1 Correlación entre variación del tipo de cambio e inflación ---
correlacion <- cor(datos$variacion_tc, datos$inflacion_mensual, use = "complete.obs")
print(correlacion)

# --- 2.2 Regresión lineal simple: inflación ~ variación del tipo de cambio ---
modelo <- lm(inflacion_mensual ~ variacion_tc, data = datos)
summary(modelo)

# --- 2.3 Tabla resumen por décadas (¿la relación es más fuerte en
#     periodos de alta volatilidad cambiaria, ej. 1998, 2008, 2020?) ---
tabla_decadas <- datos %>%
  mutate(decada = paste0(floor(anio / 10) * 10, "s")) %>%
  group_by(decada) %>%
  summarise(
    correlacion_periodo = cor(variacion_tc, inflacion_mensual, use = "complete.obs"),
    volatilidad_tc       = sd(variacion_tc, na.rm = TRUE),
    inflacion_promedio   = mean(inflacion_mensual, na.rm = TRUE),
    n_meses              = n()
  )

print(tabla_decadas)

# --- 2.4 Intervalo de confianza de la correlación en cada década ---
# (para saber si la relación es estadísticamente distinta de cero
# en cada periodo, no solo ver el punto estimado)
intervalos_decada <- datos %>%
  mutate(decada = paste0(floor(anio / 10) * 10, "s")) %>%
  group_by(decada) %>%
  summarise(
    ic_inferior = cor.test(variacion_tc, inflacion_mensual)$conf.int[1],
    ic_superior = cor.test(variacion_tc, inflacion_mensual)$conf.int[2]
  )

tabla_decadas <- tabla_decadas %>% left_join(intervalos_decada, by = "decada")
print(tabla_decadas)

# -------------------------------------------------------------
# 3. VISUALIZACIÓN ADICIONAL DEL HALLAZGO
# -------------------------------------------------------------
dir.create("figuras", showWarnings = FALSE)

# Gráfico 7: correlación resumen por década (magnitud de la relación
# en cada periodo). Responde "cuánto".
g_decadas <- tabla_decadas %>%
  ggplot(aes(x = decada, y = correlacion_periodo, fill = correlacion_periodo > 0)) +
  geom_col(show.legend = FALSE, width = 0.6) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_text(aes(label = round(correlacion_periodo, 2),
                vjust = ifelse(correlacion_periodo >= 0, -0.6, 1.4)),
            size = 5, fontface = "bold") +
  scale_fill_manual(values = c("TRUE" = "#2C7FB8", "FALSE" = "#D95F0E")) +
  scale_y_continuous(expand = expansion(mult = c(0.15, 0.15))) +
  labs(
    title    = "Evolución de la relación entre tipo de cambio e inflación, por década",
    subtitle = "Coeficiente de correlación estimado en cada década, Perú 1995-2026",
    x        = NULL,
    y        = "Correlación",
    caption  = "Fuente: BCRP - BCRPData"
  ) +
  theme_minimal(base_size = 16) +
  theme(
    plot.title    = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(color = "grey30", size = 12),
    axis.text     = element_text(size = 13),
    panel.grid.minor = element_blank()
  )

g_decadas
ggsave("figuras/07_correlacion_por_decada.png", g_decadas, width = 8, height = 6, dpi = 300)

# Gráfico 8: datos crudos detrás del gráfico 7, mes a mes por década,
# para verificar visualmente que la correlación no está distorsionada
# por outliers. Responde "cómo se ve" esa relación.
g_facetado <- datos %>%
  mutate(decada = paste0(floor(anio / 10) * 10, "s")) %>%
  ggplot(aes(x = variacion_tc, y = inflacion_mensual)) +
  geom_point(alpha = 0.5, color = "#2C7FB8") +
  geom_smooth(method = "lm", color = "#D95F0E", se = FALSE) +
  facet_wrap(~ decada) +
  labs(
    title    = "Relación entre depreciación del sol e inflación mensual, por década",
    subtitle = "Perú, 1995-2026",
    x        = "Variación % mensual del tipo de cambio",
    y        = "Inflación mensual (%)",
    caption  = "Fuente: BCRP - BCRPData"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(color = "grey30", size = 11),
    strip.text    = element_text(face = "bold", size = 11),
    panel.grid.minor = element_blank()
  )

g_facetado
ggsave("figuras/08_relacion_facetada_decada.png", g_facetado, width = 9, height = 7, dpi = 300)

# -------------------------------------------------------------
# 3.5 TRASPASO CAMBIARIO POR TIPO DE BIEN: TRANSABLES VS. NO TRANSABLES
# -------------------------------------------------------------
# La teoría del traspaso cambiario predice que los bienes TRANSABLES
# (susceptibles de comercio internacional: sus precios dependen de
# precios internacionales convertidos a soles) deberían mostrar un
# traspaso más fuerte que los NO TRANSABLES (servicios y bienes cuyo
# precio depende de condiciones domésticas). Esta sección pone a
# prueba esa predicción directamente.

transables <- read_csv("data/transables.csv", skip = 2,
                       col_names = c("periodo", "transables"),
                       locale = locale(encoding = "ISO-8859-1")) %>%
  mutate(fecha = parsear_periodo(periodo)) %>%
  select(fecha, transables)

no_transables <- read_csv("data/no_transables.csv", skip = 2,
                          col_names = c("periodo", "no_transables"),
                          locale = locale(encoding = "ISO-8859-1")) %>%
  mutate(fecha = parsear_periodo(periodo)) %>%
  select(fecha, no_transables)

datos_sectorial <- datos %>%
  inner_join(transables, by = "fecha") %>%
  inner_join(no_transables, by = "fecha")

# --- Correlación de la variación del tipo de cambio con cada tipo de bien ---
cor_transables    <- cor(datos_sectorial$variacion_tc, datos_sectorial$transables, use = "complete.obs")
cor_no_transables <- cor(datos_sectorial$variacion_tc, datos_sectorial$no_transables, use = "complete.obs")

print(cor_transables)
print(cor_no_transables)

# --- Prueba de significancia para cada correlación ---
test_transables    <- cor.test(datos_sectorial$variacion_tc, datos_sectorial$transables)
test_no_transables <- cor.test(datos_sectorial$variacion_tc, datos_sectorial$no_transables)
print(test_transables)
print(test_no_transables)

# --- Gráfico 9: correlación con el tipo de cambio, transables vs. no transables ---
g_sectorial <- tibble(
  tipo_bien   = c("Transables", "No transables"),
  correlacion = c(cor_transables, cor_no_transables)
) %>%
  ggplot(aes(x = tipo_bien, y = correlacion, fill = tipo_bien)) +
  geom_col(show.legend = FALSE, width = 0.5) +
  geom_text(aes(label = round(correlacion, 3)), vjust = -0.6, fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Transables" = "#2C7FB8", "No transables" = "#D95F0E")) +
  scale_y_continuous(expand = expansion(mult = c(0.1, 0.2))) +
  labs(
    title    = "Traspaso cambiario según tipo de bien",
    subtitle = "Correlación entre la variación del tipo de cambio y la inflación mensual, Perú 1995-2026",
    x        = NULL,
    y        = "Correlación",
    caption  = "Fuente: BCRP - BCRPData"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title    = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(color = "grey30", size = 11),
    panel.grid.minor = element_blank()
  )

g_sectorial
ggsave("figuras/09_traspaso_transables_no_transables.png", g_sectorial, width = 7, height = 6, dpi = 300)

# -------------------------------------------------------------
# 4. CONCLUSIONES
# -------------------------------------------------------------
# Existe una relación positiva entre la depreciación del sol y la
# inflación mensual, pero débil (correlación = 0.108, p = 0.036,
# R² = 1.2%) y no constante en el tiempo: negativa en los 90 (-0.22,
# por el propio fin de la hiperinflación), nula en 2000-2010 (0.05 y
# 0.00, tras la adopción de Metas Explícitas de Inflación), y algo más
# visible en 2020s (0.14), coincidiendo con la mayor volatilidad
# cambiaria del periodo (gráficos 7 y 8).
#
# El hallazgo más sólido es otro: al desagregar por tipo de bien
# (sección 3.5, gráfico 9), la correlación es casi el triple en
# transables (0.175, p = 0.0006) que en no transables (0.062,
# p = 0.233, no significativa) — justo lo que predice la teoría del
# traspaso cambiario, y evidencia más robusta que la correlación
# general o por década, porque aísla el mecanismo económico correcto.
#
# En conjunto, el Perú muestra un traspaso cambiario bajo, atribuible
# a la credibilidad del BCRP: una depreciación puntual no debería
# generar expectativas de inflación generalizada, aunque sí se
# traslada de forma medible a bienes importados o que compiten con
# importados.
#
# Limitaciones: correlación no implica causalidad; el bajo R² indica
# que otras variables (precios internacionales, expectativas, política
# fiscal) también explican la inflación.
