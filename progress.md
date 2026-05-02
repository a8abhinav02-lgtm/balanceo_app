Fase Actual: Implement (Branch: feature/evolucion-vectorial)

Objetivo Principal: Visualización evolutiva de vectores (Inicial vs Final) para mejor diagnóstico.

Research (Verdad del Código):
- `lib/screens/resultados_screen.dart`: Implementado `PageView` para comparar estados inicial y final.
- `lib/widgets/polar_plot.dart`: Leyenda corregida para mostrar siempre X e Y.

Plan (Compresión de Intención):
1. [x] [CREATE BRANCH] `feature/evolucion-vectorial`.
2. [x] [MODIFY] `lib/screens/resultados_screen.dart`:
   - Vista de "Estado Inicial" con vectores de diagnóstico originales.
   - Vista de "Estado Final" con resultados y masas.
   - Controles de navegación entre gráficos.
3. [x] [MODIFY] `lib/widgets/polar_plot.dart`: Leyenda unificada para X/Y.

Implement (Estado):
- [x] Gráfico dual evolutivo funcional.
- [x] Leyenda completa (X e Y siempre visibles).
- [x] Navegación intuitiva entre estados.
- [x] Análisis limpio.
