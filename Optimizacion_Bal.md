A partir del análisis del documento **[Balanceo Dinamico en Campo.md](file:///c:/Users/angel/balanceo_app/Balanceo%20Dinamico%20en%20Campo.md)** y cruzándolo con el estado actual del código de tu aplicación, he identificado **7 oportunidades clave de mejora**. 

Estas mejoras elevarían tu aplicación de una calculadora matemática básica a un asistente técnico de balanceo de nivel industrial:

---

### 1. Sugerencia Automática de la Masa de Prueba (TW)
* **Situación actual:** La aplicación solicita al usuario que ingrese la masa de prueba en [prueba_coeficientes_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/prueba_coeficientes_screen.dart#L96) sin darle ninguna recomendación física de cuánto peso colocar.
* **Oportunidad de Mejora (Sección 9.A):** Implementar la fórmula de estimación de masa de prueba segura basada en el peso del rotor ($W_{\text{kg}}$), el radio de colocación ($r_{\text{mm}}$) y la velocidad nominal de giro ($n_{\text{RPM}}$):
  $$m_{\text{g}} = 1.79 \times 10^8 \cdot \frac{W_{\text{kg}}}{r_{\text{mm}} \cdot n^2}$$
* **Impacto:** Evita que el técnico coloque un peso demasiado grande que dañe los rodamientos de la máquina o uno muy pequeño que no cause impacto.

---

### 2. Validación de la "Regla del 30/30"
* **Situación actual:** La app acepta cualquier valor de vibración de la corrida de prueba e inicia el cálculo matemático de inmediato, incluso si la masa de prueba no causó ningún cambio.
* **Oportunidad de Mejora (Sección 9.A):** Al ingresar los datos de la corrida de prueba, la app debe verificar automáticamente que el vector de vibración $\vec{V}_1$ haya cambiado al menos **30% en amplitud** o **$30^\circ$ en fase** con respecto al vector inicial $\vec{V}_0$.
* **Impacto:** Si no se cumple esta regla, el sistema debe mostrar una advertencia: *“Advertencia: El cambio en la vibración es insignificante. Aumente la masa de prueba para evitar errores matemáticos por ruido en el sensor”*. Esto blinda el software contra coeficientes de influencia inexactos.

---

### 3. División Vectorial de Pesos (Weight Splitting)
* **Situación actual:** En rotores discretos (con un número fijo de álabes), la app calcula el ángulo exacto donde colocar el peso en [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart#L305), pero si el ángulo cae en un espacio vacío entre álabes, el usuario debe calcular visual o empíricamente el reparto.
* **Oportunidad de Mejora (Sección 9.Q):** Implementar una utilidad interactiva de **"Dividir Pesos"** en la pantalla de resultados. Si el usuario tiene un rotor de álabes (ej: 12 álabes), la app calcula vectorialmente cómo repartir esa única masa teórica en las dos posiciones físicas de álabes más cercanas sin alterar la fuerza centrífuga resultante.
* **Impacto:** Facilidad de montaje físico directo para el operador de campo.

---

### 4. Combinación Vectorial de Masas de Refinamiento (Add Vectors)
* **Situación actual:** Si la vibración no baja a la primera y se inicia una "Nueva Iteración" (Trim), el técnico termina colocando un peso de corrección original más un peso de ajuste fino (Trim 1) en posiciones distintas del rotor.
* **Oportunidad de Mejora (Sección 9.R):** Agregar una función en el historial o resultados para **"Combinar Pesos"**. Esta suma vectorialmente todos los contrapesos instalados en un plano a lo largo del proceso y le dice al técnico: *"Retire todos los pesos previos e instale un único peso de X gramos en la posición Y°"*.
* **Impacto:** Mantiene limpio el rotor, evitando la acumulación de múltiples pesos pequeños en diferentes puntos.

---

### 5. Asistente para Rotores en Voladizo (Overhung Rotors)
* **Situación actual:** La aplicación trata todos los rotores de 2 planos de forma idéntica en [balanceo_provider.dart](file:///c:/Users/angel/balanceo_app/lib/providers/balanceo_provider.dart#L186), asumiendo un rotor simétrico apoyado entre chumaceras.
* **Oportunidad de Mejora (Sección 9.O):** Permitir seleccionar en la configuración si el rotor está "En Voladizo" (ej. extractores, ventiladores de tiro inducido). Si se activa, la app guiará al operador a realizar corridas especiales:
  * Medir el desbalance estático en el rodamiento cercano y el de acople en el rodamiento lejano.
  * Recomendar la instalación de pesos en pareja (acoplados $180^\circ$) para aislar la interferencia de planos (cross-effect) que en estos rotores suele ser superior al 100%.

---

### 6. Evaluación de Tolerancia de Calidad según ISO 1940
* **Situación actual:** La aplicación compara el resultado final solo contra un "Límite Objetivo" estático introducido por el usuario en micras o mils.
* **Oportunidad de Mejora (Sección 11.B):** Crear una calculadora de **Grado de Calidad ISO 1940** integrada. El usuario selecciona el tipo de máquina (ej. G2.5 para ventiladores industriales o G6.3 para bombas) y el peso del rotor. La app calcula el desbalance residual admisible ($e_{per}$ en g-mm) y evalúa si la vibración final alcanzada cumple la norma.
* **Impacto:** Entrega un reporte PDF con validez oficial internacional que certifica que el balanceo cumple con los estándares de la norma ISO.

---

### 7. Diagnóstico Previo al Balanceo (Lista de Verificación)
* **Situación actual:** El usuario inicia la configuración del rotor directamente.
* **Oportunidad de Mejora (Sección 4):** Crear una pantalla o lista de verificación interactiva de diagnóstico preliminar basada en el comportamiento de la fase. Por ejemplo, preguntar la fase en H y V para verificar si el desfase cumple los parámetros de desbalance dinámico, o alertar si la fase fluctúa (indicador de soltura mecánica o no-linealidad).
* **Impacto:** Evita que el técnico pierda tiempo intentando balancear una máquina que en realidad tiene desalineación, ejes doblados o soltura mecánica en su base.
