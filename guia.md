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
- **Sensores:** Ubicación angular física de los sensores X e Y.

### 2. Medición Inicial (Diagnóstico)
Mida la vibración base a velocidad nominal. Se capturan datos de ambos sensores (X/Y) para tener un panorama completo del desbalance inicial.

### 3. Prueba de Coeficientes
Instale un peso de prueba (`M1`) y mida la nueva vibración resultante (`V1` y `V2`).
- **Dualidad:** Incluso en modo de 1 plano, la app solicita ambos sensores para monitorear el acoplamiento entre planos.

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
  - **Círculo `(X)`:** Ubicación angular física del Sensor 1.
  - **Cuadrado `[Y]`:** Ubicación angular física del Sensor 2.
- **Vectores de Vibración:** 
  - **`V1` (Celeste):** Vibración medida en el plano del Sensor 1.
  - **`V2` (Rojo):** Vibración medida en el plano del Sensor 2.
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

## Concepto de Coeficientes de Influencia (Lag y Lead)

El coeficiente de influencia (H) es una constante física del sistema que mide cómo responde el rotor a la adición de una masa de prueba. En el reporte final, este coeficiente se acompaña de una clasificación de desfase:

- **(Lag - Retraso de Fase):** Ocurre cuando el ángulo de desfase del coeficiente está entre 0° y 180°. Es el comportamiento estándar en la mayoría de los rotores industriales; la respuesta física del rotor tiene un retraso o inercia respecto a la ubicación del peso.
- **(Lead - Adelanto de Fase):** Se indica cuando el ángulo está entre 180° y 360°. Esto representa un adelanto de fase de la señal de respuesta, típico bajo condiciones dinámicas de resonancia o acoplamientos específicos del sensor.


