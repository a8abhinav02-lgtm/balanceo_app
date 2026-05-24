# Plan de Implementación: Flujo de Confirmación y Estructura Dinámica de Gráficas en PDF y Pantalla de Resultados

Este plan propone ajustar el comportamiento del diálogo de confirmación de fin de balanceo, la comparación de vibración inicial vs. final en el gráfico de verificación, y la estructura/numeración dinámica de las gráficas polares en el reporte PDF y en la pantalla de resultados.

---

## 🙋 Preguntas Aclaratorias / Decisiones a Confirmar
> [!NOTE]
> De acuerdo con las respuestas provistas en tu solicitud:
> 1. **Momento del Diálogo**: Se mantiene la opción de mostrar el diálogo de confirmación tras registrar la vibración residual (acción "Registrar Vibración Residual" -> Confirmación para Concluir o Refinar).
> 2. **Gráfica Final/Residual**: Mostrará siempre la comparación entre la **Vibración Inicial Original (Corrida 1)** contra la **Vibración Final Concluida**.
> 3. **Estructura y Cantidad**: La gráfica final/residual de verificación solo se mostrará en el PDF una vez que el usuario declare formalmente que el balanceo ha concluido. La numeración de las gráficas será dinámica en todo momento para reflejar adecuadamente la cantidad total de gráficas renderizadas.

---

## 📐 Cambios Propuestos

### 1. Pantalla de Resultados (`ResultadosScreen`)
#### [MODIFY] [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart)
*   **Comparación Inicial vs. Final en la UI (Página de Verificación/Resultados Finales del carrusel)**:
    *   Cambiar la referencia de la vibración inicial en esta pestaña. Actualmente usa `provider.v0` (que es el residual de la iteración inmediatamente anterior). Cambiarlo para usar `provider.v0Original ?? provider.v0` para asegurar que compare la vibración con la que arrancó el sistema originalmente (Corrida 1).
    *   Actualizar las etiquetas en el gráfico para que muestren `(inicial)` y `(final)` en lugar de `(Ini.)` y `(Verif.)`.

### 2. Generación de Reporte PDF (`PdfExport`)
#### [MODIFY] [pdf_export.dart](file:///c:/Users/angel/balanceo_app/lib/utils/pdf_export.dart)
*   **Gráfica Final/Residual**:
    *   Asegurar que `imgVerif` (sección 7) solo se genere y renderice si `provider.vVerificacion != null` (es decir, una vez concluido el proceso).
    *   Actualizar los nombres de las etiquetas en `imgVerif` a `'$tag (inicial)'` y `'$tag (final)'` para que coincidan con la interfaz de usuario.
*   **Sección 7 (Vibración de Verificación / Resultados Finales)**:
    *   Renombrar la fila "Vibración Final (Verif.)" a "Vibración Final (concluida)" o "Vibración Final" para mejor legibilidad del reporte.
*   **Numeración Dinámica**:
    *   Validar que la numeración dinámica basada en `totalGraficos` asigne de manera secuencial los índices corretos a cada gráfico (`idxIni`, `idxP1`, `idxFin`, `idxVerif`) sin saltos de numeración ni índices fijos en texto.

---

## 🧪 Plan de Verificación

### Pruebas Automatizadas
*   Ejecutar `flutter test` para validar que no se rompen pruebas unitarias existentes tras la modificación.

### Pruebas Manuales
1.  **Iterando (Sin Concluir)**:
    *   Iniciar un proceso de balanceo.
    *   Generar un PDF antes de registrar la vibración residual final.
    *   Comprobar que el reporte tiene 3 gráficos en total (1: Inicial/Residual, 2: Prueba, 3: Masas Correctoras) y la numeración muestra "de 3" (ej: "Gráfica 3 de 3").
2.  **Concluyendo el Balanceo**:
    *   Hacer clic en "Registrar Vibración Residual", rellenar los campos y seleccionar "Concluir Balanceo".
    *   Verificar que en la pantalla de resultados aparece la pestaña de "VIBRACIÓN FINAL / VERIFICACIÓN" comparando los vectores iniciales originales (translúcidos) contra los vectores finales (sólidos).
    *   Generar el reporte PDF y verificar que ahora tiene 4 gráficos en total (con numeración "de 4", ej: "Gráfica 4 de 4: Resultados Finales (Inicial vs. Final)").
    *   Comprobar que las etiquetas del 4to gráfico y la tabla muestran claramente "Vibración Inicial" vs. "Vibración Final".
