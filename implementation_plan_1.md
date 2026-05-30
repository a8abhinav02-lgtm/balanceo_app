# Plan de Implementación: Mejoras de Balanceo Dinámico (Paso 1)

Este plan de implementación detalla el primer paso para incorporar las mejoras sugeridas en [Oportunidades de Mejora - Balanceo Dinámico.md](file:///c:/Users/angel/balanceo_app/Oportunidades%20de%20Mejora%20-%20Balanceo%20Din%C3%A1mico.md). 

Siguiendo la metodología de trabajo acordada, implementaremos las mejoras **paso a paso**. Comenzaremos con el **Paso 1: Manejo Adaptativo del Peso de Prueba Sugerido**.

---

## Propósito del Paso 1
Permitir que la aplicación calcule y sugiera una masa de prueba segura basada en parámetros físicos del rotor (peso, radio, RPM) si estos están disponibles, manteniendo la flexibilidad de omitir este cálculo o usar valores empíricos si la información no está disponible en campo.

---

## Cambios Propuestos

### Componente: Modelo de Datos

#### [MODIFY] [rotor_config.dart](file:///c:/Users/angel/balanceo_app/lib/models/rotor_config.dart)
* Agregar los siguientes campos opcionales (nullable) a la clase `RotorConfig` para soportar tanto el cálculo de la masa de prueba como el posterior control de calidad ISO 1940:
  * `pesoRotor` (double?): Peso del rotor en kg.
  * `velocidadRPM` (double?): Velocidad nominal del rotor en RPM.
  * `radioPeso` (double?): Radio de colocación de la masa en mm.
* Actualizar el constructor, `copyWith`, `toJson` y `fromJson` de `RotorConfig` para serializar y deserializar estos nuevos campos correctamente.

---

### Componente: Interfaz de Usuario (Configuración del Rotor)

#### [MODIFY] [configuracion_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/configuracion_screen.dart)
* Agregar campos de texto opcionales en el formulario bajo una sección titulada **"Datos Dinámicos del Rotor (Opcionales)"**:
  * Peso del rotor (kg)
  * Velocidad de rotación (RPM)
  * Radio de masa (mm)
* Modificar el guardado de la configuración para incluir estos valores nullable en `RotorConfig`.
* Asegurar que no sean campos requeridos (validación flexible) para no obstaculizar al operador cuando no cuente con estos datos.

---

### Componente: Asistente de Masa de Prueba

#### [MODIFY] [prueba_coeficientes_screen.dart](file:///c:/Users/angel/balanceo_app/lib/screens/prueba_coeficientes_screen.dart)
* En la sección "Peso de prueba", añadir un botón de ayuda/asistente llamado **"Calcular Masa Sugerida"** junto al campo de "Masa de prueba (g)".
* Al presionar este botón, se abrirá un diálogo (`showDialog`):
  * Si los campos de peso del rotor, velocidad y radio ya fueron configurados en el paso anterior, la app mostrará el cálculo matemático de la masa sugerida:
    $$m_{\text{g}} = 1.79 \times 10^8 \cdot \frac{W_{\text{kg}}}{r_{\text{mm}} \cdot n^2}$$
    y ofrecerá un botón para *"Usar este valor"*, rellenando automáticamente el campo de masa.
  * Si los datos no están disponibles (son nulos), el diálogo presentará:
    * Un formulario rápido para ingresarlos en el momento.
    * O una lista de **Recomendaciones Empíricas** rápidas (ej. *"Para rotores pequeños < 1 metro de diámetro, se sugiere de 5g a 15g. Para rotores medianos, de 15g a 50g"*).
* Si el usuario decide cancelar o prefiere no usar el asistente, el comportamiento se mantendrá idéntico al actual, permitiéndole escribir cualquier masa manualmente.

---

## Plan de Verificación

### Pruebas Unitarias / Aritméticas
* Verificar el cálculo de la fórmula para diferentes valores estándar:
  * Ejemplo del libro: $W = 453.6\text{ kg}$, $r = 304.8\text{ mm}$, $n = 1800\text{ RPM} \implies m \approx 82.2\text{ g}$.
  * Ventilador mediano típico: $W = 100\text{ kg}$, $r = 250\text{ mm}$, $n = 1500\text{ RPM} \implies m \approx 31.8\text{ g}$.
  * Rotor pequeño: $W = 10\text{ kg}$, $r = 100\text{ mm}$, $n = 3600\text{ RPM} \implies m \approx 1.38\text{ g}$.

### Pruebas de Interfaz (Manuales)
1. Iniciar la configuración de un rotor nuevo e ingresar los parámetros opcionales. Avanzar hasta la pantalla de Prueba de Coeficientes y presionar "Calcular Masa Sugerida". Validar que se calcule y rellene el valor correcto.
2. Iniciar la configuración omitiendo los parámetros opcionales. En la pantalla de Prueba de Coeficientes, verificar que al presionar el asistente se muestren las recomendaciones empíricas o la posibilidad de ingresarlos al vuelo.
3. Verificar que el flujo continúe funcionando correctamente si el usuario escribe la masa de prueba manualmente sin usar el asistente.
