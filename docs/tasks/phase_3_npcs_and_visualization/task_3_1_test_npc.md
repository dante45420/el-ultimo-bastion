# Tarea: 3.1 - NPC de Prueba

## 📝 Descripción General

Esta tarea implementa el sistema fundamental de Personajes No Jugables (NPCs). Los diseñadores podrán definir nuevos tipos de NPC (`TipoNPC`) con sus roles, comportamientos y gráficos, y luego crear instancias de estos NPCs (`InstanciaNPC`) en el mundo del juego a través del panel de administración. Godot Engine será capaz de cargar y visualizar estos NPCs, con un comportamiento de IA básico.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Backend API para `TipoNPC` e `InstanciaNPC`:**
    * `POST /api/v1/admin/tipos_npc`: Permite crear nuevos `TipoNPC` (incluyendo la creación de `CriaturaViva_Base` asociada con sus `Inventario` y `Daño`).
    * `GET /api/v1/admin/tipos_npc`: Retorna una lista de todos los `TipoNPC`s.
    * `GET /api/v1/admin/tipos_npc/<int:tipo_id>`: Retorna un `TipoNPC` específico.
    * `POST /api/v1/admin/instancias_npc`: Permite crear nuevas `InstanciaNPC` en un `Mundo` dado (basadas en un `TipoNPC`).
    * `GET /api/v1/admin/instancias_npc`: Retorna una lista de todas las `InstanciaNPC`s.
    * `GET /api/v1/admin/instancias_npc_by_mundo/<int:mundo_id>`: Retorna las `InstanciaNPC`s de un `Mundo` específico.
    * `PUT /api/v1/admin/instancias_npc/<int:inst_id>`: Permite actualizar atributos dinámicos de `InstanciaNPC` (ej. posición, `esta_vivo`).
    * Manejo de errores para validación (Marshmallow) e integridad de DB.
* **Frontend Panel de Administración (`TipoNPCAdminPage.jsx`, `InstanciaNPCAdminPage.jsx`):**
    * **Página `TipoNPCAdminPage.jsx`:**
        * Formulario para crear/editar `TipoNPC`, incluyendo campos para `nombre`, `descripcion`, `id_grafico`, `rol_npc` (dropdown), `comportamiento_ia` (textarea), `habilidades_base` (JSON), `resistencia_dano` (JSON), y los campos `initial_X` para crear la `CriaturaViva_Base` asociada.
        * Lista todos los `TipoNPC` existentes.
    * **Página `InstanciaNPCAdminPage.jsx` (Nuevo):**
        * Formulario para crear `InstanciaNPC`, con campos para `id_tipo_npc` (dropdown cargando TiposNPC existentes), `id_mundo` (dropdown cargando Mundos existentes), `posicion` (JSON), y opcionales `id_aldea_pertenece`, `id_clan_pertenece`, `id_persona_pertenece`, `restriccion_area`.
        * Lista todas las `InstanciaNPC`s existentes.
* **Godot Engine - Carga y Visualización de NPCs:**
    * `game_engine/scripts/Data_Loader.gd`: Se adapta para obtener/enviar datos de `TipoNPC` e `InstanciaNPC`.
    * `game_engine/scripts/NPC.gd` (Nuevo script): Script base para NPCs.
        * Adjuntado a un `CharacterBody3D` (o `Node3D` simple si es estático).
        * Carga los datos de `InstanciaNPC` y su `TipoNPC` asociado desde el backend.
        * Utiliza `id_grafico` de `TipoNPC` para cargar el modelo 3D/sprite del NPC.
        * Implementa movimiento básico (ej. deambular aleatorio) si `comportamiento_ia` lo sugiere (inicialmente muy simple).
        * Muestra un `Label3D` con el nombre del NPC.
    * `game_engine/scripts/WorldManager.gd`:
        * Se adapta para cargar las `InstanciaNPC` de su `id_mundo` y las instancia dinámicamente en la escena.
        * Actualiza periódicamente la `posicion` de las `InstanciaNPC` en el backend.
* **Prueba de Sincronización Funcional:**
    * Crear un `TipoNPC` y una `InstanciaNPC` desde el panel.
    * Al ejecutar la escena de Godot, el NPC aparece en la posición especificada y con el gráfico correcto.
    * El NPC se mueve con su IA básica (si implementada).
    * Si se actualiza la `posicion` de la `InstanciaNPC` en el panel, el NPC se teletransporta en Godot al recargar la escena o al recibir una actualización.

## 🔧 Detalles Técnicos de Implementación

### Backend (Flask / Python)

* **`backend/app/schemas.py`:** Asegurarse de que `TipoNPCSchema` e `InstanciaNPCSchema` están completos y con validaciones.
* **`backend/app/api/admin_routes.py`:**
    * Implementar `POST`, `GET` para `TipoNPC` (similar a `TipoObjeto`). Al crear `TipoNPC`, se debe crear una `CriaturaViva_Base` con `Inventario` y `Daño` asociados (los atributos `initial_X` del schema).
    * Implementar `POST`, `GET` (all y by_mundo), `PUT` para `InstanciaNPC`. Al crear `InstanciaNPC`, se debe asegurar que `id_tipo_npc`, `id_mundo` y los IDs de los componentes de `CriaturaViva_Base` son válidos.

### Frontend (React / Vite)

