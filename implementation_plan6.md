# Paso 5 (Siguiente): Control de Calidad de Balanceo bajo Norma ISO 1940 (Opcional)

El objetivo de esta mejora es incorporar un módulo opcional de control de calidad bajo la norma internacional **ISO 1940-1** para certificar técnicamente el estado del balanceo.

---

## Fundamentos Matemáticos de la Norma ISO 1940

### 1. Desbalance Residual Permitido ($U_{per}$)
Dada la velocidad del rotor $N$ (en RPM) y el grado de calidad seleccionado $G$ (e.g., $G2.5$ para ventiladores industriales):
* **Frecuencia angular ($\omega$):**
  $$\omega = \frac{2\pi \times N}{60} \approx 0.10472 \times N \quad \text{(rad/s)}$$
* **Desbalance específico permitido ($e_{per}$):**
  $$e_{per} = \frac{G \times 1000}{\omega} \approx \frac{9549.3 \times G}{N} \quad \text{(g-mm/kg)}$$
* **Desbalance total permitido ($U_{per}$):**
  $$U_{per} = e_{per} \times W \quad \text{(g-mm totales)}$$
  Donde $W$ es el peso del rotor en kg.
* **Desbalance permitido por plano ($U_{per, plane}$):**
  $$U_{per, plane} = \frac{U_{per}}{P}$$
  Donde $P$ es el número de planos de corrección (1 o 2).

---

### 2. Cálculo del Desbalance Residual Real ($U_{residual}$)
Para comparar el estado final del rotor con la norma, calculamos la sensibilidad del rotor ($S$) para cada plano $j$:
* **Sensibilidad del plano $j$ ($S_j$):**
  $$S_j = \frac{M_{tj} \times R}{|V_{jj} - V_{j0}|} \quad \text{(g-mm / unit\_vibracion)}$$
  Donde:
  * $M_{tj}$ es el peso de prueba en el plano $j$ (en gramos).
  * $R$ es el radio de colocación de masa (en mm).
  * $|V_{jj} - V_{j0}|$ es el módulo del vector de efecto del peso de prueba (diferencia entre la lectura con peso de prueba y la lectura inicial en el rodamiento $j$).
* **Desbalance residual real del plano $j$ ($U_{residual, j}$):**
  $$U_{residual, j} = S_j \times V_{final, j} \quad \text{(g-mm)}$$
  Donde $V_{final, j}$ es la amplitud de vibración final medida en el sensor $j$ (tras el balanceo final o corrida de verificación).

---

### 3. Criterio de Aceptación
El balanceo cumple con la norma ISO 1940 si para cada plano $j$:
$$U_{residual, j} \le U_{per, plane}$$

---

## Cambios Propuestos

### 1. Modelo de Datos
#### [MODIFY] [rotor_config.dart](file:///c:/Users/angel/balanceo_app/lib/models/rotor_config.dart)
* Añadir el campo opcional `String? gradoISO` (e.g. `'G2.5'`).
* Actualizar `copyWith`, `toJson`, y `fromJson` para persistir este campo.

---

### 2. Backend / Lógica de Negocio
#### [MODIFY] [balanceo_provider.dart](file:///c:/Users/angel/balanceo_app/lib/providers/balanceo_provider.dart)
* Implementar una función `calcularISO1940()` que:
  * Tome los parámetros del rotor (`gradoISO`, `pesoRotor`, `velocidadRPM`, `radioPeso`).
  * Calcule $U_{per, plane}$ y $U_{residual, j}$ para cada plano.
  * Devuelva un objeto estructurado con las tolerancias, valores reales calculados y veredictos de cumplimiento.

---

### 3. Interfaz de Usuario (UX)
#### [MODIFY] [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart)
* Diseñar la tarjeta **"Control de Calidad ISO 1940"** colapsable/opcional.
* Si el técnico no ingresó el peso/RPM/radio en la configuración inicial, permitirle ingresarlos o editarlos directamente en este módulo.
* Mostrar un menú desplegable con los grados típicos de calidad ($G0.4$, $G1.0$, $G2.5$, $G6.3$, $G16$, $G40$) con descripciones del tipo de maquinaria.
* Mostrar dinámicamente el resultado de comparación y una insignia verde destacada **"CUMPLE CON ISO G2.5"** o roja **"NO CUMPLE CON ISO G2.5"**.
* Sincronizar y guardar la selección en el proveedor al vuelo.

---

### 4. Exportación del Reporte PDF
#### [MODIFY] [pdf_export.dart](file:///c:/Users/angel/balanceo_app/lib/utils/pdf_export.dart)
* Si `gradoISO` está seleccionado, añadir una sección **"Certificación de Calidad ISO 1940"** al final del PDF que incluya los parámetros de cálculo ($G$, $W$, $N$, $R$), el desbalance residual permitido, el residual real obtenido y la firma de conformidad.

---

## Plan de Verificación

### Pruebas Automatizadas
* Crear un widget test en [navigation_test.dart](file:///c:/Users/angel/balanceo_app/test/navigation_test.dart) que verifique:
  * El cálculo correcto de $U_{per}$ y $U_{residual}$ en base a lecturas ingresadas.
  * El renderizado exitoso de las insignias de cumplimiento en la pantalla de resultados.
  * La persistencia de los campos ISO en base de datos local (`shared_preferences`).
