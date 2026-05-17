Actúa como un UX Architect y Analista Estático de Flutter. Tu objetivo es realizar una auditoría funcional de la navegación y la consistencia de la interfaz de usuario en el proyecto actual. No te enfoques en colores, tipografías ni estilos visuales; concéntrate puramente en la lógica estructural, usabilidad y flujo.

Por favor, escanea los archivos de la capa de presentación (views, screens, widgets) y genera un reporte estructurado bajo los siguientes criterios:

1. Árbol de Navegación Actual:
   - Identifica todas las pantallas existentes.
   - Mapea cómo se conectan entre sí (rastrea Navigator.push, context.go, Named Routes, etc.).
   - Detecta si existen pantallas "callejón sin salida" (vistas de las que no se puede regresar fácilmente).

2. Consistencia en la UI Genérica:
   - Analiza el uso de estructuras base (Scaffold, AppBar, BottomNavigationBar, Drawers). ¿Se usan los mismos patrones de diseño en todas las pantallas?
   - Verifica la ubicación y comportamiento de los botones de retorno (Back buttons). ¿El comportamiento es predecible?

3. Hallazgos de Fricción Funcional:
   - Detecta inconsistencias críticas en el flujo (ej. en una pantalla se usa un diálogo emergente para confirmar una acción y en otra se navega a una pantalla nueva para lo mismo).

Output Requerido:
Genera un reporte claro en Markdown titulado "Reporte de Estado de UX Funcional y Navegación". Organízalo con tablas y diagramas de flujo en formato texto o Mermaid.js para que el usuario pueda usarlo como mapa de ruta para refinar la experiencia en su próximo chat.