* **`frontend/src/api/adminApi.js`:**
    * Añadir funciones `createTipoNPC`, `getTiposNPC`, `createInstanciaNPC`, `getInstanciasNPC`, `getInstanciasNPCByMundo`.
* **`frontend/src/pages/TipoNPCAdminPage.jsx` (Nuevo)**:
    * Formulario para `TipoNPC`.
    * Manejar los campos `JSONB` como `resistencia_dano`, `habilidades_base`, `valores_rol`.
    * Incluir los campos `initial_X` para la creación de `CriaturaViva_Base`.
    * Lista `TipoNPC`s existentes.
* **`frontend/src/pages/InstanciaNPCAdminPage.jsx` (Nuevo)**:
    * Formulario para `InstanciaNPC`.
    * Dropdowns para seleccionar `TipoNPC` e `Mundo` existentes (cargando datos de la API).
    * Inputs para `posicion`, `restriccion_area`.
    * Lista `InstanciaNPC`s existentes.
* **`frontend/src/App.jsx`:** Integrar las nuevas páginas (`TipoNPCAdminPage`, `InstanciaNPCAdminPage`) y quizás una navegación básica.

### Godot Engine (GDScript)

* **`game_engine/scripts/Data_Loader.gd`:**
    * Añadir funciones para obtener datos de `TipoNPC` e `InstanciaNPC` (ej. `get_all_instancia_npcs_for_mundo(mundo_id)`).
* **`game_engine/scripts/NPC.gd` (Nuevo):**
    * Extiende de `CharacterBody3D` (o `Node3D`).
    * Recibe los datos de `InstanciaNPC` y `TipoNPC`.
    * Carga el modelo/sprite 3D basado en `TipoNPC.id_grafico`.
    * Configura su `CollisionShape3D` (hitbox) y `MeshInstance3D` (render) dinámicamente según las propiedades del tipo de NPC.
    * **IA Básica:** `_physics_process(delta)` para movimiento aleatorio o seguir un camino simple.
    * **Sincronización:** Cuando un NPC se mueve (o sus atributos cambian), envía una actualización `PUT` a `instancias_npc/<id>` en el Backend.
* **`game_engine/scripts/WorldManager.gd`:**
    * Después de cargar el `Mundo`, llama a `Data_Loader` para obtener todas las `InstanciaNPC` de ese `Mundo`.
    * Instancia la escena `NPC.tscn` para cada `InstanciaNPC` cargada y pasa los datos relevantes.
    * Gestiona el ciclo de vida de los NPCs (respawn, despawn).

## 🧪 Pruebas Detalladas

### Pruebas Unitarias (Backend)

* **Archivo:** `backend/tests/test_tanda_npc_crud.py` (Nuevo).
* **Funcionalidades a Testear:**
    * `test_create_tipo_npc`: Crear `TipoNPC` y verificar que su `CriaturaViva_Base` y sus componentes (`Inventario`, `Daño`) se crean correctamente.
    * `test_tipo_npc_unique_name`.
    * `test_create_instancia_npc_basic`: Crear `InstanciaNPC` y verificar relaciones con `TipoNPC` y `Mundo`.
    * `test_instancia_npc_with_aldea_owner`: Crear `InstanciaNPC` con `id_aldea_pertenece`.
    * `test_instancia_npc_update_position`: Actualizar `posicion` de `InstanciaNPC`.
    * `test_instancia_npc_update_health`: Simular daño y verificar `esta_vivo` y `salud_actual` en `CriaturaViva_Base`.

### Verificación Manual (Funcional Frontend & Godot)

1.  **Iniciar Backend y Frontend.**
2.  **Flujo en Frontend:**
    * Crear varios `TipoNPC`s (Aldeano, Malvado, Constructor, Mago) con diferentes `id_grafico`, `rol_npc` y `valores_rol`.
    * Crear varias `InstanciaNPC`s, asignándolas a diferentes `Mundo`s y posiciones.
    * Verificar que aparecen correctamente en las listas.
    * Actualizar la posición de una `InstanciaNPC` y verificar que se guarda.
3.  **Flujo en Godot:**
    * Cargar el proyecto Godot y ejecutar la escena del `Mundo` de Clan.
    * Observar que los `InstanciaNPC`s creados en el panel aparecen en sus posiciones correctas, con los gráficos esperados.
    * Verificar que la IA básica (ej. movimiento aleatorio si es un aldeano) funciona.
    * Si mueves un NPC de forma forzada en Godot (con un script de debug), su posición debería persistir al reiniciar la escena.

## 🚧 Bloqueadores/Riesgos

* Gestión de assets gráficos en Godot para que `id_grafico` cargue el modelo/sprite correcto.
* Implementación de IA básica para los diferentes roles de NPC de forma genérica.

## 🤝 Colaboración

* **Roles Involucrados:** Desarrollador Backend, Desarrollador Frontend, Desarrollador Godot, Diseñador de Juego.
* **Puntos de Contacto:** La colaboración es fundamental para que el `id_grafico` y los `valores_rol` sean interpretados correctamente entre el diseñador, el backend y Godot.
* **Actualizaciones:** Asegurarse de que `CURRENT_TASK_PROGRESS.md` se actualice al finalizar esta tarea.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                  | Responsable |
| :---------- | :--------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición detallada para la tarea `3.1 - NPC de Prueba`. | AI          |