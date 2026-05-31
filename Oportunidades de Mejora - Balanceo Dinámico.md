# Oportunidades de Mejora: Balanceo Dinámico en Campo

Este documento recopila las oportunidades de mejora identificadas para la aplicación **Balanceo App**, basadas en las mejores prácticas de la industria descritas en el manual técnico [Balanceo Dinamico en Campo.md](file:///c:/Users/angel/balanceo_app/Balanceo%20Dinamico%20en%20Campo.md) y adaptadas a las realidades prácticas del trabajo en campo según la retroalimentación del especialista.

---

## 1. Validación de la "Regla del 30/30" (Corrida de Prueba)

### Fundamento Técnico (Sección 9.A)
Para que los coeficientes de influencia calculados sean numéricamente estables y precisos, la masa de prueba instalada en el rotor debe provocar un cambio significativo en el estado de vibración original del sistema. Si el cambio es muy pequeño, las variaciones de lectura debidas al ruido de los sensores falsearán los coeficientes calculados.
* **Regla Industrial:** La masa de prueba debe provocar un cambio de al menos **30% en la amplitud** de vibración o de **30° en el ángulo de fase**.

### Propuesta de Implementación
* Al ingresar las lecturas de la corrida con masa de prueba (V1), la aplicación comparará automáticamente el nuevo vector con el vector inicial (V0).
* Si el cambio en amplitud es menor al 30% ($\Delta A < 0.3$) y el cambio en fase es menor a 30° ($\Delta \theta < 30^\circ$), la app mostrará un banner de advertencia visual en color amarillo:
  > **[!WARNING]**
  > **Cambio de Señal Insuficiente**
  > La masa de prueba colocada no ha provocado un cambio significativo en la vibración (Amplitud: $\Delta A\%$, Fase: $\Delta \theta^\circ$). Los coeficientes de influencia calculados podrían no ser precisos. Se recomienda detener el rotor e incrementar la masa de prueba.

---

## 2. División Vectorial de Pesos (Weight Splitting)

### Fundamento Técnico (Sección 9.Q)
El cálculo matemático del balanceo entrega un peso corrector exacto en un ángulo cartesiano continuo (por ejemplo, 14.2 gramos a 112.5°). En la realidad, muchos rotores son de tipo **discreto** (cuentan con un número fijo de álabes, aspas o rayos) y no es posible colocar el contrapeso en el ángulo exacto porque coincide con un vacío.
* **Solución Vectorial:** Descomponer el vector del contrapeso teórico en dos vectores equivalentes ubicados en los dos álabes físicos adyacentes más cercanos.

### Propuesta de Implementación
* Agregar una pestaña o botón de acción en la pantalla de [resultados_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/resultados_screen.dart) llamado **"Dividir Pesos"**.
* El usuario ingresa:
  * El número total de álabes del rotor.
  * La posición del Álabe #1 (para alinearse con el sentido de giro).
* La app calcula automáticamente qué masas colocar y en qué número de álabes (ej: *"Colocar 8.5 gramos en el Álabe #4 y 6.2 gramos en el Álabe #5"*).

---

## 3. Combinación Vectorial de Masas de Refinamiento (Add Vectors)

### Fundamento Técnico (Sección 9.R)
Cuando se requiere más de una corrida de balanceo para alcanzar el límite objetivo de vibración (iteraciones de ajuste o trim), el técnico termina instalando un peso de corrección original más un peso de ajuste fino (Trim 1) en distintas posiciones del rotor. Acumular contrapesos dispersos en el rotor es una mala práctica de ingeniería porque añade masa innecesaria y estrés localizado.
* **Solución Vectorial:** Sumar vectorialmente todos los pesos añadidos en un mismo plano para consolidarlos en uno solo.

### Propuesta de Implementación
* En la sección del Historial de Iteraciones o en la pantalla de Resultados, habilitar una función para **"Consolidar Pesos"**.
* La app sumará los vectores de masa colocados durante el proceso y le indicará al técnico:
  > *"Retire todos los contrapesos instalados previamente en este plano. Instale un único contrapeso consolidado de **X gramos** en la posición **Y°**."*

---

## 4. Asistente Especializado para Rotores en Voladizo (Overhung)

### Fundamento Técnico (Sección 9.O)
Los rotores en voladizo (donde el disco impulsor o ventilador está suspendido fuera del vano de los rodamientos de soporte) tienen un comportamiento dinámico único. El rodamiento más cercano al disco es extremadamente sensible al desbalance estático, mientras que el rodamiento lejano responde de forma dominante al desbalance de acople.
* En estos rotores, el efecto cruzado (cross-effect) suele superar el 100%, lo que vuelve inestable el cálculo convencional de 2 planos.

### Propuesta de Implementación
* En [configuracion_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/configuracion_screen.dart), añadir un selector opcional: **"Rotor en voladizo (Overhung)"**.
* Si se activa, la aplicación guiará al operador a:
  * Realizar un balanceo estático inicial sobre el rodamiento cercano utilizando el Plano 1.
  * Si persiste la vibración en el rodamiento lejano, aplicar una corrección de acople (colocando pesos de igual magnitud desfasados $180^\circ$ en los planos 1 y 2) midiendo el impacto desde el rodamiento lejano.

---

## 5. Control de Calidad de Balanceo bajo Norma ISO 1940 (Opcional)

### Fundamento Técnico (Sección 11)
La norma ISO 1940 establece los grados de calidad de balanceo (G0.4, G1.0, G2.5, G6.3, G16, etc.) en función del tipo de máquina, su velocidad de rotación ($n$) y el peso del rotor ($W$). Define el desbalance residual admisible ($e_{per}$ en g-mm/kg o g-mm totales).

### Propuesta de Implementación
* En la pantalla de resultados, añadir un módulo opcional: **"Verificar norma ISO 1940"**.
* Si el técnico dispone de la información (peso del rotor y velocidad), la aplicación calculará el límite admisible.
* Si el balanceo final cae dentro del límite admisible, la aplicación mostrará una insignia verde: **"Cumple ISO G2.5"** y agregará la certificación oficial en el Reporte PDF.
* **Nota Importante de Campo:** Esta validación debe ser **100% opcional** y no obligatoria para avanzar, reconociendo que en muchos servicios rápidos en campo el peso o dimensiones exactas del rotor son desconocidas.

---

## 6. Lista de Verificación y Diagnóstico de Fase (Checklist)

### Fundamento Técnico (Sección 4)
Más del 50% de las máquinas que muestran alta vibración a 1X RPM en campo no tienen un problema de desbalance, sino desalineación, soltura mecánica o resonancia. Balancear una máquina con soltura o desalineación es inútil y frustrante para el técnico.

### Propuesta de Implementación
* Agregar un paso intermedio antes de la configuración del rotor que funcione como una **Guía de Diagnóstico**:
  * ¿La fase fluctúa o es inestable? (Indica soltura mecánica).
  * ¿El desfase de fase axial a través del acople es cercano a 180°? (Indica desalineación angular).
  * ¿El desfase radial H-V del rodamiento es cercano a 0° o 180° en lugar de 90°? (Indica excentricidad).
* **Impacto:** Protege el tiempo del técnico en campo, ayudándole a confirmar si realmente debe proceder a balancear o si debe recomendar alineación o apriete de pernos.

---

## 7. Manejo Adaptativo del Peso de Prueba Sugerido

### Consideración de Campo (Retroalimentación del Especialista)
En los servicios industriales rutinarios en campo, a menudo no se dispone de planos, dimensiones o el peso exacto del rotor. Por tanto, condicionar el inicio del balanceo al ingreso de estos datos geométricos entorpecerá el flujo de trabajo.

### Lógica de Diseño para la Aplicación
* En lugar de obligar al usuario a ingresar peso y radio del rotor para sugerir la masa de prueba:
  * El sistema ofrecerá un botón opcional **"Calcular Peso de Prueba Sugerido"**.
  * Si el usuario no tiene esos datos, puede omitir el cálculo y colocar directamente una masa estimada basada en su experiencia (ej. 10g o 20g), avanzando de forma inmediata.
  * Se pueden añadir recomendaciones empíricas rápidas sin necesidad de datos matemáticos complejos (ej: *"Para ventiladores de menos de 1 metro de diámetro, se sugiere comenzar con masas entre 5 y 20 gramos"*).
