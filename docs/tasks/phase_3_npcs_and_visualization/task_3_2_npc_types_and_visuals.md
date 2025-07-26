# Tarea: 3.2 - Tipos y Visualizaciones de NPCs

## 📝 Descripción General

Esta tarea profundiza en la diversidad de NPCs y la fidelidad visual, asegurando que los `TipoNPC`s con sus roles específicos (Constructor, Comerciante, Malvado, Mago) y los `id_grafico`s se representen correctamente en Godot. Se busca que la apariencia y el comportamiento inicial de los NPCs reflejen lo definido en el panel de administración.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Backend - Datos de Tipos de NPC Enriquecidos:**
    * El `seed` de `manage.py` incluye datos de ejemplo para al menos 2-3 `TipoNPC`s de cada `rol_npc` (Constructor, Comerciante, Malvado, Mago), con `id_grafico`s distintivos y `valores_rol` representativos (ej. `rango_vision` para Malvado, `cooldown_construccion` para Constructor).
* **Godot Engine - Carga y Visualización Dinámica:**
    * `game_engine/scripts/NPC.gd` puede cargar el modelo/sprite 3D correcto en tiempo de ejecución basado en `TipoNPC.id_grafico`.
    * El tamaño y la forma del hitbox (`CollisionShape3D`) de los NPCs se ajustan dinámicamente en Godot según las dimensiones del modelo cargado o un parámetro en `TipoNPC.valores_rol`.
    * Se implementa una lógica de visualización básica en Godot que reacciona a `TipoNPC.resistencia_dano` (ej. si tiene resistencia a fuego, un efecto visual rojo tenue al ser golpeado por fuego).
* **Godot Engine - IA Básica por Rol:**
    * Se implementa una lógica de IA rudimentaria para cada `rol_npc`:
        * **Constructor:** Deambula por la aldea. Podría acercarse a edificios en `estado_construccion="EN_PROGRESO"` (visual sin lógica de construcción aún).
        * **Malvado:** Deambula o patrulla. Ataca al Bastión del jugador o a otros NPCs/Animales si entran en su `rango_vision`.
        * **Comerciante:** Permanece en una posición fija (ej. un puesto), tiene un indicador visual que invita a comerciar.
        * **Mago:** Permanece en una posición fija o deambula lentamente. Podría mostrar un efecto visual de una de sus `habilidades_base` (sin funcionalidad de combate aún).
* **Verificación Manual (Frontend & Godot):**
    * Desde el panel de admin, se pueden crear `TipoNPC`s de diferentes roles y observar que sus `id_grafico`s y `valores_rol` se guardan.
    * En Godot, al instanciar y ejecutar el juego, los NPCs aparecen con sus gráficos correctos y exhiben su comportamiento de IA básico asociado a su rol. Se puede verificar que las reglas de `resistencia_dano` se aplicarían conceptualmente.

## 🔧 Detalles Técnicos de Implementación

### Backend (Flask / Python)

* **`backend/manage.py` (seed):**
    * Asegurarse de que el `seed` crea ejemplos de `TipoNPC` para cada rol (Constructor, Malvado, Comerciante, Mago, Genérico).
    * Cada `TipoNPC` de ejemplo debe tener un `id_grafico` diferente.
    * Cada `TipoNPC` debe tener `resistencia_dano` y `valores_rol` que reflejen su rol (`rango_vision`, `ofertas_comercio_ids`, `mana_max`, etc.).

### Godot Engine (GDScript)

* **`game_engine/assets/characters/`:** Los artistas (o placeholders) deben proporcionar modelos 3D simples (ej. archivos `.glb` o `.obj`) para cada `id_grafico` de los `TipoNPC` de prueba.
* **`game_engine/scripts/NPC.gd`:**
    * En `_ready()`:
        * Después de cargar los datos de `InstanciaNPC` y `TipoNPC` del backend:
        * Cargar el `Mesh` o `Sprite3D` dinámicamente usando `TipoNPC.id_grafico` (ej., `load("res://assets/characters/" + npc_data.tipo_npc.id_grafico + ".glb")`).
        * Ajustar `scale` del `MeshInstance3D` si `TipoNPC.valores_rol` tiene un atributo `escala_modelo`.
        * Ajustar el `shape.extents` de `CollisionShape3D` (hitbox) basándose en las dimensiones del modelo o en un parámetro de `TipoNPC.valores_rol`.
    * **IA por Rol:**
        * Crear funciones o componentes de IA para cada `rol_npc`. Un `match` statement en `_physics_process(delta)` de `NPC.gd` podría delegar a estas funciones:
            ```gdscript
            func _physics_process(delta):
                match npc_data.tipo_npc.rol_npc:
                    "CONSTRUCTOR":
                        _handle_builder_ai(delta)
                    "MALVADO":
                        _handle_evil_ai(delta)
                    # ... y así sucesivamente
            ```
        * Las funciones `_handle_X_ai()` implementarán la lógica rudimentaria (ej., movimiento aleatorio para "Constructor", detectar y moverse hacia el jugador para "Malvado" usando `rango_vision` de `valores_rol`).
    * **Visualización de Debilidades/Fortalezas:**
        * Implementar un `Shader` básico en un `Material` del NPC que cambie ligeramente de color o emita un brillo cuando reciba daño de un `tipo_dano` al que sea `resistencia_dano`. Esto es un indicador visual de la mecánica.

## 🧪 Pruebas Detalladas

### Pruebas Unitarias (Backend)

* Ya cubiertas por `test_tanda2_types.py` (para la creación de `TipoNPC`s con `resistencia_dano` y `valores_rol`).
* No se requieren nuevos tests unitarios de backend específicos para esta tarea, ya que la lógica principal es de visualización e IA en Godot.

### Verificación Manual (Funcional Frontend & Godot)

1.  **Iniciar Backend y Frontend.**
2.  **Flujo en Frontend:**
    * Acceder a la página de administración de `TipoNPC`.
    * Crear nuevos `TipoNPC`s de cada `rol_npc` (Constructor, Malvado, Comerciante, Mago), asegurándose de usar `id_grafico`s únicos y definir `valores_rol` y `resistencia_dano` según la descripción.
    * Crear `InstanciaNPC`s de estos nuevos tipos en el `Mundo` de prueba.
3.  **Flujo en Godot:**
    * Cargar el proyecto Godot y ejecutar la escena.
    * Observar que los `InstanciaNPC`s aparecen con sus modelos/sprites específicos (si los assets están en `game_engine/assets/characters/` con los nombres correctos).
    * Verificar que los NPCs deambulan, se quedan quietos, o (para Malvado) intentan moverse hacia el jugador.
    * (Opcional) Implementar un simple "botón de debug de daño" en Godot para simular diferentes `tipo_dano` y observar si los efectos visuales de `resistencia_dano` se activan.

## 🚧 Bloqueadores/Riesgos

* Disponibilidad de assets 3D/2D para `id_grafico`.
* Complejidad de la IA; mantenerla muy simple para esta tarea.
* Sincronización de transformaciones (posición, rotación) del NPC entre Godot y el Backend.

## 🤝 Colaboración

* **Roles Involucrados:** Desarrollador Godot (IA, Visualización), Artista 3D/2D (creación de assets), Diseñador de Juego (refinamiento de comportamiento IA).
* **Puntos de Contacto:** Diálogo constante para asegurar que los `id_grafico` se correspondan con los assets, y que la IA implementada satisfaga los `comportamiento_ia` textuales.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                  | Responsable |
| :---------- | :--------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición detallada para la tarea `3.2 - Tipos y Visualizaciones de NPCs`. | AI          |