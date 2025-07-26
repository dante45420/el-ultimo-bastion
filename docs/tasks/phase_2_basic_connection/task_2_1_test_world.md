# Tarea: 2.1 - Mundo Sandbox Editable y Editor de Contenido In-World

## 📝 Descripción General

Esta tarea se centra en establecer el "Mundo Sandbox" como el entorno central de desarrollo y pruebas. Esto implica crear un `Mundo` específico en la base de datos para este propósito y desarrollar las herramientas en el panel de administración para editar no solo sus propiedades globales (geografía), sino también para **crear, listar y editar las instancias de entidades que habitan *dentro* de ese mundo** (NPCs, Animales, Recursos Terreno, Aldeas, Edificios, Misiones Activas, Eventos Activos). Godot Engine será capaz de cargar y visualizar este mundo con todas sus entidades dinámicas. Este es el primer paso hacia el editor de contenido in-world.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Identificación/Creación de Mundo Sandbox:**
    * Un `Mundo` específico existe en la base de datos con `nombre_mundo="Mundo Sandbox para Devs"` (o similar).
    * Godot Engine se conecta por defecto a esta instancia de `Mundo` al ejecutar la escena principal.
* **Backend API para `Mundo`:**
    * `POST /api/v1/admin/mundos`: Permite crear nuevas instancias de `Mundo`.
    * `GET /api/v1/admin/mundos`: Retorna una lista de todas las instancias de `Mundo`.
    * `GET /api/v1/admin/mundos/<int:mundo_id>`: Retorna una instancia de `Mundo` por su ID.
    * `PUT /api/v1/admin/mundos/<int:mundo_id>`: Permite actualizar atributos de `Mundo` (semilla, configuración).
    * Manejo de errores para validación (Marshmallow) e integridad de DB.
* **Backend API para `InstanciaNPC`:**
    * `POST /api/v1/admin/instancias_npc`: Permite crear nuevas `InstanciaNPC` en un `Mundo` dado.
    * `GET /api/v1/admin/instancias_npc_by_mundo/<int:mundo_id>`: Retorna las `InstanciaNPC`s de un `Mundo` específico.
    * `PUT /api/v1/admin/instancias_npc/<int:inst_id>`: Permite actualizar atributos dinámicos (ej. posición, `esta_vivo`).
* **Backend API para Dropdowns del Frontend:**
    * `GET /api/v1/admin/usuarios`: Retorna una lista de `Usuario`s (para propietarios de Mundos/Instancias).
    * `GET /api/v1/admin/clanes`: Retorna una lista de `Clan`s (para propietarios de Mundos/Instancias).
    * `GET /api/v1/admin/tipos_npc`: Retorna una lista de `TipoNPC`s (para crear `InstanciaNPC`).
    * `GET /api/v1/admin/criaturaviva_bases`: Retorna una lista de `CriaturaViva_Base`s existentes (para seleccionar al crear `InstanciaNPC`, `Bastion`, `InstanciaAnimal`).
* **Frontend Panel de Administración (Rediseñado):**
    * **Página Principal de Navegación (`App.jsx`):** Contiene botones para acceder a las diferentes páginas de administración (Mundos, Tipos de Objeto, Instancias NPC, etc.).
    * **Página "Administrar Mundos" (`MundoAdminPage.jsx`):**
        * Formulario para crear/editar `Mundo`s (nombre, tipo, propietario, semilla, JSONs de configuración).
        * Lista todos los `Mundo`s creados.
        * Un botón o enlace para "Editar Contenido" que lleve a una vista de edición de contenido in-world para el `Mundo` seleccionado (inicialmente, esta vista estará en `MundoAdminPage.jsx` o una nueva página `WorldContentEditorPage.jsx`).
    * **Página "Administrar Instancias NPC" (`InstanciaNPCAdminPage.jsx`):**
        * Formulario para crear nuevas `InstanciaNPC`, con dropdowns para `id_tipo_npc`, `id_mundo`, `id_criatura_viva_base`.
        * Lista todas las `InstanciaNPC`s existentes, con opción de filtrar por `Mundo`.
        * (La edición visual de posición en el mapa Godot es futura, por ahora es manual en el formulario).
* **Godot Engine - Renderizado y Sincronización del Mundo Sandbox y sus NPCs:**
    * `game_engine/scripts/Data_Loader.gd`: Puede solicitar datos de `Mundo`, `InstanciaNPC`, `TipoNPC`, `CriaturaViva_Base`.
    * `game_engine/scripts/WorldManager.gd`:
        * Carga la instancia de `Mundo` con `nombre_mundo="Mundo Sandbox para Devs"`.
        * Genera el terreno básico usando `semilla_generacion`.
        * Obtiene todas las `InstanciaNPC`s asociadas a este Mundo Sandbox (`id_mundo`).
        * Instancia visualmente los NPCs cargados en sus `posicion` (`MeshInstance3D` simple + `Label3D` con nombre).
    * `game_engine/scenes/main_scene.tscn`: Configurada con los nodos `WorldManager_Node`, `DataLoader`, `WorldNameLabel`, `GroundContainer`, `NPCContainer`.
    * Assets `default_block_mesh.tres`, `default_block_material.tres`, `default_npc_mesh.tres`, `default_npc_material.tres` creados.
