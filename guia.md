# Guía de Operación - Balanceo App

Esta aplicación permite realizar el balanceo de rotores utilizando el **Método de Coeficientes de Influencia**, soportando configuraciones de 1 y 2 planos.

---

## Flujo de Trabajo

### 1. Configuración del Rotor
Antes de iniciar, defina las características físicas del equipo:
- **Nombre del Activo:** Identificador único para guardar el historial.
- **Sentido de Giro:** Crucial para la interpretación de ángulos en el gráfico polar.
- **Tipo de Rotor:** 
  - *Continuo:* Para balanceo basado estrictamente en grados.
  - *Discreto:* Si el rotor tiene álabes numerados. Permite configurar la posición del álabe #1 y el sentido de numeración.
- **Sensores:** Ubicación angular de los sensores X e Y.

### 2. Medición Inicial
Mida la vibración del equipo a velocidad nominal sin pesos de prueba. 
- Ingrese Amplitud (μm) y Fase (°) para cada sensor.

### 3. Prueba de Coeficientes
Instale un peso de prueba conocido en la posición indicada por la aplicación.
- **1 Plano:** Requiere una sola corrida con peso de prueba.
- **2 Planos:** Requiere dos corridas (una para cada plano) para calcular la matriz de influencia.

### 4. Resultados y Corrección
La aplicación calculará la masa exacta y el ángulo de colocación.
- **Masa Correctora:** El peso exacto (en gramos) que debe instalarse.
- **Ángulo de Colocación:** La posición angular donde debe fijarse la masa.
- **Sugerencia de Álabe:** Indica el número de álabe más cercano al ángulo calculado.

---

## Interpretación del Diagrama Polar

El diagrama polar es la herramienta visual clave para validar el proceso:

- **Vectores de Vibración:** Los vectores **V1 (Sensor 1/X)** y **V2 (Sensor 2/Y)** se muestran de forma independiente. **No son una resultante**. Cada uno representa la vibración medida en su respectivo plano de apoyo.
- **Sentido de Giro (GIRO):** Una flecha naranja externa indica hacia dónde gira el rotor. Los ángulos en el gráfico se interpretan siguiendo esta convención física.
- **Keyphasor (KP):** La línea negra sólida indica la referencia de fase (0°).
- **Indicadores de Sensores:** 
  - **Círculo (X):** Ubicación física del Sensor 1.
  - **Cuadrado (Y):** Ubicación física del Sensor 2.
- **Leyenda:** Situada en la esquina superior derecha, permite identificar rápidamente cada color de vector sin saturar el gráfico interno.

---

## Post-Balanceo e Iteraciones

### Verificación
Después de instalar las masas correctoras calculadas, realice una nueva corrida.
- Si la vibración residual es aceptable, el proceso ha terminado.
- Si aún es alta, use la opción **Nueva Iteración**. La aplicación usará los coeficientes ya calculados para refinar la masa basándose en la nueva lectura, ahorrando tiempo de corrida.
