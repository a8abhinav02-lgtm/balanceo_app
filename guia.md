# Guía de Operación - Balanceo App

Esta aplicación permite realizar el balanceo de rotores utilizando el **Método de Coeficientes de Influencia**, soportando configuraciones de 1 y 2 planos con un alto grado de precisión técnica.

---

## Flujo de Trabajo

### 1. Configuración del Rotor
Defina las características físicas antes de medir:
- **Nombre del Activo:** Identificador para persistencia en el historial.
- **Sentido de Giro:** Vital para la visualización. La app asume la convención de **Contra-Rotación** para los ángulos de fase.
- **Tipo de Rotor:** 
  - *Continuo:* Balanceo basado en grados ($0^\circ$ a $360^\circ$).
  - *Discreto:* Para rotores con álabes. Permite configurar el ángulo del Álabe #1 y si la numeración es Horaria o Antihoraria.
- **Sensores:** Ubicación angular física de los sensores X e Y.

### 2. Medición Inicial (Diagnóstico)
Mida la vibración base a velocidad nominal. Se capturan datos de ambos sensores (X/Y) para tener un panorama completo del desbalance inicial.

### 3. Prueba de Coeficientes
Instale un peso de prueba ($M_t$) y mida la nueva vibración resultante ($V_1$).
- **Dualidad:** Incluso en modo de 1 plano, la app solicita ambos sensores para monitorear el acoplamiento entre planos.

### 4. Resultados y Evolución Vectorial
La app calcula la **Masa Correctora ($M_c$)** exacta. Los resultados se presentan en un carrusel comparativo:
- **Estado Inicial:** Solo la vibración diagnóstica ($V_0$).
- **Efecto de Prueba:** Muestra $V_0$, la masa de prueba y el vector resultante $V_1$.
- **Masa Correctora:** Muestra la solución final recomendada ($M_c$) sobre el estado inicial.

---

## Convenciones y Diagrama Polar

### Regla de Ángulos (Contra-Giro)
Siguiendo los estándares industriales (ISO/Bently Nevada), los ángulos se grafican en **sentido opuesto al giro del rotor**.
- Si el rotor gira **Horario**, los grados se cuentan **Antihorario**.
- **¿Por qué?** La fase es un retraso (*lag*). El punto pesado se encuentra "atrás" de la marca de referencia respecto al giro.

### Elementos del Gráfico
- **Flecha de GIRO:** Indica el sentido de rotación configurado.
- **Keyphasor (KP):** Referencia de fase ($0^\circ$).
- **Vectores de Vibración:** $V1$ (Sensor X), $V2$ (Sensor Y).
- **Masas:** $M_t$ (Prueba), $M_c$ (Correctora).
- **Sugerencia de Álabe:** Cálculo exacto basado en la distancia angular más corta a la posición física de los álabes configurados.

---

## Refinamiento (Iteraciones)
Si tras instalar la masa correctora la vibración residual no es satisfactoria:
1. Use **Nueva Iteración**.
2. Ingrese la nueva vibración medida.
3. La app recalculará una corrección adicional usando los coeficientes de influencia ya obtenidos, optimizando el tiempo de campo.
