# Reporte de Revisión de UI: Hacia un Diseño Industrial Profesional

He analizado la base de tu interfaz actual y he preparado este informe enfocado en llevar tu aplicación de **Balanceo por Coeficientes** a un nivel mucho más profesional, moderno y alineado con los estándares industriales.

## Estado Actual de la UI

Actualmente estás utilizando **Material 3** en Flutter con un `ColorScheme` basado en `Colors.blueGrey` (Gris azulado) y `Colors.teal.shade600` (Verde azulado). Es un buen punto de partida que transmite cierta seriedad, pero se puede sentir genérico ("por defecto" de Flutter). Las pantallas actuales (`ConfiguracionScreen`, `MedicionInicialScreen`, `ResultadosScreen`) cumplen funcionalmente pero carecen de esa estética "premium industrial" y jerarquía visual que los usuarios de herramientas técnicas esperan.

## Recomendaciones de Diseño Profesional

Para transformar la experiencia, te sugiero aplicar los siguientes principios en tu rediseño:

### 1. Paleta de Colores (Estética Industrial Moderna)
* **Primario:** `BlueGrey.shade900` (#263238) - Excelente elección para el tema principal. Da peso y profesionalidad.
* **Acento (Call to Action):** Cambiar de `Teal` a **Ámbar/Naranja Industrial** (`Colors.amber.shade700` o `#F57C00`). Este color es el estándar universal en la industria pesada para advertencias y acciones importantes, ofreciendo un contraste excelente (WCAG 2.2) sobre fondos oscuros.
* **Fondos:** Usa fondos gris muy claro (como el actual `grey.shade50`) pero envuelve los formularios y gráficos en tarjetas blancas (`Colors.white`) con **sombras muy sutiles** (`boxShadow` con opacidad del 5%) para crear profundidad.
* **Modo Oscuro (Opcional pero muy recomendado):** En entornos de planta industrial, un modo oscuro puro (fondos `#121212` con tarjetas `#1E1E1E` y texto blanco) reduce la fatiga visual.

### 2. Jerarquía y Tipografía
* **Fuentes Modernas:** No uses la fuente por defecto. Integra fuentes de Google Fonts como **Inter**, **Roboto Flex**, o **Outfit**. Éstas tienen una excelente legibilidad para datos numéricos y tablas.
* **Tamaños:** Asegúrate de que los valores de medición (vibración, ángulo, RPM) tengan una tipografía grande (ej. `fontSize: 32`, `fontWeight: FontWeight.bold`) mientras que sus etiquetas sean pequeñas y de color secundario (ej. `grey.shade600`).

### 3. Componentes Visuales (Widgets)
* **Inputs (TextFormFields):** Evita que floten. Usa `OutlineInputBorder` con bordes ligeramente redondeados (`borderRadius: BorderRadius.circular(8)`). Usa color de relleno gris claro en los inputs.
* **Tarjetas de Datos (Data Cards):** Los resultados de la medición inicial y final deben presentarse en "Dashboards". En lugar de texto plano, usa tarjetas donde destaquen íconos representativos (ej. un ícono de un rotor o de vibración) junto al valor numérico.
* **Botones:** Usa botones grandes, expansivos (`width: double.infinity`), con las esquinas ligeramente redondeadas, elevación nula (flat) y en el color de acento Ámbar.

### 4. Gráficos de Vectores (PolarPlot)
* **Integración Visual:** Los gráficos polares para mostrar las fases deben integrarse fluidamente. Usa un fondo transparente o que coincida exactamente con el de la tarjeta, y utiliza colores vibrantes (Rojo para la fase inicial, Verde para la fase corregida) para dibujar los vectores.

---

> [!TIP]
> **Generación de UI con Stitch**
> Le he solicitado a **Stitch** que empiece a generar prototipos de este nuevo diseño profesional. Una vez generados, podrás verlos en tus proyectos de Stitch. ¡Te ayudarán a tener una referencia visual directa para codificar en Flutter!
