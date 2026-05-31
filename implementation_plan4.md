# Paso 4: Combinación Vectorial de Masas de Refinamiento (Add Vectors)

El objetivo de este paso es permitir la consolidación vectorial de todos los contrapesos instalados previamente en el rotor junto con el nuevo contrapeso recomendado para este plano, reemplazándolos por una única masa consolidada equivalente. Esto evita la acumulación de masas dispersas y estrés dinámico localizado.

## Lógica Matemática de Consolidación

1. **Masa Acumulada Previa ($\vec{M}_{\text{acumulada}}$):**
   Es la suma vectorial de todas las masas reales instaladas en iteraciones anteriores en el rotor para un plano dado. Ya está implementada en el proveedor mediante:
   $$\vec{M}_{\text{acumulada}} = \sum_{i=1}^{N-1} \vec{M}_{\text{real}, i}$$

2. **Nueva Corrección Recomendada ($\vec{M}_{\text{nueva}}$):**
   Es el contrapeso calculado para la iteración actual para corregir el desbalance residual.

3. **Masa Consolidada Teórica ($\vec{M}_{\text{consolidada}}$):**
   Es la suma vectorial directa de las masas previas y la nueva corrección:
   $$\vec{M}_{\text{consolidada}} = \vec{M}_{\text{acumulada}} + \vec{M}_{\text{nueva}}$$
   
   La instrucción para el técnico es: **retirar todas las masas instaladas previamente** y colocar una **única masa** de magnitud $|\vec{M}_{\text{consolidada}}|$ en el ángulo $\angle \vec{M}_{\text{consolidada}}$.

4. **Registro de Consolidación Real Personalizada:**
   Si el técnico instala un contrapeso consolidado real $\vec{M}_{\text{consolidada\_real}}$ (que puede diferir del teórico por restricciones de montaje), la masa real neta de la corrida actual que debe registrarse en el historial es:
   $$\vec{M}_{\text{real}, N} = \vec{M}_{\text{consolidada\_real}} - \vec{M}_{\text{acumulada}}$$
   De este modo, al sumar el historial, la nueva masa acumulada será exactamente $\vec{M}_{\text{consolidada\_real}}$.

---

## Cambios Propuestos

### Componente: Backend / Lógica de Negocio
#### [MODIFY] [balanceo_provider.dart](file:///c:/Users/angel/balanceo_app/lib/providers/balanceo_provider.dart)
* Implementar un método para registrar la masa instalada a partir de un valor consolidado:
  ```dart
  void registrarMasaConsolidada({
    required int plano,
    required double modulo,
    required double anguloAjustado,
  }) { ... }
  ```
  Este método calculará el vector neto $\vec{M}_{\text{real}} = \vec{M}_{\text{consolidada\_real}} - \vec{M}_{\text{acumulada}}$ (ajustando la dirección del ángulo según el sentido de giro) y lo asignará a `masaRealInstalada1` o `masaRealInstalada2`.

---

### Componente: Interfaz de Usuario (UX)
#### [MODIFY] [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart)
1. **Nueva Tarjeta de Consolidación:**
   Si `esRefinamiento` (iteración > 1) es verdadero, se agregará una nueva tarjeta destacada: **"Consolidación Vectorial de Contrapesos"**:
   * Muestra la masa consolidada teórica para cada plano: `X.X g @ Y.Y°`.
   * Si el rotor es discreto, muestra el álabe físico equivalente: `(Álabe N° Z)`.
   * Incluye instrucciones claras: *"Retire todos los contrapesos anteriores en este plano e instale un único peso consolidado..."*.
   * Proporciona un botón de acción **"Confirmar Consolidación"** que registra el vector consolidado teórico en el proveedor y lo resalta.

2. **División de Masa Consolidada para Rotores Discretos:**
   Si el rotor es discreto, se agregará una sección colapsable `"Ver división de masa consolidada"` dentro de la tarjeta de consolidación.
   * Mostrará los dos álabes adyacentes y sus pesos correspondientes para montar la masa consolidada de forma dividida.
   * Contará con sus propios controles de simulación inline (número de álabes, referencia de ángulo y checkbox CW) que calculan la división sobre la masa consolidada.
   * Incluirá un botón **"Instalar Dividido Consolidado"** que registra el vector sumado de la división simulada como la masa instalada.

3. **Edición Adaptativa en el Diálogo "Ajustar Peso Real":**
   En `_mostrarDialogoAjustarPesoReal`, si es una iteración de refinamiento, se añadirá una pestaña o un switch: **"Registrar peso como consolidado"**.
   * Al estar activo, los campos de entrada representarán la masa total consolidada que quedó en el rotor (en lugar del incremento neto).
   * Al aceptar, la app calculará automáticamente la diferencia neta y la registrará en el proveedor de manera transparente.
   * Si el rotor es discreto, también soportará registrar por división de la masa consolidada física.

---

## Plan de Verificación

### Pruebas Automatizadas
* Agregar pruebas en [navigation_test.dart](file:///c:/Users/angel/balanceo_app/test/navigation_test.dart) para verificar:
  * El cálculo correcto de la masa consolidada.
  * La visualización y registro de la masa consolidada desde la tarjeta.
  * El registro correcto de pesos consolidados personalizados en el diálogo "Ajustar Peso Real".
  * Que el flujo de refinamiento y coeficientes de influencia continúe de forma íntegra tras la consolidación.

### Verificación Manual
1. Iniciar un balanceo, realizar la primera iteración de prueba para calcular los coeficientes de influencia.
2. Avanzar a la Iteración 2 (Refinamiento). La vibración residual será la nueva $V_0$.
3. Ingresar lecturas y presionar Calcular. Se mostrará el nuevo peso corrector recomendado de, por ejemplo, $5\text{ g}$.
4. Validar que aparezca la tarjeta de Consolidación mostrando la suma vectorial de la masa de la corrida 1 y la corrida 2.
5. Hacer clic en "Confirmar Consolidación" y verificar que la "Masa Real Instalada" del Plano 1 refleje el cambio de manera consistente.
6. Abrir "Ajustar Peso Real", seleccionar "Registrar como consolidado", ingresar un valor personalizado y verificar que la masa neta se registre correctamente.
