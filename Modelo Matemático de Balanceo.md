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

### 6.6. Relación entre Canales de Medición, Planos de Corrección y Corridas de Prueba

Es un malentendido común asumir que al incrementar el número de sensores (canales de medición, $M$) se requiere incrementar proporcionalmente el número de corridas o masas de prueba. 

**La regla física y matemática fundamental es:**
> El número de corridas de prueba (y por ende de masas de prueba instaladas) es **estrictamente igual al número de planos de corrección ($N$)**, independientemente de cuántos canales de medición ($M$) se estén monitoreando simultáneamente.

#### 6.6.1. Explicación Matemática de las Dimensiones de la Matriz $[\mathbf{C}]$
La matriz de coeficientes de influencia $[\mathbf{C}]$ tiene dimensiones de **$M \times N$** (Sensores $\times$ Planos).
* Cada **columna** de la matriz corresponde a un plano de corrección $j$.
* Cada **fila** corresponde a un sensor o punto de medición $i$.

Para rellenar una columna entera $j$ (que contiene los coeficientes de influencia de ese plano sobre todos los sensores), solo se requiere realizar **una única corrida de prueba** colocando un peso conocido en el plano $j$ y registrando la respuesta en todos los sensores al mismo tiempo.

#### 6.6.2. Ejemplo de Operación en Campo: 2 Planos y 4 Sensores ($M=4, N=2$)
Para balancear un rotor con 4 sensores utilizando 2 planos de corrección, el procedimiento requiere únicamente **3 corridas en total** (la inicial más dos de prueba):

1. **Corrida Inicial (Sin masas de prueba):**
   * Se mide la vibración inicial en los 4 sensores simultáneamente: $\vec{V}_{0,1H}, \vec{V}_{0,1V}, \vec{V}_{0,2H}, \vec{V}_{0,2V}$.
2. **Corrida de Prueba 1 (Masa $\vec{M}_{t1}$ instalada en el Plano 1):**
   * Se mide la vibración modificada en los 4 sensores simultáneamente: $\vec{V}_{1,1H}, \vec{V}_{1,1V}, \vec{V}_{1,2H}, \vec{V}_{1,2V}$.
   * Se calcula la **columna 1** de la matriz $[\mathbf{C}]$ (4 coeficientes complejos correspondientes al Plano 1):
     $$c_{i, 1} = \frac{\vec{V}_{1, i} - \vec{V}_{0, i}}{\vec{M}_{t1}} \quad \text{para } i \in \{1H, 1V, 2H, 2V\}$$
3. **Corrida de Prueba 2 (Se retira la masa 1 y se instala $\vec{M}_{t2}$ en el Plano 2):**
   * Se mide la vibración modificada en los 4 sensores simultáneamente: $\vec{V}_{2,1H}, \vec{V}_{2,1V}, \vec{V}_{2,2H}, \vec{V}_{2,2V}$.
   * Se calcula la **columna 2** de la matriz $[\mathbf{C}]$ (4 coeficientes complejos correspondientes al Plano 2):
     $$c_{i, 2} = \frac{\vec{V}_{2, i} - \vec{V}_{0, i}}{\vec{M}_{t2}} \quad \text{para } i \in \{1H, 1V, 2H, 2V\}$$

Con esto se ha determinado la matriz completa $[\mathbf{C}]$ de $4 \times 2$. El algoritmo de mínimos cuadrados calcula las masas correctoras finales para los planos 1 y 2 en base a esta información.

#### 6.6.3. Beneficio Industrial
Esta independencia entre el número de sensores y el número de corridas de prueba es una gran ventaja práctica. Colocar un peso de prueba requiere detener la máquina, esperar a que desacelere, abrir guardas de seguridad, instalar el peso, cerrar guardas y volver a arrancar la máquina. 
Al medir en 4 canales en lugar de 2, el técnico obtiene un mapa de vibraciones mucho más completo y seguro **sin añadir un solo minuto extra de parada de máquina o instalaciones de pesos adicionales**.

---

### 6.7. Ambigüedad de Nomenclatura en la App: Ejes Ortogonales (X/Y) vs. Soportes Físicos (Soporte 1/2)

El análisis del código fuente y de las pantallas de la aplicación confirma una **importante confusión conceptual y terminológica** en el diseño actual de la interfaz y el modelo de datos respecto a los sensores y los planos de corrección:

#### 6.7.1. Lo que dicta la teoría de balanceo dinámico (2 Planos):
1. **Planos de Corrección ($N=2$):** Ubicaciones a lo largo del eje del rotor donde se colocan contrapesos (ej: Plano Izquierdo / Plano Derecho o Plano Lado Acople / Lado Libre).
2. **Posiciones de Medición ($M=2$):** Puntos donde se colocan los sensores de vibración. Para balancear dinámicamente dos planos, la práctica industrial estándar requiere **colocar un sensor en el Soporte/Rodamiento 1 y otro sensor en el Soporte/Rodamiento 2**, midiendo ambos en la misma dirección (típicamente horizontal o vertical).

