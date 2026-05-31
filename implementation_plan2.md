# Paso 2: Validación de la Regla del "30/30" (Corrida de Prueba)

El objetivo de este paso es implementar la regla de calidad industrial de vibración que indica que la masa de prueba debe provocar un cambio de al menos **30% en la amplitud** de vibración o de **30° en el ángulo de fase** con respecto a la vibración inicial ($V_0$). Si el cambio es menor en ambos rubros, el cálculo de los coeficientes de influencia podría verse falseado por ruido de medición.

## User Review Required

> [!IMPORTANT]
> **Criterio de Validación:**
> * La alerta se activará de forma **individual por canal** si tanto el cambio de amplitud es menor al 30% como el de fase es menor a 30° ($\Delta A < 30\%$ AND $\Delta \theta < 30^\circ$).
> * Si **todos los canales** ingresados para la corrida de prueba actual no superan el criterio, se mostrará una advertencia global amarilla sugiriendo detener el rotor e incrementar la masa de prueba.
> * Las advertencias se calculan en tiempo real mientras el técnico escribe las lecturas, sin bloquear el avance del flujo si decide continuar de todos modos (es una recomendación técnica, no un bloqueo).

## Open Questions

*Ninguna. La lógica de negocio está completamente definida según el marco teórico.*

## Proposed Changes

### Componente: Pantalla de Prueba de Coeficientes

---

#### [MODIFY] [prueba_coeficientes_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/prueba_coeficientes_screen.dart)
* **Listeners en Controladores:**
  * Agregar listeners en `initState` a los controladores de amplitud y fase de las corridas de prueba (`_v1AmpControllers`, `_v1FaseControllers`, `_v2AmpControllers`, `_v2FaseControllers`) para re-evaluar la interfaz de forma reactiva a medida que el usuario escribe.
  * Liberar adecuadamente los listeners en `dispose`.
* **Cálculo del Cambio Vectorial:**
  * Implementar funciones auxiliares para determinar el porcentaje de cambio en amplitud y la distancia angular más corta en fase con respecto a las lecturas originales ($V_0$ cargados de `provider.v0`).
* **Indicadores Individuales por Canal:**
  * Dentro de cada `Card` de canal de medición, mostrar una sección de resultados en tiempo real:
    * Si están vacíos, no muestra nada.
    * Si están completos, calcula e imprime: `Cambio: ΔAmp: X.X% | ΔFase: Y.Y°`.
    * Si pasa la regla (al menos uno $\ge 30$), muestra un distintivo verde: `Señal OK`.
    * Si falla la regla (ambos $< 30$), muestra un distintivo naranja: `Señal Insuficiente`.
* **Banner de Advertencia Global:**
  * Agregar un banner superior o inferior de advertencia (color amarillo) si **todos los canales activos** registran cambio de señal insuficiente.

## Verification Plan

### Automated Tests
* Escribir pruebas unitarias/de widget en [navigation_test.dart](file:///c:/Users/angel/balanceo_app/test/navigation_test.dart) o un nuevo archivo de test que valide:
  * El cálculo correcto de las variaciones (amplitud y fase).
  * La aparición del distintivo de advertencia por canal.
  * La aparición del banner global de advertencia.
  * El comando a ejecutar es:
    ```bash
    flutter test
    ```

### Manual Verification
1. Iniciar un activo y establecer mediciones iniciales (p. ej., `10 µm` a `120°`).
2. En la pantalla de corrida de prueba, ingresar valores que provoquen cambio insuficiente (p. ej., `11 µm` a `130°` $\implies \Delta A = 10\%$, $\Delta \theta = 10^\circ$). Verificar que aparezca el distintivo "Señal Insuficiente" y el banner global.
3. Cambiar los valores de entrada para superar el umbral (p. ej., `15 µm` a `120°` o `10 µm` a `160°`). Verificar que el banner global desaparezca y cambie a "Señal OK".
