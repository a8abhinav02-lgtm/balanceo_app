Evaluación Técnica: Modelo Matemático de Balanceo
Esta evaluación analiza la integridad de los cálculos implementados en BalanceoProvider.dart y Complejo.dart, comparándolos con los estándares de la industria (ISO 21940).

1. Validación del Método Matemático
La aplicación implementa el Método de Coeficientes de Influencia, que es el estándar de facto para el balanceo dinámico de rotores rígidos en campo.

Balanceo en 1 Plano
Fórmula de Coeficiente ($\vec{\alpha}$): $\vec{\alpha} = \frac{\vec{V}_1 - \vec{V}_0}{\vec{M}_t}$
Fórmula de Masa Correctora ($\vec{M}_c$): $\vec{M}_c = \frac{-\vec{V}_0}{\vec{\alpha}}$
Estado: Correcto. La implementación en las líneas 149-150 y 184 del código sigue estrictamente esta relación vectorial.
Balanceo en 2 Planos
Modelo: Sistema de ecuaciones lineales $[\vec{V}] = [\vec{V}_0] + [\mathbf{C}][\vec{M}]$.
Resolución: Se utiliza la inversión de una matriz compleja de $2 \times 2$.
Fórmulas de Inversión: Implementa correctamente el método de la matriz adjunta y el determinante ($det = ad - bc$).
Estado: Correcto. El cálculo de la corrección mediante $[\vec{M}] = -[\mathbf{C}]^{-1} [\vec{V}_0]$ es técnicamente sólido y estándar.
2. Consistencia de Variables y Unidades
Variable	Unidad Estándar	Implementación en App	Validación
Vibración ($\vec{V}$)	$\mu m$ (p-p) o $mm/s$ (rms)	Complejo (Mag, Fase)	Válido (Agnóstico a unidad)
Masa ($\vec{M}$)	Gramos ($g$)	Complejo (Mag, Fase)	Válido
Ángulos ($\theta$)	Grados ($^\circ$)	Grados ($0$-$360^\circ$)	Válido
Fase	Lag (Retraso)	Convención Contra-Rotación	Válido (Estándar Bently Nevada/CSI)
3. Observaciones Críticas y Limitaciones
IMPORTANT

Suposición de Linealidad El modelo asume un sistema lineal. En rotores que operan cerca de velocidades críticas o con soportes no lineales, los coeficientes de influencia pueden variar. La función de "Nueva Iteración" implementada es la respuesta técnica correcta para mitigar esto mediante refinamiento sucesivo.

WARNING

Convención de Ángulos La lógica de ajustarAngulo y sugerirAlabe depende totalmente de que el usuario ingrese la fase como un ángulo de retraso (lag). Si el analizador de vibraciones del usuario entrega phase lead, los resultados estarían invertidos. Se recomienda asegurar que la ayuda en pantalla enfatice el uso de "Ángulo de Retraso".

4. Análisis de la Lógica de Álabes (Rotor Discreto)
La función sugerirAlabe (líneas 245-273) es una de las fortalezas técnicas de la implementación actual:

No se limita a una división entera.
Utiliza Distancia Angular Mínima en el círculo trigonométrico.
Considera el desfase del Álabe #1 y el sentido de numeración.
Resultado: Proporciona la ubicación física más precisa posible para el operador de campo.
5. Conclusión Técnica
El modelo es VÁLIDO y cumple con los requisitos para balanceo de precisión en maquinaria rotativa industrial. El uso de aritmética de números complejos para todas las operaciones asegura que no haya errores de redondeo por descomposición escalar innecesaria.

Recomendación de mejora:

Implementar una validación de "Masa de Prueba Sugerida" para evitar que el usuario coloque una masa tan pequeña que no logre un cambio significativo en el vector de vibración (regla del 30% de cambio en amplitud o 30° en fase).