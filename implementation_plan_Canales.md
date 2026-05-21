# Plan de Implementación: Canales Dinámicos a Voluntad y Mínimos Cuadrados Ponderados (Fases 3 y 4)

Este plan detalla la implementación para permitir que el usuario elija y configure de 1 a 4 canales de medición a voluntad, junto con sus respectivos pesos (ponderaciones) para el cálculo de balanceo por mínimos cuadrados (Weighted Least Squares).

---

## 🛠️ Objetivos
1.  **Canales a voluntad**: Permitir agregar y eliminar canales dinámicamente en la pantalla de configuración.
    *   Mínimo de canales: 1 para balanceo de 1 plano, 2 para balanceo de 2 planos.
    *   Máximo de canales: 4.
2.  **Ponderación (Pesos)**: Permitir asignar un peso real ($w_i \ge 0.1$) a cada canal para compensar la anisotropía del soporte.
3.  **Modelo Matemático Unificado**: Implementar la pseudoinversa de Moore-Penrose ponderada para 1 y 2 planos de corrección sobre $M$ canales, sin dependencias externas.
4.  **Flujo Dinámico**: Adaptar las pantallas de Medición Inicial, Prueba de Coeficientes, Resultados, Gráfico Polar y Reporte PDF para manejar listas dinámicas de tamaño $M$.

---

## 📐 Modelo Matemático Ponderado (M Canales, N Planos)

Definimos el vector de pesos diagonales $\mathbf{W} = \text{diag}(w_1, w_2, \dots, w_M)$ donde $w_i$ es el peso del canal $i$.

### 1. Balanceo en 1 Plano ($N=1$)
*   Vectores de vibración: $\vec{\mathbf{V}}_0, \vec{\mathbf{V}}_1 \in \mathbb{C}^M$
*   Coeficientes de influencia: $\vec{\boldsymbol{\alpha}} \in \mathbb{C}^M$ donde $\alpha_i = \frac{V_{1,i} - V_{0,i}}{M_t}$
*   Fórmula de Masa Correctora óptima:
    $$M_c = -\frac{\sum_{i=1}^M w_i \alpha_i^* V_{0,i}}{\sum_{i=1}^M w_i |\alpha_i|^2}$$
    *(Si $M=1$ y $w_1=1.0$, se reduce a la fórmula exacta original $M_c = -\frac{V_{0,1}}{\alpha_1}$)*

### 2. Balanceo en 2 Planos ($N=2$)
*   Matriz de coeficientes de influencia $\mathbf{C} \in \mathbb{C}^{M \times 2}$
*   Calculamos la matriz cuadrada $\mathbf{A} = \mathbf{C}^H \mathbf{W} \mathbf{C} \in \mathbb{C}^{2 \times 2}$ y el vector $\vec{\mathbf{B}} = -\mathbf{C}^H \mathbf{W} \vec{\mathbf{V}}_0 \in \mathbb{C}^2$:
    *   $A_{11} = \sum_{i=1}^M w_i |c_{i,1}|^2$
    *   $A_{12} = \sum_{i=1}^M w_i c_{i,1}^* c_{i,2}$
    *   $A_{21} = A_{12}^*$
    *   $A_{22} = \sum_{i=1}^M w_i |c_{i,2}|^2$
    *   $B_1 = -\sum_{i=1}^M w_i c_{i,1}^* V_{0,i}$
    *   $B_2 = -\sum_{i=1}^M w_i c_{i,2}^* V_{0,i}$
*   Determinante $D = A_{11} A_{22} - |A_{12}|^2$ (siempre real)
*   Solución vectorial de masas $\vec{\mathbf{M}} = \begin{pmatrix} M_{c1} \\ M_{c2} \end{pmatrix}$:
    *   $M_{c1} = \frac{A_{22} B_1 - A_{12} B_2}{D}$
    *   $M_{c2} = \frac{A_{11} B_2 - A_{21} B_1}{D}$
    *(Si $M=2$ y $w_i=1.0$, se reduce exactamente al sistema determinado original)*

---

## 💻 Cambios Propuestos

### 1. Modelo de Datos (`CanalMedicion` y `HistorialItem`)

#### [MODIFY] [canal_medicion.dart](file:///c:/Users/angel/balanceo_app/lib/models/canal_medicion.dart)
*   Agregar propiedad `double peso` (por defecto `1.0`).
*   Actualizar `copy`, `toJson` y `fromJson`.

#### [MODIFY] [historial_item.dart](file:///c:/Users/angel/balanceo_app/lib/models/historial_item.dart)
*   Sustituir `vibracionResidual1` y `vibracionResidual2` por `List<double> vibracionesResiduales`.
*   En `fromJson`, realizar migración retrocompatible: si existen las propiedades antiguas, inicializar la lista con `[vibracionResidual1, vibracionResidual2]`.

---

### 2. Proveedor de Estado (`BalanceoProvider`)

