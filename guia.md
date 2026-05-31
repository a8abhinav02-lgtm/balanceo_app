# Guía de Operación - Balanceo App

Esta aplicación permite realizar el balanceo de rotores utilizando el **Método de Coeficientes de Influencia**, soportando configuraciones de 1 y 2 planos con un alto grado de precisión técnica.

---

## Flujo de Trabajo

### 1. Configuración del Rotor
Defina las características físicas antes de medir:
- **Nombre del Activo:** Identificador para persistencia en el historial.
- **Sentido de Giro:** Vital para la visualización. La app asume la convención de **Contra-Rotación** para los ángulos de fase.
- **Tipo de Rotor:** 
  - *Continuo:* Balanceo basado en grados (0° a 360°).
  - *Discreto:* Para rotores con álabes. Permite configurar el ángulo del Álabe #1 y si la numeración es Horaria o Antihoraria.
- **Sensores:** Ubicación angular física de los canales de medición (con tags dinámicos).

### 2. Medición Inicial (Diagnóstico)
Mida la vibración base a velocidad nominal. Se capturan datos de ambos canales para tener un panorama completo del desbalance inicial.

### 3. Prueba de Coeficientes
Instale un peso de prueba (`M1`) y mida la nueva vibración resultante (`V1` y `V2`).
- **Dualidad:** Incluso en modo de 1 plano, la app solicita mediciones de ambos canales para monitorear el acoplamiento entre planos.

### 4. Resultados y Evolución Vectorial
La app calcula la **Masa Correctora** exacta. Los resultados se presentan en un carrusel comparativo:
- **Estado Inicial:** Solo la vibración diagnóstica pura.
- **Efecto de Prueba:** Muestra la vibración base, la masa de prueba y la vibración resultante tras colocar el peso.
- **Masas Correctoras:** Muestra la solución final recomendada sobre el estado inicial.

---

## Convenciones y Diagrama Polar

### Regla de Ángulos (Contra-Giro)
Siguiendo los estándares industriales (ISO/Bently Nevada), los ángulos se grafican en **sentido opuesto al giro del rotor**.
- Si el rotor gira **Horario**, los grados se cuentan **Antihorario**.
- **¿Por qué?** La fase representa un retraso (*lag*). El punto pesado se encuentra físicamente "atrás" de la marca de referencia respecto al giro de la máquina.

### Elementos Gráficos (Simbología)
El diagrama polar utiliza símbolos exactos para garantizar una interpretación visual directa de los datos en campo:

- **Flecha `GIRO` (Naranja):** Indica el sentido de rotación físico configurado por el usuario.
- **Línea `KP` (Negra):** El Keyphasor. Es la marca óptica de referencia (fase = 0°).
- **Indicadores de Sensores:** 
  - **Círculo:** Ubicación angular física del Canal 1 (ej: `1H`).
  - **Cuadrado:** Ubicación angular física del Canal 2 (ej: `2H`).
- **Vectores de Vibración:** 
  - **`V1` (Azul Eléctrico / Cian):** Canal 1 (Azul Eléctrico para la vibración inicial/residual; Cian brillante con peso de prueba).
  - **`V2` (Rojo Rubí / Magenta):** Canal 2 (Rojo Rubí para la vibración inicial/residual; Magenta/Rosado Neón con peso de prueba).

- **Vectores de Masas:** 
  - **`M1` / `M2` (Gris/Verde):** Representan el peso de prueba o la masa correctora recomendada.
- **Álabes (Círculos Azules):** Muestran la distribución de los álabes (ej. 1, 2, 3...) según el tipo de rotor configurado.

---

## Refinamiento (Iteraciones)
Si tras instalar la masa correctora la vibración residual no es satisfactoria:
1. Use **Nueva Iteración**.
2. Ingrese la nueva vibración medida.
3. La app recalculará una corrección adicional usando los coeficientes de influencia ya obtenidos, optimizando el tiempo de campo sin requerir nuevos pesos de prueba.

---

## Balanceo de Rotores en Voladizo (Overhung) - Método Estático-Acople

