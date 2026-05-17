# Plan de Implementación: UI/UX Industrial y Accesibilidad (WCAG 2.2)

Este plan detalla los pasos para migrar la aplicación a una estética más industrial y profesional, resolviendo simultáneamente las brechas de accesibilidad identificadas en nuestro análisis previo.

## ⚠️ User Review Required

Por favor revisa la **nueva paleta de colores industrial** propuesta antes de proceder. 

**Propuesta de Paleta Industrial:**
*   **Color Primario (AppBars, Cabeceras):** Gris Pizarra Oscuro (`Colors.blueGrey.shade900` o `#263238`). Transmite robustez, maquinaria pesada y profesionalidad, eliminando el tono "celeste genérico".
*   **Color de Acento (Botones, FAB, Destacados):** Ámbar Industrial (`Colors.amber.shade700` o `#FFA000`). Ofrece un contraste excelente y evoca las señales de seguridad típicas del sector industrial.
*   **Color de Fondo (Pantallas):** Gris muy claro (`Colors.grey.shade50`) para mantener máxima legibilidad en formularios.
*   *Nota:* Se mantendrán intactos los colores de alto contraste recién definidos para los vectores (Azul Eléctrico y Rojo Rubí).

¿Estás de acuerdo con esta paleta o prefieres otra combinación (ej. Azul Marino Oscuro / Amarillo)?

## Cambios Propuestos

### 1. Refactorización Cromática (Estética Industrial)
- **[MODIFICAR]** `lib/main.dart`: Actualizar `ThemeData` para usar el nuevo esquema de colores (`colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, primary: Colors.blueGrey.shade900, secondary: Colors.amber.shade700)`).
- **[MODIFICAR]** Todas las pantallas (`configuracion_screen.dart`, `medicion_inicial_screen.dart`, `prueba_coeficientes_screen.dart`, `resultados_screen.dart`, `historial_screen.dart`, `guia_screen.dart`): Reemplazar los usos directos de `backgroundColor: Colors.blue` por el color dinámico del tema o explícitamente `Colors.blueGrey.shade900`. Reemplazar textos estáticos marcados con `Colors.blue`.

### 2. Mejoras de Accesibilidad Perceptible y Comprensible (WCAG 1.4.3 & 3.3.4)
- **[MODIFICAR]** `configuracion_screen.dart`: Aumentar el contraste de los textos secundarios (ej. `Colors.grey` -> `Colors.grey.shade700`).
- **[MODIFICAR]** Todos los formularios numéricos de fase (ángulos): Implementar un `TextInputFormatter` personalizado en tiempo real para evitar que el usuario pueda escribir números mayores a 359.9° o valores negativos. Esto previene errores de captura de datos de raíz (WCAG Prevención de Errores).
- **[MODIFICAR]** `lib/widgets/polar_plot.dart`: Envolver el `CustomPaint` en un widget `Semantics` que incluya un `label` genérico anunciando que es un "Gráfico polar de análisis vibracional".

### 3. Mejoras de Accesibilidad Operable (WCAG 2.5.1)
- **[MODIFICAR]** `resultados_screen.dart`: El carrusel de resultados (`PageView`) exige el gesto de arrastrar (swipe). Se añadirán dos botones en la barra inferior (BottomNavigationBar o una fila inferior): **"Anterior"** y **"Siguiente"** para que pueda ser navegado con toques simples (taps).
- **[MODIFICAR]** `configuracion_screen.dart`: Asegurar que los botones segmentados utilicen las propiedades adecuadas para accesibilidad de teclado o voz.

## Plan de Verificación
### Pruebas Manuales
1. Ejecutar `flutter analyze` para verificar la limpieza del código tras los cambios extensivos en la UI.
2. Comprobar que los campos de "Ángulo" no permiten ingresar `360` ni `-5`.
3. Navegar la pantalla de resultados interactuando únicamente con los nuevos botones Anterior/Siguiente.
4. Visualizar las pantallas para confirmar que el nuevo tono "Gris Pizarra" y "Ámbar" reemplaza completamente al azul inicial.
