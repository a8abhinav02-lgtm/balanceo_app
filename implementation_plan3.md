# Paso 3: División Vectorial de Pesos (Weight Splitting)

El objetivo de este paso es permitir la descomposición vectorial de un peso corrector teórico en dos pesos equivalentes ubicados en los dos álabes físicos adyacentes más cercanos. 

## User Review Required

> [!IMPORTANT]
> **Opcionalidad del Montaje:**
> * La división de pesos **no sustituye la sugerencia directa del álabe más cercano** (que se mantiene visible por defecto en `ResultadoCard`).
> * La división vectorial se presenta como una **herramienta opcional** para el analista, ya que colocar dos masas puede duplicar el esfuerzo físico de montaje. El analista decidirá si prefiere colocar un único peso en el álabe más cercano o dividirlo en dos álabes adyacentes.

---

## Proposed Changes

### Componente: Backend / Lógica de Negocio
#### [MODIFY] [balanceo_provider.dart](file:///c:/Users/angel/balanceo_app/lib/providers/balanceo_provider.dart)
* **Importación:** Añadir `import 'dart:math' as math;` al inicio del archivo.
* **Función `calcularDivisionPesos`:** Implementar la lógica matemática descrita para encontrar los índices de los dos álabes adyacentes que encierran el ángulo teórico, calcular las diferencias angulares y resolver la descomposición mediante Cramer. Debe admitir overrides opcionales para permitir simulaciones y pruebas dinámicas en pantalla.

---

### Componente: Interfaz de Usuario (UX)
#### [MODIFY] [resultado_card.dart](file:///c:/Users/angel/balanceo_app/lib/widgets/resultado_card.dart)
* Se preserva el indicador actual de: **`Álabe recomendado: N° X`** (obtenido con `sugerirAlabe`, que es el más cercano y la opción primaria para ahorrar trabajo de montaje).
* Si el rotor actual es discreto y tiene álabes configurados, añadir un botón de texto discreto **"Ver división vectorial opcional"** o similar que expanda la tarjeta o muestre una ventana emergente para consultar los pesos divididos si la colocación en el álabe recomendado no fuera factible.

#### [MODIFY] [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart)
* Agregar un botón de acción en la sección de "Acciones" titulado **"Dividir Pesos (Simulación/Ajuste)"**.
* Al presionarlo, se abrirá un diálogo (`_AsistenteDivisionPesosDialog`):
  * Mostrará las masas teóricas resultantes y sus descomposiciones vectoriales opcionales.
  * Permitirá al usuario editar interactivamente sobre este diálogo temporal:
    * El número de álabes.
    * El ángulo de referencia del Álabe #1.
    * El sentido de numeración (horaria / antihoraria).
  * La app recalculará y mostrará en tiempo real la división resultante para ambos planos conforme el usuario altera estos parámetros de simulación.

---

## Verification Plan

### Automated Tests
* Agregar un set de pruebas en [navigation_test.dart](file:///c:/Users/angel/balanceo_app/test/navigation_test.dart) o un nuevo archivo de pruebas widget para validar:
  * El cálculo correcto de la división de pesos para casos conocidos (ej: descompuesto a 45° entre álabes a 0° y 90°).
  * La correcta visualización de las masas divididas en `ResultadoCard` y en el diálogo interactivo de simulación.
* Ejecutar:
  ```bash
  flutter test
  ```

### Manual Verification
1. Configurar un rotor discreto con 4 álabes, referencia de Álabe 1 a 0°, sentido antihorario.
2. Ingresar lecturas tales que la masa de corrección calculada sea $10\text{ g}$ a $45^\circ$.
3. Verificar que la app muestre como álabe recomendado el Álabe 1 o 2 (el más cercano).
4. Activar la opción de división vectorial en la tarjeta o simulación y verificar que muestre colocar $7.07\text{ g}$ en el Álabe 1 ($0^\circ$) y $7.07\text{ g}$ en el Álabe 2 ($90^\circ$).
5. Abrir la herramienta de simulación de división de pesos, cambiar a 8 álabes, y verificar que recalcule dinámicamente las posiciones y masas.
