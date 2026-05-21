Evaluación Técnica: Modelo Matemático de Balanceo
Esta evaluación analiza la integridad de los cálculos implementados en BalanceoProvider.dart y Complejo.dart, comparándolos con los estándares de la industria (ISO 21940).

1. Validación del Método Matemático
La aplicación implementa el Método de Coeficientes de Influencia, que es el estándar de facto para el balanceo dinámico de rotores rígidos en campo.

Balanceo en 1 Plano
Fórmula de Coeficiente ($\vec{\alpha}$): $\vec{\alpha} = \frac{\vec{V}_1 - \vec{V}_0}{\vec{M}_t}$
Fórmula de Masa Correctora ($\vec{M}_c$): $\vec{M}_c = \frac{-\vec{V}_0}{\vec{\alpha}}$
Estado: Correcto. La implementación en las líneas 149-150 y 184 del código sigue estrictamente esta relación vectorial.
Balanceo en 2 Planos
Modelo: Sistema de ecuaciones lineales $[\vec{V}] = [\vec{V}_0] + [\mathbf{C}][\vec{M}]$.
Resolución: Se utiliza la inversión de una matriz compleja de $2 \times 2$.
Fórmulas de Inversión: Implementa correctamente el método de la matriz adjunta y el determinante ($det = ad - bc$).
Estado: Correcto. El cálculo de la corrección mediante $[\vec{M}] = -[\mathbf{C}]^{-1} [\vec{V}_0]$ es técnicamente sólido y estándar.
2. Consistencia de Variables y Unidades
Variable	Unidad Estándar	Implementación en App	Validación
Vibración ($\vec{V}$)	$\mu m$ (p-p) o $mm/s$ (rms)	Complejo (Mag, Fase)	Válido (Agnóstico a unidad)
Masa ($\vec{M}$)	Gramos ($g$)	Complejo (Mag, Fase)	Válido
Ángulos ($\theta$)	Grados ($^\circ$)	Grados ($0$-$360^\circ$)	Válido
Fase	Lag (Retraso)	Convención Contra-Rotación	Válido (Estándar Bently Nevada/CSI)
3. Observaciones Críticas y Limitaciones
IMPORTANT

Suposición de Linealidad El modelo asume un sistema lineal. En rotores que operan cerca de velocidades críticas o con soportes no lineales, los coeficientes de influencia pueden variar. La función de "Nueva Iteración" implementada es la respuesta técnica correcta para mitigar esto mediante refinamiento sucesivo.

WARNING

Convención de Ángulos La lógica de ajustarAngulo y sugerirAlabe depende totalmente de que el usuario ingrese la fase como un ángulo de retraso (lag). Si el analizador de vibraciones del usuario entrega phase lead, los resultados estarían invertidos. Se recomienda asegurar que la ayuda en pantalla enfatice el uso de "Ángulo de Retraso".

4. Análisis de la Lógica de Álabes (Rotor Discreto)
La función sugerirAlabe (líneas 245-273) es una de las fortalezas técnicas de la implementación actual:

No se limita a una división entera.
Utiliza Distancia Angular Mínima en el círculo trigonométrico.
Considera el desfase del Álabe #1 y el sentido de numeración.
Resultado: Proporciona la ubicación física más precisa posible para el operador de campo.
5. Conclusión Técnica
El modelo es VÁLIDO y cumple con los requisitos para balanceo de precisión en maquinaria rotativa industrial. El uso de aritmética de números complejos para todas las operaciones asegura que no haya errores de redondeo por descomposición escalar innecesaria.

Recomendación de mejora:

Implementar una validación de "Masa de Prueba Sugerida" para evitar que el usuario coloque una masa tan pequeña que no logre un cambio significativo en el vector de vibración (regla del 30% de cambio en amplitud o 30° en fase).

---

## 6. Ampliación a 4 Posiciones de Medición (Sistemas Sobredeterminados)

Cuando se pasa de medir en **un solo soporte** (con sensor horizontal y vertical, sumando 2 canales en total) a medir en **dos soportes** (ambos con sensores horizontal y vertical, sumando 4 canales en total) manteniendo **2 planos de corrección**, el modelo matemático experimenta un cambio fundamental de categoría.

