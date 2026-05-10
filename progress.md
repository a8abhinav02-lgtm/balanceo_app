Fase Actual: Finalizada (Rama: feature/dual-sensor-measurement)

Objetivo Principal: Refactorización Dual-Sensor y Exportación PDF Industrial.

Research (Verdad del Código):
- `lib/providers/balanceo_provider.dart`: Implementada lógica mandatoria de doble sensor (X/Y) e iteraciones de refinamiento persistentes.
- `lib/utils/pdf_export.dart`: Sistema de reporte completo con captura de gráficas polares (Helvetica/GoogleFonts fallback), historial de iteraciones y soporte para compartir/guardar nativo.
- `lib/widgets/polar_plot.dart`: Función de renderizado a bytes para exportación de imágenes.

Plan (Compresión de Intención):
1. [x] [CREATE BRANCH] `feature/dual-sensor-measurement`.
2. [x] [REFACTOR] Sistema dual mandatorio (X e Y siempre presentes).
3. [x] [MODIFY] Lógica de iteraciones: Preservación de coeficientes H y actualización de residuales.
4. [x] [NEW] Exportación PDF: Reporte consolidado con datos técnicos y gráficas.
5. [x] [FIX] PDF: Solución a errores de fuentes y rutas de guardado en Android (SAF).
6. [x] [IMPLEMENT] Compartir nativo (WhatsApp, Email) y Guardar en Descargas.

Implement (Estado):
- [x] Flujo de balanceo dual completo y probado en dispositivo físico.
- [x] Reporte PDF profesional con 8 secciones y gráficas evolutivas.
- [x] Funciones de guardado y compartir 100% operativas en Android.
- [x] Código limpio y sincronizado.