Para rotores en voladizo (geometrías con alto acoplamiento dinámico donde el ventilador o impulsor está fuera del vano de los apoyos), el método convencional de 2 planos por matriz de influencia puede ser inestable. En su lugar, la app cuenta con un asistente especializado basado en el método modal de **Descomposición Estático-Acople**.

### Flujo de Operación Paso a Paso:

1. **Configuración Inicial:**
   * En la pantalla de **Configuración**, seleccione **2 planos** y active el interruptor **"Rotor en voladizo (Overhung)"**.
2. **Medición Inicial (V0):**
   * Realice una corrida del rotor sin pesos añadidos y registre los niveles de vibración diagnósticos iniciales.
3. **Fase 1: Corrida de Prueba Estática:**
   * **Instalación:** Coloque dos masas de prueba **idénticas** (ej: 10 gramos) en la **misma posición angular** (ej: a 0°) tanto en el Plano 1 como en el Plano 2.
   * **Registro:** Ingrese el peso y ángulo de una de las masas, y registre las vibraciones resultantes en ambos sensores.
   * **Propósito:** Esta prueba aísla el comportamiento estático (traslación) del rotor.
4. **Fase 2: Corrida de Prueba de Acople:**
   * **Instalación:** Retire los pesos anteriores. Coloque dos masas de prueba **idénticas** pero **desfasadas 180°** (ej: 10 gramos a 0° en Plano 1 y 10 gramos a 180° en Plano 2).
   * **Registro:** Ingrese el peso y ángulo de la masa del Plano 1, y registre las vibraciones resultantes en ambos sensores.
   * **Propósito:** Esta prueba aísla el comportamiento de acople (momento/rotación angular) del rotor.
5. **Cálculo y Corrección Final:**
   * Presione **Calcular**. La aplicación calculará los coeficientes de influencia modales Hs y Hc, y generará las masas de corrección definitivas para el Plano 1 y Plano 2 resolviendo vectorialmente el desbalance estático y el de acople por separado.

---

## Concepto de Coeficientes de Influencia (Lag y Lead)

El coeficiente de influencia (H) es una constante física del sistema que mide cómo responde el rotor a la adición de una masa de prueba. En el reporte final, este coeficiente se acompaña de una clasificación de desfase:

- (Lag - Retraso de Fase): Ocurre cuando el ángulo de desfase del coeficiente está entre 0° y 180°. Es el comportamiento estándar en la mayoría de los rotores industriales; la respuesta física del rotor tiene un retraso o inercia respecto a la ubicación del peso.
- (Lead - Adelanto de Fase): Se indica cuando el ángulo está entre 180° y 360°. Esto representa un adelanto de fase de la señal de respuesta, típico bajo condiciones dinámicas de resonancia o acoplamientos específicos del sensor.

---

## Control de Calidad de Balanceo (Norma ISO 1940-1)

La aplicación incluye un módulo opcional para certificar técnicamente el estado del balanceo bajo la norma internacional **ISO 1940-1**:

1. **Activación:** Puede habilitar el switch "Control de Calidad ISO 1940" directamente en la pantalla de resultados finales.
2. **Configuración de Parámetros:** Ingrese el grado de calidad (G) correspondiente al tipo de maquinaria (e.g. G2.5 para ventiladores industriales), el peso del rotor (kg), la velocidad nominal (RPM) y el radio de corrección (mm). Estos parámetros pueden modificarse dinámicamente en caliente sin perder los cálculos actuales del balanceo.
3. **Cálculos y Veredicto:**
   * **Desbalance Admisible ($U_{per, plane}$):** Representa el límite de tolerancia superior por plano (en g-mm) según la norma:
     $$U_{per, plane} = \frac{9549.3 \times G \times W}{N \times P}$$
   * **Desbalance Residual Real ($U_{residual, j}$):** Se calcula a partir de la sensibilidad física ($S_j$) obtenida de la corrida de peso de prueba y el nivel final de vibración medida:
     $$U_{residual, j} = S_j \times V_{final, j}$$
   * **Conformidad:** El sistema otorga un distintivo verde **"CUMPLE CON ISO"** si el desbalance residual real de todos los planos es inferior o igual a la tolerancia admisible. De lo contrario, se muestra en rojo **"NO CUMPLE"**