### 6.1. De un Sistema Determinado a uno Sobredeterminado
En la configuración estándar de 2 planos y 2 sensores, el sistema de ecuaciones es **determinado**:
* **Incógnitas**: 2 masas de corrección complejas ($\vec{M}_1, \vec{M}_2$, que equivalen a 4 incógnitas reales: magnitud y fase para cada plano).
* **Ecuaciones**: 2 lecturas de vibración complejas ($\vec{V}_{0,1}, \vec{V}_{0,2}$, equivalentes a 4 ecuaciones reales).
* **Solución**: Existe una solución única exacta $[\vec{M}] = -[\mathbf{C}]^{-1} [\vec{V}_0]$ que, en teoría, reduce la vibración en ambos sensores a exactamente cero.

Al introducir 4 sensores ($S_{1H}, S_{1V}, S_{2H}, S_{2V}$) y mantener solo 2 planos de corrección:
* **Incógnitas**: 2 masas complejas ($\vec{M}_1, \vec{M}_2$).
* **Ecuaciones**: 4 lecturas de vibración complejas ($\vec{V}_{0,1H}, \vec{V}_{0,1V}, \vec{V}_{0,2H}, \vec{V}_{0,2V}$, es decir, 8 ecuaciones reales).
* **Matriz de Coeficientes**: Se convierte en una matriz no cuadrada $[\mathbf{C}]$ de dimensiones $4 \times 2$.
* **Consecuencia**: El sistema se vuelve **sobredeterminado** ($4 > 2$). En la práctica, debido a ruidos de medición, no-linealidades y asimetrías físicas del rotor, **no existe una combinación de masas que reduzca a cero absoluto la vibración en los 4 puntos de medición simultáneamente**.

### 6.2. Solución Matemática: Método de Mínimos Cuadrados
Para resolver este sistema, el objetivo cambia de "hacer la vibración residual igual a cero" a "minimizar el promedio de la energía vibratoria residual global". 

Definimos el vector de vibraciones residuales $\vec{\mathbf{V}}_{res} \in \mathbb{C}^4$:
$$\vec{\mathbf{V}}_{res} = \vec{\mathbf{V}}_0 + [\mathbf{C}] \vec{\mathbf{M}}$$

Buscamos minimizar la suma de los cuadrados de los módulos de la vibración residual (función de costo $E$):
$$E = \|\vec{\mathbf{V}}_{res}\|^2 = \vec{\mathbf{V}}_{res}^H \vec{\mathbf{V}}_{res}$$

donde $H$ indica la **traspuesta conjugada (Hermitiana)**. Al diferenciar con respecto a los componentes de la masa de corrección e igualar a cero, obtenemos las **Ecuaciones Normales**:
$$[\mathbf{C}]^H [\mathbf{C}] \vec{\mathbf{M}} = - [\mathbf{C}]^H \vec{\mathbf{V}}_0$$

Dado que $[\mathbf{C}]$ es $4 \times 2$, el término $[\mathbf{C}]^H [\mathbf{C}]$ es una **matriz cuadrada de $2 \times 2$**. Suponiendo que las columnas de $[\mathbf{C}]$ sean linealmente independientes, esta matriz es invertible y la solución óptima es:
$$\vec{\mathbf{M}} = - \left( [\mathbf{C}]^H [\mathbf{C}] \right)^{-1} [\mathbf{C}]^H \vec{\mathbf{V}}_0$$

Aquí, la expresión $\mathbf{C}^+ = ([\mathbf{C}]^H [\mathbf{C}])^{-1} [\mathbf{C}]^H$ es la **pseudoinversa de Moore-Penrose** de la matriz de coeficientes de influencia.

### 6.3. Necesidad de Ponderación (Weighted Least Squares)
En maquinaria rotativa, los soportes suelen ser **anisótropos** (la rigidez en la dirección horizontal suele ser significativamente menor que en la vertical debido al diseño del pedestal). Esto causa que las amplitudes de vibración horizontal sean mucho mayores.

Si aplicamos mínimos cuadrados simples, el algoritmo priorizará reducir las vibraciones horizontales (porque aportan más al error cuadrático total), descuidando e incluso empeorando las verticales.

