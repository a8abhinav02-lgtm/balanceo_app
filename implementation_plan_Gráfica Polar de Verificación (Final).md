# Plan de Implementación: Gráfica Polar de Verificación (Final) en PDF e Interfaz

Este plan detalla el diseño para permitir al usuario registrar los valores de vibración de verificación (finales) medidos después de instalar las masas correctoras calculadas, visualizar esta información en un cuarto gráfico polar de verificación en la app y exportarla en una nueva sección del reporte PDF.

---

## 🛠️ Objetivos
1. **Registrar Vibración de Verificación**: Permitir al usuario registrar la amplitud y fase final medida en cada canal tras colocar las masas correctoras.
2. **Cuarto Gráfico Polar (4/4)**: Añadir un gráfico polar final en la pantalla de resultados y en el reporte PDF que compare la vibración final con la inicial.
3. **Persistencia y Flujo**: Guardar estas lecturas de verificación en el estado persistente (`SharedPreferences`) y facilitar el traspaso al flujo de refinar iteraciones.

---

## 🙋 User Review Required

> [!IMPORTANT]
> Para proceder con la implementación, requerimos su confirmación o comentarios sobre las siguientes decisiones de diseño y preguntas abiertas.

### Preguntas Aclaratorias (Múltiples Iteraciones)

1. **¿Cómo se debe comportar la gráfica y los datos cuando hay múltiples iteraciones?**
   * **Opción A (Recomendada)**: El reporte PDF siempre muestra los detalles de la **iteración activa** actual. 
     * El gráfico 1/4 muestra la vibración con la que inició la iteración actual (que es el residual de la iteración anterior).
     * El gráfico 4/4 muestra la verificación final de la iteración actual.
     * Toda la historia completa (It. 1, It. 2, etc.) se detalla cuantitativamente en la tabla del "Historial de Iteraciones".
   * **Opción B**: Mantener un registro de gráficos finales de todas las iteraciones en el PDF. Esto incrementaría significativamente la longitud del PDF (2-3 páginas adicionales por iteración).

2. **Flujo de guardado y retrocompatibilidad del Historial**:
   Actualmente, el botón "Guardar" en la pantalla de resultados almacena en el historial el estado *inicial* de la iteración (puesto que el usuario no ha realizado aún la corrida de verificación). 
   * **Propuesta**: Permitir al usuario ingresar la vibración de verificación final en la pantalla de resultados. Al presionar "Guardar", se guardará el registro histórico con el valor de verificación final (residual real) asociado a esa iteración.
   * Si inicia una "Nueva Iteración (Refinar)", el sistema tomará automáticamente estos valores de verificación guardados como la vibración inicial de la siguiente corrida, evitando que el usuario deba digitarlos dos veces.

---

## 📐 Cambios Propuestos

### 1. Modelo de Datos y Proveedor (`BalanceoProvider`)

#### [MODIFY] [balanceo_provider.dart](file:///c:/Users/angel/balanceo_app/lib/providers/balanceo_provider.dart)
* Añadir la propiedad `List<Complejo>? vVerificacion` para almacenar las lecturas de verificación (post-corrección) de la iteración actual.
* Actualizar el método `nuevaIteracion` para que, si ya se registraron las lecturas de verificación, se usen automáticamente como punto de partida de la siguiente iteración.
* Actualizar los métodos de persistencia `saveToDisk` y `loadFromDisk` (JSON) para incluir `vVerificacion`.
* Asegurar compatibilidad en la carga de datos si el campo `vVerificacion` no existe en registros antiguos.

---

### 2. Interfaz de Usuario (`ResultadosScreen`)

#### [MODIFY] [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart)
* **Nueva Acción / Botón**: Añadir en la sección de "Acciones" un botón destacado: `"Registrar Vibración de Verificación"`.
  * Al hacer clic, se abrirá un diálogo idéntico al de Nueva Iteración para capturar la Amplitud y Fase obtenidas con el peso de corrección instalado.
* **Carrusel de Gráficos**: Añadir la cuarta página al carrusel: **VIBRACIÓN FINAL / VERIFICACIÓN**.
  * Mostrará en formato polar los vectores de vibración iniciales (en tono claro / semitransparente) y los vectores de vibración de verificación finales (en tono sólido), permitiendo apreciar visualmente la reducción del vector de vibración.
* **Optimización de Flujo**:
  * Si el usuario ya registró la verificación y presiona "Nueva Iteración (Refinar)", el diálogo se pre-poblará con dichos valores o se iniciará directamente usando `vVerificacion` para ahorrar clics.

---

### 3. Generación del Reporte PDF (`PdfExport`)

#### [MODIFY] [pdf_export.dart](file:///c:/Users/angel/balanceo_app/lib/utils/pdf_export.dart)
* Si `provider.vVerificacion` no es nulo, renderizar una gráfica polar adicional `imgVerif` (4/4).
* Esta gráfica mostrará los vectores de verificación en colores sólidos, comparados contra los vectores iniciales del rotor en colores claros (con opacidad).
* Agregar la sección **"7. Vibración de Verificación / Resultados Finales"** antes del Historial de Iteraciones, detallando el porcentaje de reducción de vibración por canal:
  $$\text{Reducción \%} = \frac{|V_{\text{inicial}}| - |V_{\text{verificación}}|}{|V_{\text{inicial}}|} \times 100$$
* Mostrar la gráfica `imgVerif` de tamaño 280x280 centrada en dicha sección.

---

## 🧪 Plan de Verificación

### Pruebas Automatizadas
* Actualizar la suite de pruebas para inicializar y verificar que la persistencia de `vVerificacion` funciona de manera íntegra.
* Validar que la exportación a PDF se compila correctamente e incluye la página/sección extra cuando `vVerificacion` está presente.

### Pruebas Manuales
1. **Flujo de Registro**: Configurar un activo, realizar lecturas iniciales y de prueba, calcular la masa correctora.
2. **Registrar Verificación**: Ingresar valores ficticios de verificación (ej. reducciones del 80% en vibración). Comprobar que aparece la 4ta pestaña en el carrusel de la app.
3. **Exportar PDF**: Generar el reporte PDF y verificar visualmente la inclusión de la sección "7. Vibración de Verificación / Resultados Finales" con su respectivo gráfico polar de vectores finales y la tabla de reducción.
4. **Nueva Iteración**: Presionar "Nueva Iteración" y validar que los datos se transfieren limpiamente como la nueva medición inicial.