#### [MODIFY] [balanceo_provider.dart](file:///c:/Users/angel/balanceo_app/lib/providers/balanceo_provider.dart)
*   Sustituir `v0_1` y `v0_2` por `List<Complejo>? v0`.
*   Sustituir `v0_1_original` y `v0_2_original` por `List<Complejo>? v0Original`.
*   Sustituir variables temporales de corridas de prueba (`v1_1_temp`, `v1_2_temp`, etc.) por:
    *   `List<Complejo>? v1Temp` (mediciones con masa en P1).
    *   `List<Complejo>? v2Temp` (mediciones con masa en P2).
*   Sustituir `coeficiente1` y `matrizCoeficientes` por `List<List<Complejo>>? matrizCoeficientes` de dimensiones $M \times N$ (donde $N$ es el número de planos).
*   Eliminar `usarSensorX` (ya no se requiere al promediar por mínimos cuadrados).
*   Implementar métodos de cálculo generalizados:
    *   `setMedicionInicial(List<Complejo> lecturas)`
    *   `calcularCoeficientes1Plano(Complejo pesoPrueba, List<Complejo> v1)`
    *   `calcularCoeficientes2Planos(Complejo mt1, Complejo mt2, List<Complejo> v1, List<Complejo> v2)`
    *   `calcularCorreccion1Plano()` usando la fórmula de mínimos cuadrados ponderada.
    *   `calcularCorreccion2Planos()` usando la pseudoinversa ponderada de $2 \times 2$.
    *   `nuevaIteracion(List<Complejo> nuevasLecturas)`

---

### 3. Vistas de la Aplicación (UI)

#### [MODIFY] [configuracion_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/configuracion_screen.dart)
*   Añadir botones para **Agregar Canal** y **Eliminar** (con validaciones de límites de acuerdo a `numPlanos`).
*   Mostrar un listado dinámico de canales configurados donde el usuario puede editar:
    *   `Tag` (ej: 1H, 2V).
    *   `Ángulo` (0° a 359°).
    *   `Peso / Ponderación` (campo de texto numérico o slider de 0.1 a 5.0).
*   Al cambiar `numPlanos` a 2: si hay menos de 2 canales, forzar la adición de canales hasta llegar a 2.

#### [MODIFY] [medicion_inicial_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/medicion_inicial_screen.dart)
*   Generar campos de entrada de forma dinámica según la longitud de `config.canales`.
*   Actualizar la previsualización del gráfico polar dinámicamente.

#### [MODIFY] [prueba_coeficientes_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/prueba_coeficientes_screen.dart)
*   Generar los campos de entrada de mediciones dinámicamente según `config.canales` para el paso de Plano 1 (y Plano 2 si aplica).
*   Eliminar el selector de "Sensor de cálculo" en 1 plano, ya que los mínimos cuadrados aprovechan la información de todos los canales activos automáticamente.

#### [MODIFY] [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart)
*   Visualizar y pasar al gráfico polar todas las vibraciones de los canales activos.
*   En el diálogo de "Nueva Iteración", generar dinámicamente los campos de vibración residual para los $M$ canales configurados.
*   Actualizar el guardado en el historial pasando la lista de amplitudes actuales.

---

### 4. Utilidades y Reportes

#### [MODIFY] [pdf_export.dart](file:///c:/Users/angel/balanceo_app/lib/utils/pdf_export.dart)
*   Actualizar la generación de tablas de configuración y mediciones para iterar sobre la lista de canales activos en lugar de usar referencias estáticas.
*   Actualizar la tabla de historial en el PDF para incluir tantas columnas de vibración como canales estén activos.

#### [MODIFY] [complejo.dart](file:///c:/Users/angel/balanceo_app/lib/models/complejo.dart)
*   Agregar getter `Complejo get conjugado => Complejo(real, -imaginario);`.

---

## 🧪 Plan de Verificación

### Pruebas Automatizadas
*   Añadir pruebas unitarias en `test/widget_test.dart` o un nuevo test para validar la lógica matemática de Moore-Penrose con 1, 2, 3 y 4 canales (con y sin pesos) comparando los resultados contra un cálculo manual o de referencia.
*   Ejecutar `flutter test` y `flutter analyze`.

### Pruebas Manuales
1.  **Configuración**: Crear un activo, agregar 3 canales (`1H`, `1V`, `2H`), configurar pesos (`1.5`, `1.0`, `1.5`).
2.  **Flujo 1 Plano / 3 Canales**: Completar el flujo y comprobar que calcula la masa correctora óptima minimizando la vibración residual en los 3 puntos.
3.  **Flujo 2 Planos / 4 Canales**: Realizar el flujo con 4 canales (`1H`, `1V`, `2H`, `2V`) y validar el cálculo de masas.
4.  **Retrocompatibilidad**: Abrir un activo antiguo y comprobar que se carga correctamente con sus 2 canales originales, y que el historial anterior se visualiza sin problemas.
