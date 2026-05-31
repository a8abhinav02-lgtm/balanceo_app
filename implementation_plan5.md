# Paso 5: Asistente Especializado para Rotores en Voladizo (Overhung)

El objetivo de este paso es implementar un asistente especializado para el balanceo de **Rotores en Voladizo (Overhung)**. Debido al alto acoplamiento dinámico (efecto cruzado o *cross-effect* > 100%) característico de estas geometrías (e.g., extractores, ventiladores de tiro inducido), el cálculo convencional de 2 planos por matriz de influencia 2x2 suele ser numéricamente inestable.

> [!IMPORTANT]
> **Diseño 100% Opcional y No Bloqueante**
> Para mantener la rapidez de operación en campo y no forzar análisis adicionales cuando no se requieran:
> * Esta funcionalidad es totalmente opcional. El selector en la pantalla de configuración vendrá desactivado por defecto.
> * Si el selector permanece desactivado, el flujo de balanceo de 2 planos convencional (matriz 2x2) operará de forma idéntica a la actual, sin interrupciones ni cambios de flujo para el analista.
> * Únicamente cuando se active explícitamente "Rotor en Voladizo (Overhung)", la aplicación cambiará al método de balanceo modal secuencial Estático-Acople.

Para resolver esto (cuando esté activado), implementaremos la **descomposición modal Estático-Acople (Static-Couple)** guiando al analista a través de dos fases secuenciales de prueba:
1. **Fase 1 (Estático):** Colocación de masas de prueba idénticas en fase en ambos planos para aislar el desbalance estático, midiendo la respuesta promedio.
2. **Fase 2 (Acople):** Colocación de masas de prueba idénticas desfasadas 180° en ambos planos para aislar el desbalance de acople, midiendo la respuesta diferencial.

---

## Lógica Matemática de Balanceo Estático-Acople

### 1. Variables de Vibración Modal
A partir de las lecturas iniciales de vibración en el rodamiento cercano $\vec{V}_{10}$ (Canal 1) y el rodamiento lejano $\vec{V}_{20}$ (Canal 2):
* **Componente Estática Inicial:**
  $$\vec{V}_{s0} = \frac{\vec{V}_{10} + \vec{V}_{20}}{2}$$
* **Componente de Acople Inicial:**
  $$\vec{V}_{c0} = \frac{\vec{V}_{10} - \vec{V}_{20}}{2}$$

---

### 2. Fase 1: Coeficiente de Influencia Estático ($H_s$)
* El analista instala una masa de prueba estática $\vec{T}_s$ en ambos planos (mismo peso y ángulo, e.g., $M$ en $0^\circ$ en Plano 1 y Plano 2).
* Mide las nuevas vibraciones $\vec{V}_{11}$ y $\vec{V}_{21}$.
* Calcula la respuesta estática resultante:
  $$\vec{V}_{s1} = \frac{\vec{V}_{11} + \vec{V}_{21}}{2}$$
* Calcula el coeficiente de influencia estático:
  $$H_s = \frac{\vec{V}_{s1} - \vec{V}_{s0}}{\vec{T}_s}$$
* La corrección estática requerida es:
  $$\vec{C}_s = -\frac{\vec{V}_{s0}}{H_s}$$

---

### 3. Fase 2: Coeficiente de Influencia de Acople ($H_c$)
* El analista instala una pareja de masas de prueba de acople $\vec{T}_c$ desfasadas 180° (e.g., $M$ en $0^\circ$ en Plano 1 y $M$ en $180^\circ$ en Plano 2).
* Mide las nuevas vibraciones $\vec{V}_{12}$ y $\vec{V}_{22}$.
* Calcula la respuesta de acople resultante:
  $$\vec{V}_{c2} = \frac{\vec{V}_{12} - \vec{V}_{22}}{2}$$
* Calcula el coeficiente de influencia de acople:
  $$H_c = \frac{\vec{V}_{c2} - \vec{V}_{c0}}{\vec{T}_c}$$
* La corrección de acople requerida es:
  $$\vec{C}_c = -\frac{\vec{V}_{c0}}{H_c}$$

---

### 4. Consolidación de Correcciones Finales
Una vez completadas ambas fases, la masa correctora recomendada para cada plano es:
* **Plano 1 (Cercano):**
  $$\vec{M}_1 = \vec{C}_s + \vec{C}_c$$
* **Plano 2 (Lejano):**
  $$\vec{M}_2 = \vec{C}_s - \vec{C}_c$$

*(Esto permite aislar y corregir ambos modos dinámicos de forma totalmente independiente e inmune al ruido cruzado de rodamientos).*