#### 6.7.2. Lo que implementa la interfaz actual de la App:
* En [configuracion_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/configuracion_screen.dart#L266-L290), se define la configuración geométrica de los sensores como **Sensor X** y **Sensor Y** (con ángulos por defecto de 0° y 90°).
* En [medicion_inicial_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/medicion_inicial_screen.dart#L132-L182) y [prueba_coeficientes_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/prueba_coeficientes_screen.dart#L101-L177), las entradas se titulan:
  * **Sensor 1 (X)** (Asociado al color Azul)
  * **Sensor 2 (Y)** (Asociado al color Rojo)

#### 6.7.3. La Confusión de Nomenclatura y su Conflicto Físico:
Esta forma de estructurar la interfaz genera una contradicción de interpretación física:

1. **Interpretación A: Los sensores representan ejes ortogonales en un único soporte.**
   * Si "Sensor X" y "Sensor Y" son la medición Horizontal y Vertical de **un mismo rodamiento** (como insinúan los nombres de las variables y sus ángulos de 0° y 90°):
     * El cálculo de "2 planos" en la app estaría balanceando el rotor basándose únicamente en el comportamiento de un extremo del rotor, ignorando totalmente lo que ocurre en el otro soporte. Esto no resuelve el desbalance dinámico de par/momento y es incorrecto para la mayoría de los rotores industriales apoyados sobre dos rodamientos.
2. **Interpretación B: Los sensores representan dos soportes de rodamientos distintos.**
   * Si el usuario coloca el Sensor 1 en el Rodamiento Lado Acople y el Sensor 2 en el Rodamiento Lado Libre (lo cual es el estándar para balancear 2 planos):
     * La nomenclatura de llamarlos "Sensor X" y "Sensor Y" y configurar sus ángulos como ortogonales (0° y 90°) es **totalmente incorrecta e induce a error**. En este escenario, ambos sensores están midiendo en la misma dirección física (ambos horizontales a 0° o ambos verticales a 90°) pero en distintos rodamientos.

#### 6.7.4. Recomendación de Reestructuración de la Interfaz
Para limpiar esta ambigüedad, la aplicación debería diferenciar claramente entre:
* **En el modelo de datos (`RotorConfig`) y pantallas:**
  * En lugar de fijar "Sensor X" y "Sensor Y", renombrar las etiquetas y variables a **Sensor Soporte 1** y **Sensor Soporte 2** (o Rodamiento A / Rodamiento B).
  * Permitir configurar el ángulo de orientación para cada soporte de manera independiente (ej: ambos a 0° si miden horizontal, o ambos a 90° si miden vertical).
* **Al ampliar a 4 posiciones de medición (Sección 6.6):**
  * La interfaz solicitará explícitamente:
    * **Soporte 1:** Horizontal ($S_{1H}$) y Vertical ($S_{1V}$)
    * **Soporte 2:** Horizontal ($S_{2H}$) y Vertical ($S_{2V}$)
  * De esta forma, la app se alinea con la nomenclatura real de campo, eliminando cualquier confusión entre dirección del canal (H/V) y plano físico de corrección.

---

### 6.8. Estrategia de Configuración Dinámica de Canales por Tags de Usuario (`1H`, `2H`, `1V`, `2V`)

Para llevar la flexibilidad y claridad de la aplicación al nivel de un software industrial de alta gama (como CSI/Emerson o Bently Nevada), la propuesta de **permitir que el usuario asigne sus propios tags o nombres a las posiciones de medición** es la solución definitiva.

#### 6.8.1. Estructura y Significado de los Tags Propuestos
El estándar de nomenclatura rápida en mantenimiento predictivo consiste en abreviar la posición con un formato alfanumérico donde:
* **El número representa el soporte físico / rodamiento** (ej: `1` = Lado Acople / Drive End, `2` = Lado Libre / Non-Drive End).
* **La letra representa la coordenada/eje de medición** (ej: `H` = Horizontal, `V` = Vertical, o `X` / `Y` para sistemas ortogonales de proximidad).

Esto permite combinaciones claras para el técnico:
* **`1H`**: Soporte 1, dirección Horizontal.
* **`2H`**: Soporte 2, dirección Horizontal.
* **`1V`**: Soporte 1, dirección Vertical.
* **`2V`**: Soporte 2, dirección Vertical.

#### 6.8.2. Implementación de Modelado de Datos Flexible
En lugar de tener campos rígidos en `RotorConfig` como `sensorXAngulo` o `sensorYAngulo`, se puede modelar una colección de objetos `CanalMedicion`:

```dart
class CanalMedicion {
  String tag;          // Ej: "1H", "2H", "1V", "2V" o personalizado: "DE-H", "NDE-H"
  double angulo;       // Ángulo físico del sensor (ej: 0.0, 90.0)
  int idSoporte;       // 1 o 2 (Para mapear físicamente el rodamiento)
  String direccion;    // "H", "V", "X" o "Y"
}
```

En la configuración, el usuario ve una lista de canales dinámicos y puede editar el "Tag" visual.

#### 6.8.3. Beneficios de esta Propuesta
1. **Eliminación Absoluta de la Confusión:** Si el usuario está realizando un balanceo en 2 planos usando únicamente las componentes horizontales, configura dos canales con los tags **`1H`** y **`2H`**. Queda explícito que son dos soportes diferentes en la misma dirección horizontal, descartando el equívoco de mezclar ejes ortogonales en un solo punto.
2. **Personalización del Entorno de Trabajo:** Hay plantas industriales que prefieren terminologías en inglés (`DE-H`, `NDE-H` para *Drive End / Non-Drive End*) o nomenclaturas específicas de fábrica. Permitir la edición del tag hace que la app se adapte al vocabulario del cliente, no al revés.
3. **Claridad en los Reportes PDF:** El reporte exportado utilizará los tags exactos ingresados por el usuario, facilitando que otros ingenieros auditen el trabajo sin ambigüedades.
4. **Coexistencia de X/Y y H/V:** Al mantener el campo `direccion` y permitir editar el tag, un técnico que use sondas de proximidad Bently Nevada puede etiquetar sus canales como `1X` y `1Y`, mientras que un técnico con acelerómetros tradicionales puede usar `1H` y `1V`. Ambos conviven bajo la misma lógica matemática.