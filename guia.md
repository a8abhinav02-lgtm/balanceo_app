# Guía de Operación: Aplicación de Balanceo por Coeficientes

Esta aplicación está diseñada para facilitar el proceso de balanceo de rotores rígidos utilizando el **Método de Coeficientes de Influencia**. Permite realizar balanceos tanto en **un solo plano** (estático) como en **dos planos** (dinámico).

## Conceptos Fundamentales

El método de coeficientes de influencia se basa en la relación lineal entre la masa de desbalance y la vibración medida. La aplicación calcula cuánto cambia la vibración por cada gramo de masa añadido (el coeficiente) para luego determinar la masa exacta necesaria para anular la vibración original.

---

## Flujo de Trabajo

La aplicación sigue un proceso secuencial dividido en cuatro etapas principales:

### 1. Configuración del Rotor
En la pantalla inicial, se definen los parámetros físicos del equipo:
- **Sentido de Giro:** Crucial para la interpretación de los ángulos (Horario o Antihorario).
- **Tipo de Rotor:** 
    - *Continuo:* Para colocar masas en cualquier ángulo.
    - *Discreto:* Si el rotor tiene álabes o posiciones fijas (la app sugerirá en qué número de álabe colocar la masa).
- **Ángulos de Sensores:** Posición angular de los sensores X e Y respecto a la referencia (Keyphasor).
- **Planos de Corrección:** Elegir entre 1 o 2 planos según el tipo de rotor y la severidad del desbalance dinámico.

### 2. Medición Inicial (V0)
Se debe hacer girar el rotor a su velocidad nominal **sin ninguna masa de prueba**.
- Se ingresa la **Amplitud** (generalmente en μm o mils) y la **Fase** (en grados) medida por el analizador de vibraciones.
- Si es balanceo de 2 planos, se requieren las mediciones de ambos sensores simultáneamente.

### 3. Prueba de Coeficientes (Pesos de Prueba)
En esta etapa se determina la respuesta del sistema ante una masa conocida:
- **Plano 1:** Se coloca una masa de prueba (MT1) en un ángulo conocido y se mide la nueva vibración (V1).
- **Plano 2 (solo en 2 planos):** Se retira la masa del Plano 1, se coloca una masa de prueba en el Plano 2 (MT2) y se mide la respuesta (V2).
- *Nota:* La aplicación utiliza estos datos para calcular la matriz de influencia.

### 4. Resultados y Corrección
Una vez procesados los datos, la aplicación muestra:
- **Masa Correctora:** El peso exacto (en gramos) que debe instalarse.
- **Ángulo de Colocación:** La posición angular donde debe fijarse la masa.
- **Diagrama Polar:** Una representación visual de los vectores de vibración y las masas calculadas.
- **Sugerencia de Álabe:** Si el rotor es discreto, indica el número de álabe más cercano al ángulo calculado.

---

## Post-Balanceo e Iteraciones

### Verificación
Después de instalar las masas correctoras calculadas, se debe realizar una nueva corrida de verificación.
- Si la vibración residual es aceptable (menor al límite configurado), el proceso ha terminado.
- Si aún es alta, se puede realizar una **Siguiente Iteración** dentro de la pantalla de resultados. La aplicación usará los coeficientes ya calculados para ajustar la masa basándose en la nueva vibración medida.

### Historial
La aplicación permite guardar los resultados de cada iteración para documentar la evolución del balanceo y generar un reporte final.

---

## Consejos para un Balanceo Exitoso
1. **Consistencia:** Asegúrese de que la velocidad de rotación sea la misma en todas las mediciones.
2. **Referencia de Ángulo:** Mantenga siempre la misma convención para medir los ángulos (a favor o en contra del giro) según lo configurado.
3. **Masa de Prueba:** Use una masa que produzca un cambio significativo en la vibración (al menos un 30% en amplitud o 30° en fase) para obtener coeficientes precisos.