Para corregir esto, se introduce una matriz diagonal de pesos reales positivos $[\mathbf{W}] \in \mathbb{R}^{4 \times 4}$:
$$[\mathbf{W}] = \begin{pmatrix} w_{1H} & 0 & 0 & 0 \\ 0 & w_{1V} & 0 & 0 \\ 0 & 0 & w_{2H} & 0 \\ 0 & 0 & 0 & w_{2V} \end{pmatrix}$$

La función de costo ponderada es $E_w = \vec{\mathbf{V}}_{res}^H [\mathbf{W}] \vec{\mathbf{V}}_{res}$, y su solución resulta en:
$$\vec{\mathbf{M}} = - \left( [\mathbf{C}]^H [\mathbf{W}] [\mathbf{C}] \right)^{-1} [\mathbf{C}]^H [\mathbf{W}] \vec{\mathbf{V}}_0$$

Esto permite al operador o al software dar más peso a un rodamiento crítico o equilibrar el peso de las componentes horizontales y verticales (por ejemplo, asignando $w_V > w_H$).

### 6.4. Impacto y Requerimientos de Código para la App
Para implementar esta lógica de 4 sensores dentro del código actual, se requeriría:

1. **Estructura de Datos (`RotorConfig`)**:
   * Permitir un nuevo modo de medición de 4 posiciones.
   * Almacenar coeficientes de ponderación opcionales.

2. **Cálculo de Coeficientes (`BalanceoProvider` / `BalanceoLogic`)**:
   * Los vectores de vibración inicial ($\vec{V}_0$) y de corridas de prueba con masas ($\vec{V}_1, \vec{V}_2$) pasan de contener 2 complejos a 4 complejos.
   * La matriz de coeficientes de influencia se almacena como `List<List<Complejo>>` de $4 \times 2$.
   * La fórmula para calcular los coeficientes de influencia individuales por plano $j$ y sensor $i$ sigue siendo lineal y directa:
     $$c_{i, j} = \frac{\vec{V}_{j, i} - \vec{V}_{0, i}}{\vec{M}_{t, j}}$$

3. **Inversión y Resolución**:
   * En lugar de calcular el determinante de la matriz directa $[\mathbf{C}]$, primero debemos efectuar el producto matricial complejo $[\mathbf{C}]^H [\mathbf{C}]$ (o $[\mathbf{C}]^H [\mathbf{W}] [\mathbf{C}]$).
   * Al ser el resultado de esta operación una matriz de $2 \times 2$, podemos reutilizar el algoritmo de inversión por determinante adjunto implementado en `calcularCorreccion2Planos` sobre esta nueva matriz resultante. No se requiere incluir bibliotecas externas complejas de álgebra lineal en Dart.
   * Ejemplo de pseudocódigo para resolver en Dart:
     ```dart
     // C = Matriz 4x2 de coeficientes de influencia
     // W = Matriz diagonal 4x4 de pesos
     // V0 = Vector de vibración inicial (longitud 4)
     
     // 1. Calcular C_H (Traspuesta conjugada, 2x4)
     // 2. Calcular A = C_H * W * C (Resultado: 2x2)
     // 3. Calcular B = C_H * W * (-V0) (Resultado: 2x1)
      // 4. Resolver A * M = B mediante inversión de matriz 2x2:
      //    M = A^-1 * B
      ```

### 6.5. ¿Priorización Automática de Posiciones de Medición?

La pregunta de si el sistema debe priorizar automáticamente ciertas posiciones o direcciones (e.g., horizontal vs vertical) sobre la base de la dinámica y la no linealidad es un dilema clásico en la dinámica de rotores y el balanceo industrial en campo.

#### 6.5.1. El Comportamiento Físico del Rotor: Anisotropía y Fuerza vs. Desplazamiento
* **Anisotropía de Soportes:** Los pedestales de rodamientos suelen ser mucho más rígidos verticalmente (apoyados en compresión sobre la fundación y base de concreto) que horizontalmente. Esto significa que la rigidez vertical ($K_y$) es usualmente entre 2 y 4 veces mayor que la horizontal ($K_x$).
* Por tanto, para una misma fuerza centrífuga de desbalance $F = m \cdot r \cdot \omega^2$, la amplitud de la vibración resultante será inherentemente mayor en la dirección horizontal ($V_x \approx F / K_x$) que en la vertical ($V_y \approx F / K_y$).
* **El Peligro de Priorizar Solo la Mayor Amplitud:** Si el sistema prioriza automáticamente la posición horizontal por tener mayor amplitud, puede estar ignorando fuerzas estructurales masivas en la dirección vertical. Una vibración de $3\text{ mm/s}$ en vertical puede estar transmitiendo esfuerzos a los rodamientos equivalentes a $9\text{ mm/s}$ en horizontal.