---

## Cambios Propuestos

### 1. Modelo de Datos
#### [MODIFY] [rotor_config.dart](file:///c:/Users/angel/balanceo_app/lib/models/rotor_config.dart)
* Agregar el campo `bool esVoladizo` (por defecto `false`).
* Actualizar el método `copyWith`, la serialización `toJson` y la deserialización `fromJson` para soportar este nuevo parámetro.

---

### 2. Backend / Lógica de Negocio
#### [MODIFY] [balanceo_provider.dart](file:///c:/Users/angel/balanceo_app/lib/providers/balanceo_provider.dart)
* Añadir campos temporales persistentes en el proveedor:
  * `bool esVoladizo` (se sincroniza con `config.esVoladizo` al establecer la configuración).
  * `Complejo? mtEstatico` (masa de prueba estática ingresada en la Fase 1).
  * `Complejo? mtAcople` (masa de prueba de acople ingresada en la Fase 2).
  * `List<Complejo>? vEstatico` (vibraciones resultantes de la Fase 1).
  * `List<Complejo>? vAcople` (vibraciones resultantes de la Fase 2).
* Implementar métodos matemáticos para calcular los coeficientes modales $H_s$ y $H_c$, así como las correcciones consolidadas $\vec{M}_1$ y $\vec{M}_2$.
* Guardar e inicializar el estado del voladizo en `saveToDisk` y `cargarActivo`.

---

### 3. Interfaz de Usuario (UX)
#### [MODIFY] [configuracion_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/configuracion_screen.dart)
* Renderizar un switch condicional **"Rotor en voladizo (Overhung)"** únicamente cuando `numPlanos == 2` está seleccionado.
* Mostrar una breve descripción explicativa para el analista de campo sobre el método de balanceo modal.

#### [MODIFY] [prueba_coeficientes_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/prueba_coeficientes_screen.dart)
* Si `esVoladizo` es `true` y `numPlanos` es `2`:
  * Dividir la pantalla de prueba en dos pasos internos secuenciales (Paso 1: Estático, Paso 2: Acople).
  * Mostrar instrucciones claras en banners superiores para guiar físicamente al técnico:
    * **Paso 1 (Estático):** *"Instale masas de prueba idénticas en la misma posición angular en el Plano 1 y Plano 2..."*
    * **Paso 2 (Acople):** *"Instale una pareja de masas de prueba idénticas desfasadas 180° (Plano 1 en el ángulo ingresado, Plano 2 desfasado +180°)..."*
  * Sincronizar el botón inferior: cambiar de "Siguiente" (para avanzar de la Fase 1 a la Fase 2) a "Calcular" (en la Fase 2 para realizar el análisis modal completo).

#### [MODIFY] [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart)
* Asegurar que cuando `esVoladizo` es `true`, los cálculos de `m1` y `m2` utilicen las ecuaciones de corrección modal estático-acople descritas en los fundamentos matemáticos.
* Presentar etiquetas informativas en la pantalla de resultados indicando que los contrapesos recomendados corresponden a la consolidación modal estático-acople.

---

## Plan de Verificación

### Pruebas Automatizadas
* Crear un widget test en [navigation_test.dart](file:///c:/Users/angel/balanceo_app/test/navigation_test.dart) que verifique:
  * El guardado de la configuración en modo Voladizo (Overhung).
  * La navegación paso a paso a través de la Fase 1 (Estática) y Fase 2 (Acople) con visualización de banners informativos.
  * La exactitud del cálculo de la respuesta estática y de acople, y la consolidación de masas correctoras finales para los planos 1 y 2.
  * La transición exitosa a la pantalla de resultados mostrando la etiqueta modal.

### Verificación Manual
1. Crear un activo "Turbina Voladizo" de 2 planos, seleccionando "Rotor en voladizo (Overhung)".
2. Avanzar a la medición inicial e ingresar vibraciones con desfasaje (e.g. $10\text{ µm} \angle 0^\circ$ y $8\text{ µm} \angle 120^\circ$).
3. Avanzar a la prueba de coeficientes:
   * Colocar un peso estático de $5\text{ g} \angle 0^\circ$. Ingresar las lecturas resultantes en la Fase 1.
   * Tapar "Siguiente". Se presentará la Fase 2 para el desbalance de acople.
   * Colocar un peso de acople de $5\text{ g} \angle 0^\circ$ (desfasado $180^\circ$ en P2). Ingresar lecturas y presionar "Calcular".
4. Validar que la pantalla de resultados muestre los contrapesos consolidados correctos.
