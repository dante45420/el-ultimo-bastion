# Documentación y Aprendizajes: Fase 2 - Conexión y Mundo Sandbox

## 📝 Resumen de la Fase
En esta fase se estableció la conexión en tiempo real entre el motor de juego (Godot) y el servidor (Flask/Python), con el objetivo de cargar y visualizar un mundo dinámico definido en la base de datos. Se implementó la generación procedural de terreno y la instanciación de entidades (NPCs) basadas en los datos del backend.

## 🐛 Proceso de Depuración Detallado

La implementación de la generación de terreno presentó una serie de errores críticos que requirieron una depuración exhaustiva. Los aprendizajes de este proceso son fundamentales para el futuro del proyecto.

### Error 1: `Invalid access... on base 'Object'` y `Nonexistent function 'get_fractal'`
- **Síntoma:** El juego se detenía al intentar configurar las propiedades del terreno como `octaves` o `lacunarity`. El error indicaba que el objeto de ruido no era del tipo correcto o que la función no existía.
- **Causa Raíz:** Un error fundamental de diagnóstico basado en una **API incorrecta de Godot 4**. Mi conocimiento inicial apuntaba a que las propiedades fractales (`octaves`, `lacunarity`) se accedían a través de una función `get_fractal()`, lo cual es incorrecto para la versión estable de Godot 4.
- **Solución Implementada:** Se corrigió el código para acceder a las propiedades directamente desde el objeto `FastNoiseLite`, usando los nombres correctos de la API de Godot 4, como `noise.fractal_octaves` y `noise.fractal_lacunarity`.
- **Aprendizaje Clave:** **Verificar siempre la versión específica de la API del motor.** Las APIs pueden cambiar drásticamente entre versiones (incluso menores) y la documentación oficial para la versión en uso es la única fuente de verdad.

### Error 2: `HTTPRequest is processing a request` (ERR_BUSY)
- **Síntoma:** El juego fallaba al inicio porque dos scripts (`World.gd` y `Player.gd`) intentaban usar el `DataLoader` al mismo tiempo.
- **Causa Raíz:** El `DataLoader` original usaba un único nodo `HTTPRequest` y no estaba diseñado para manejar solicitudes concurrentes, resultando en una condición de carrera.
- **Solución Implementada:** Se rediseñó el `DataLoader.gd` para funcionar como un **gestor de colas (request queue)**. Ahora, las solicitudes se encolan en un array y se procesan de una en una, de forma ordenada.
- **Aprendizaje Clave:** Para un sistema escalable, los módulos de comunicación deben ser robustos y capaces de manejar múltiples solicitudes de forma asíncrona sin conflictos. La arquitectura de cola es una solución estándar y muy efectiva.

### Error 3: "Error Fantasma" y el Archivo sin Guardar (`●`)
- **Síntoma:** Los errores persistían a pesar de aplicar código teóricamente correcto.
- **Causa Raíz:** El editor de Godot no ejecuta el código visible en la pantalla, sino la última versión **guardada** del archivo en el disco. El indicador `●` en la pestaña del script mostraba que los cambios no se habían guardado.
- **Aprendizaje Clave:** Un pilar fundamental del flujo de trabajo de desarrollo es **siempre guardar los archivos (`Ctrl+S`)** después de cada cambio. Un error de sintaxis en un archivo dependiente (como `NPC.gd`) puede manifestarse de formas confusas en el archivo principal (`World.gd`).

## ✨ Decisiones de Arquitectura y Escalabilidad

- **Terreno Dinámico:** La generación de terreno está controlada por un diccionario `config` que viene de la base de datos. Esto sienta las bases para un sistema futuro de "modificadores de terreno", donde el panel de administración podrá definir montañas, lagos, etc., añadiendo elementos a este diccionario.
- **Entidades Data-Driven:** La creación de un personaje **MAGENTA** por defecto en `Player.gd` y de cubos de colores en `NPC.gd` valida el patrón de "fallback". Los scripts intentan cargar datos complejos (como `id_grafico`) y, si fallan, recurren a una visualización simple y funcional. Esto es clave para que el juego nunca se detenga, incluso si faltan assets.
- **Suelo de Emergencia y Colisiones:** La caída al vacío demostró que la física es un sistema separado de la lógica y la visualización. La revisión de **Capas y Máscaras de Colisión** es un paso de depuración esencial para cualquier entidad física. El "suelo de emergencia" es una herramienta de depuración útil para aislar problemas de física.