#### 6.5.2. Criterios para una Priorización Automática Inteligente
Una priorización 100% automatizada basada únicamente en "dónde hay más vibración" es peligrosa. Sin embargo, un sistema inteligente puede realizar una **priorización y ponderación automática adaptativa** utilizando tres criterios dinámicos y de calidad de señal:

1. **Estabilidad y Coherencia de Fase (Mitigación de No Linealidad):**
   * Las no linealidades (holguras mecánicas, roces estatóricos, desalineación severa) provocan que la fase del vector de vibración a la frecuencia de giro ($1\times$) sea inestable y fluctúe en el tiempo.
   * **Lógica del Sistema:** El software puede medir la desviación estándar de la fase en un intervalo de tiempo. Si un sensor presenta una desviación de fase elevada ($\sigma_{\theta} > 5^\circ$), el sistema debe **disminuir automáticamente su peso ($w_i$)** en la matriz $[\mathbf{W}]$. Las señales inestables por no linealidad ensucian el cálculo de coeficientes de influencia.
   
2. **Pureza Espectral del Desbalance (Relación $1\times$ vs. Valor Global / RMS):**
   * El balanceo por masas solo puede corregir la vibración síncrona a la frecuencia de giro del rotor ($1\times$).
   * Si un sensor muestra una vibración elevada, pero su análisis espectral revela que la energía está concentrada en armónicos ($2\times$, $3\times$ por desalineación) o subarmónicos ($0.5\times$ por holgura o inestabilidad de película de aceite), colocar masas de balanceo no resolverá el problema.
   * **Lógica del Sistema:** El sistema debe calcular el índice de pureza: $I_p = V_{1\times} / V_{RMS}$. Las posiciones con una relación baja ($I_p < 0.8$) deben ser penalizadas automáticamente con pesos menores en la matriz de mínimos cuadrados, alertando además al técnico sobre otros posibles problemas mecánicos.

3. **Consistencia en la Respuesta a Masas de Prueba (Linealidad de Coeficientes):**
   * Durante las iteraciones de refinamiento (nueva corrida tras colocar masas correctoras), el sistema predice cuál debería ser la nueva vibración residual.
   * Si en una dirección particular el error entre la vibración residual real y la predicha es sistemáticamente alto, el sistema detecta que esa posición opera en una zona no lineal (o el sensor está mal ubicado).
   * **Lógica del Sistema:** El algoritmo puede ajustar recursivamente los pesos de ponderación $w_i$, reduciendo la influencia de los sensores cuyo comportamiento desvíe de la linealidad del modelo.

#### 6.5.3. Recomendación de Diseño para la Aplicación
Para la arquitectura de tu aplicación, la mejor práctica recomendada es un **enfoque híbrido (Semiautomático)**:
1. **Ponderación por Defecto Normalizada:** El sistema inicializa la matriz $[\mathbf{W}]$ con pesos iguales ($1.0$) o normalizados por una estimación de rigidez genérica (e.g., $w_V = 1.5, w_H = 1.0$) para compensar la anisotropía natural.
2. **Filtro de Calidad Automático:** Si el sistema detecta inestabilidad de fase o baja pureza espectral en un canal de medición, debe reducir automáticamente su peso en la matriz $[\mathbf{W}]$ y mostrar una alerta en pantalla: *"Detector de no-linealidad/ruido activo: Sensor Vertical 2 ponderado al 20% debido a inestabilidad de fase"*.
3. **Control Manual para el Especialista:** Ofrecer un panel avanzado donde el técnico pueda ajustar manualmente los pesos de cada sensor en función de su experiencia y del conocimiento de la criticidad de cada rodamiento.