* **Godot Engine - Control Básico de Cámara/Jugador:**
    * `game_engine/scripts/Player.gd` implementa movimiento básico de vuelo (WASD) y control de cámara con el ratón.
    * La `Camera3D` de la escena sigue al `PlayerCharacter`.
* **Prueba de Sincronización Funcional (Flujo de Trabajo del Diseñador):**
    1.  Administrador/Diseñador crea/edita un `Mundo` ("Mundo Sandbox para Devs") en el panel.
    2.  Administrador/Diseñador crea una `InstanciaNPC` y le asigna una `posicion` y el `id_mundo` del Mundo Sandbox en el panel.
    3.  Al ejecutar/recargar la escena en Godot, el terreno generado y el NPC aparecen en las ubicaciones esperadas.
    4.  El jugador puede moverse por el mundo con la cámara y localizar el NPC.
    5.  Si se cambia la `posicion` del NPC en el panel, se refleja en Godot.

## 🔧 Detalles Técnicos de Implementación

### Backend (Flask / Python)

* **`backend/app/schemas.py`:**
    * Asegurarse de que todos los esquemas (`MundoSchema`, `InstanciaNPCSchema`, `TipoNPCSchema`, `UsuarioSchema`, `ClanSchema`, `CriaturaVivaBaseSchema`) estén completos y con sus validaciones.
* **`backend/app/api/admin_routes.py`:**
    * **Endpoints para `InstanciaNPC`:** `POST`, `GET` (all, by world ID), `PUT`. Al crear, asegurar que `id_tipo_npc`, `id_mundo`, y `id_criatura_viva_base` son válidos y existen.
    * **Endpoints para Dropdowns:** `GET /usuarios`, `GET /clanes`, `GET /tipos_npc`, `GET /criaturaviva_bases`. Estos deben retornar listas de objetos (solo `id` y `nombre`/`username` son suficientes).
* **`backend/manage.py` (seed):**
    * Asegurarse de que el `seed` crea un `Mundo` con `nombre_mundo="Mundo Sandbox para Devs"` y que es el mundo cargado por Godot.
    * Asegurarse de que el `seed` crea suficientes `Usuario`s y `Clan`s para las pruebas de propietarios de Mundos/Clanes.
    * Asegurarse de que el `seed` crea una buena variedad de `TipoNPC`s (con sus `CriaturaViva_Base`s asociadas) para poder crear `InstanciaNPC`s.

### Frontend (React / Vite)

* **`frontend/src/api/adminApi.js`:**
    * Añadir todas las funciones `createInstanciaNPC`, `getInstanciasNPC`, `getInstanciasNPCByMundo`, `updateInstanciaNPC`.
    * Asegurarse de que `getUsuarios`, `getClanes`, `getTiposNPC`, `getCriaturaVivaBases` hagan las llamadas API correctas.
* **`frontend/src/App.jsx`:**
    * Implementar un sistema de navegación simple (`useState` con botones) para cambiar entre `MundoAdminPage`, `TipoObjetoAdminPage`, `InstanciaNPCAdminPage`.
* **`frontend/src/pages/MundoAdminPage.jsx`:**
    * Extender el formulario y la lista existentes.
    * Añadir un botón "Editar Contenido" (o similar) junto a cada mundo listado. Al hacer clic, podría mostrar un editor in-line o redirigir a una nueva página (`WorldContentEditorPage.jsx`) que cargue las instancias de ese mundo.
* **`frontend/src/pages/InstanciaNPCAdminPage.jsx`:**
    * Formulario para crear `InstanciaNPC`. Incluir dropdowns para `id_tipo_npc`, `id_mundo`, `id_criatura_viva_base`.
    * Campos para `posicion` (JSON), `esta_vivo`, y los opcionales `id_aldea_pertenece`, `id_clan_pertenece`, `id_persona_pertenece`, `restriccion_area` (JSON), `valores_dinamicos` (JSON).
    * Lista las `InstanciaNPC`s con un filtro por `Mundo`.

### Godot Engine (GDScript)

* **`game_engine/scripts/Data_Loader.gd`:**
    * Asegurarse de que las funciones para `get_instancias_npc_by_mundo` y `update_instancia_npc` (para actualizar la posición del Bastión) están correctamente implementadas.
    * Funciones `get_tipos_npc`, `get_criatura_viva_bases`, `get_usuarios`, `get_clanes` para futuras referencias.
