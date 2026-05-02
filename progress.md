Fase Actual: Implement (Rama: feature/evolucion-vectorial)

Objetivo Principal: Evolución Vectorial y Precisión Técnica Industrial.

Research (Verdad del Código):
- `lib/widgets/polar_plot.dart`: Corregida flecha GIRO, dirección de puntas de flecha y layout adaptativo.
- `lib/providers/balanceo_provider.dart`: Implementada lógica de sugerencia de álabes por distancia angular mínima y almacenamiento de vectores de prueba ($V_1$).
- `lib/screens/resultados_screen.dart`: Implementado carrusel de 3-4 etapas (Inicial, Prueba P1, Prueba P2, Final).

Plan (Compresión de Intención):
1. [x] [CREATE BRANCH] `feature/evolucion-vectorial`.
2. [x] [MODIFY] `lib/screens/resultados_screen.dart`: Visualización comparativa de diagnóstico vs. prueba vs. solución.
3. [x] [FIX] UI: Eliminar `RenderFlex overflow` en la pantalla de resultados.
4. [x] [FIX] Lógica: Sincronizar flecha de GIRO con configuración y corregir geometría de flechas de vectores.
5. [x] [FIX] Matemáticas: Sugerencia de álabes basada en posición real y sentido de numeración.
6. [x] [DOCS] Sincronizar `guia.md` con convenciones de contra-rotación.

Implement (Estado):
- [x] Gráfico evolutivo funcional y preciso.
- [x] Errores de visualización resueltos.
- [x] Sugerencia de álabes exacta según configuración de rotor.
- [x] Rama consolidada y lista para merge.