* **`game_engine/scripts/WorldManager.gd`:**
    * En `_ready()` y `_generate_world_from_data()`: Asegurarse de que se intenta cargar el `Mundo` con `nombre_mundo="Mundo Sandbox para Devs"`.
    * Después de generar el terreno, llamar a `data_loader.get_instancias_npc_by_mundo(current_world_data.id)` para obtener los NPCs.
    * Implementar `_generate_npcs(npcs_data: Array)` para crear `MeshInstance3D`s (o una escena `NPC.tscn` más compleja) para cada NPC, posicionándolos según `posicion` y mostrando su nombre.
    * `npc_container: Node3D`: Nuevo `@onready var` y nodo en la escena para agrupar los NPCs.
* **`game_engine/scripts/Player.gd` (Nuevo):**
    * Extiende de `CharacterBody3D`.
    * Implementa movimiento básico de vuelo (WASD) y control de cámara con el ratón.
    * Carga la instancia del Bastión del Backend (o un Bastion de prueba hardcodeado inicialmente).
    * Actualiza la `posicion_actual` del Bastión en la DB periódicamente.
    * Muestra UI básica de salud/hambre.
* **`game_engine/scenes/main_scene.tscn`:**
    * Configurada con los nodos: `MainWorld` (root), `DirectionalLight3D`, `Camera3D` (hija de `PlayerCharacter`), `WorldManager_Node` (con sus hijos `DataLoader`, `WorldNameLabel`, `GroundContainer`, `NPCContainer`), y un nuevo nodo `PlayerCharacter` (hijo directo de `MainWorld`, con su `MeshInstance3D`, `CollisionShape3D` y `Player.gd` adjunto).
    * Assets `default_block_mesh.tres`, `default_block_material.tres`, `default_npc_mesh.tres`, `default_npc_material.tres` creados.
* **`game_engine/assets/default_player_mesh.tres` y `default_player_material.tres`:** Nuevos assets para el Bastión.

## 🧪 Pruebas Detalladas

### Pruebas Unitarias (Backend)

* **Archivo:** `backend/tests/test_tanda_instancia_crud.py` (Nuevo archivo de test).
* **Funcionalidades a Testear:**
    * `test_create_instancia_npc`: Crear `InstanciaNPC` y verificar su guardado.
    * `test_get_instancias_npc_by_mundo`: Filtrar NPCs por ID de mundo.
    * `test_update_instancia_npc_position`: Actualizar la posición de un NPC.
    * (Tests para `InstanciaAnimal`, `InstanciaRecursoTerreno`, `InstanciaAldea`, `InstanciaEdificio` se añadirán aquí en el futuro).

### Verificación Manual (Funcional Frontend & Godot)

1.  **Iniciar Backend y Frontend.**
2.  **Flujo en Frontend:**
    * Acceder a "Administrar Mundos". Asegurarse de que el "Mundo Sandbox para Devs" existe.
    * **Acceder a "Administrar Instancias NPC":**
        * Crear una nueva `InstanciaNPC`, asignándola al "Mundo Sandbox para Devs" y con una posición visible.
    * **Acceder a "Administrar Bastiones":**
        * Crear un `Bastion` de prueba para un `Usuario` (ej., `player_one`), asignándole una `CriaturaViva_Base` existente y una `posicion_actual` inicial en el Mundo Sandbox.
3.  **Flujo en Godot:**
    * Cargar el proyecto Godot y ejecutar la `main_scene.tscn`.
    * Observar el terreno generado y el `PlayerCharacter` (el cubo del jugador).
    * **Usar WASD y ratón para mover al `PlayerCharacter` (modo vuelo).**
    * Navegar por el mundo para **encontrar el NPC** que se creó desde el panel.
    * (Opcional: Si se actualiza la `posicion` del `Bastion` o el `NPC` en el panel, verificar que se refleja en Godot tras reiniciar la escena).

## 🚧 Bloqueadores/Riesgos

* Precisión en las rutas `get_node()` en Godot.
* Gestión de la posición y orientación de la cámara del jugador.
* Asegurar que los IDs de los dropdowns en el frontend correspondan a entidades existentes en la DB (`TipoNPC`, `CriaturaViva_Base`, `Mundo`, `Usuario`, `Clan`).

## 🤝 Colaboración

* **Roles Involucrados:** Desarrollador Backend, Desarrollador Frontend, Desarrollador Godot, Diseñador de Juego.
* **Puntos de Contacto:** La comunicación será muy fluida para asegurar la correcta interpretación de los datos y su visualización.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                                                                                                                                                                                                                                                                                                               | Responsable |
| :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :---------- |
| 2025-07-20  | Creación inicial del documento `documentacion_testeo_optimizacion.md` para la Fase 2.1 (incluyendo el nuevo alcance de NPCs y Bastión inicial). | AI          |