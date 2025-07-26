# Tarea: 2.2 - Bastión (Personaje Jugador)

## 📝 Descripción General

Esta tarea se enfoca en implementar la gestión completa del personaje principal del jugador (el Bastión) a través del panel de administración y su visualización y control básico en Godot. Se establecerá la sincronización bidireccional de sus atributos dinámicos (salud, hambre, posición, etc.) entre el Backend y Godot.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

Para considerar esta tarea como 'Completa', deben cumplirse todos los siguientes criterios:

* **Backend API para `Bastion`:**
    * `POST /api/v1/admin/bastiones`: Permite crear nuevas instancias de `Bastion`.
    * `GET /api/v1/admin/bastiones`: Retorna una lista de todos los `Bastion`s.
    * `GET /api/v1/admin/bastiones/<int:bastion_id>`: Retorna un `Bastion` específico.
    * `PUT /api/v1/admin/bastiones/<int:bastion_id>`: Permite actualizar los atributos del `Bastion` (nivel, experiencia, salud, hambre, posición).
    * Manejo de errores para validación (Marshmallow) e integridad de DB (unicidad de `id_usuario`).
* **Frontend Panel de Administración (`BastionAdminPage.jsx`):**
    * Una nueva página de React similar a `TipoObjetoAdminPage`.
    * Formulario para crear/editar `Bastion`s, con campos para `nombre_personaje`, `nivel`, `experiencia`, `posicion_actual` (JSON), `habilidades_aprendidas` (JSON), y los IDs de `Usuario`, `Clan`, `CriaturaViva_Base`.
    * Lista todos los `Bastion`s existentes.
    * Integración con las llamadas a la API del Backend.
* **Godot Engine - Carga, Control y Sincronización del Bastión:**
    * `game_engine/scripts/Data_Loader.gd`: Se adapta para obtener/enviar datos de `Bastion`.
    * `game_engine/scripts/Player.gd` (Nuevo script):
        * Carga la instancia de `Bastion` del jugador logeado desde el backend (o una instancia predefinida si no hay login aún).
        * Asocia los atributos de `Bastion` y `CriaturaViva_Base` (salud, hambre, velocidad, etc.) con el `CharacterBody3D` del jugador en Godot.
        * Implementa control de movimiento básico del personaje (WASD, ratón).
        * Actualiza la `posicion_actual` del `Bastion` en la base de datos a través de llamadas PUT a la API del Backend de forma periódica (ej. cada X segundos o al cambiar de área/salir del juego).
        * Muestra una UI básica con salud y hambre.
    * `game_engine/scenes/main_scene.tscn`: Instancia un `CharacterBody3D` (el Bastión) y adjunta `Player.gd`. La cámara puede seguir al personaje.
* **Prueba de Sincronización Funcional:**
    * Crear/editar un `Bastion` desde el panel (cambiar nivel, hambre).
    * Al iniciar el juego en Godot con ese `Bastion`, sus stats se reflejan en la UI del juego.
    * Al mover el `Bastion` en Godot y luego reiniciar el juego, la posición debería persistir.
    * Cambiar la salud o hambre del `Bastion` en Godot (simulando daño o consumo), y verificar que se actualiza en la base de datos (y, por ende, en el panel de admin).

## 🔧 Detalles Técnicos de Implementación

### Backend (Flask / Python)

* **`backend/app/schemas.py`:** Asegurarse de que `BastionSchema` está completo y con validaciones.
* **`backend/app/api/admin_routes.py`:**
    * Implementar las funciones Python para los métodos `POST`, `GET` (all y by ID), `PUT` para `/api/v1/admin/bastiones`.
    * Manejar la creación de `Inventario`, `Daño`, `CriaturaViva_Base` al crear un `Bastion`, asegurando que los IDs se pasen correctamente.
    * Manejar `IntegrityError` para la unicidad de `id_usuario`.

### Frontend (React / Vite)

* **`frontend/src/api/adminApi.js`:**
    * Añadir funciones `createBastion`, `getBastions`, `updateBastion`.
* **`frontend/src/pages/BastionAdminPage.jsx` (Nuevo)**:
    * Formulario para `Bastion` (`nombre_personaje`, `nivel`, `experiencia`, `posicion_actual` (JSON)).
    * Dropdowns o inputs para `id_usuario`, `id_clan`, `id_criatura_viva_base` (inicialmente, estos pueden ser inputs numéricos, asumiendo que los IDs existen).
    * Lista los Bastiones existentes.
* **`frontend/src/App.jsx`:** Integrar `BastionAdminPage` (ej. añadir un enlace de navegación simple o cambiar la página principal).

### Godot Engine (GDScript)

* **`game_engine/scripts/Data_Loader.gd`:**
    * Añadir funciones para obtener/enviar datos de `Bastion`.
* **`game_engine/scripts/Player.gd` (Nuevo):**
    * Será un script principal para un `CharacterBody3D`.
    * En `_ready()`: Obtener `Bastion` de `Data_Loader`. Configurar `CharacterBody3D` (posición, velocidad).
    * `_physics_process(delta)`: Lógica de movimiento (WASD).
    * Sincronización: Llamar a `data_loader.update_bastion_position(id, new_pos)` periódicamente.
    * UI: Mostrar `Bastion.criatura_viva_base.danio.salud_actual` y `hambre_actual` en un `CanvasLayer`.
* **`game_engine/scenes/main_scene.tscn`:**
    * Añadir un `CharacterBody3D` (representando el Bastión) y adjuntar `Player.gd`.
    * Configurar una `Camera3D` que lo siga (`CameraArm` o `SpringArm3D`).

## 🧪 Pruebas Detalladas

### Pruebas Unitarias (Backend)

* **Archivo:** `backend/tests/test_tanda_bastion_crud.py` (Nuevo archivo de test).
* **Funcionalidades a Testear:**
    * `test_create_bastion`: Crear un `Bastion` y verificar sus atributos y relaciones con `Usuario`, `Clan`, `CriaturaViva_Base`.
    * `test_bastion_unique_user_id`: Probar la restricción `UNIQUE` para `id_usuario` en `Bastion`.
    * `test_update_bastion_attributes`: Actualizar `nivel`, `experiencia`, `posicion_actual` y verificar persistencia.
    * `test_bastion_health_and_hunger_sync`: Simular actualización de `salud_actual` y `hambre_actual` de `CriaturaViva_Base` a través del `Bastion` y verificar persistencia.

### Verificación Manual (Funcional Frontend & Godot)

1.  **Iniciar Backend y Frontend.**
2.  **Flujo en Frontend:**
    * Acceder a la página de administración de `Bastion`.
    * Crear un `Usuario` (si no existe uno de los `seed`).
    * Crear `Inventario`, `Daño`, `CriaturaViva_Base` para el `Bastion` (si los IDs no son de un `seed`).
    * Crear un `Bastion`, asignándole el `id_usuario` y el `id_criatura_viva_base` correctos.
    * Actualizar `nivel`, `experiencia` del `Bastion` y verificar que el cambio se guarda.
3.  **Flujo en Godot:**
    * Ejecutar `main_scene.tscn`.
    * Controlar el movimiento del Bastión.
    * Verificar que la UI básica de salud/hambre se muestra y coincide con el panel.
    * Mover el Bastión, cerrar Godot, reabrir y verificar que la `posicion_actual` persistió.
    * Simular recibir daño/hambre en Godot (ej. con un botón de debug) y verificar que el `Bastion` actualiza sus `salud_actual`/`hambre_actual` en la base de datos (y, por ende, se refleja en el panel de admin).

## 🚧 Bloqueadores/Riesgos

* Gestión de sesiones de usuario (login) para vincular el jugador de Godot con un `Usuario` de la DB. Se puede empezar con un `Bastion` hardcodeado al principio.
* Sincronización de atributos en tiempo real o casi real entre Godot y el Backend para el personaje del jugador.

## 🤝 Colaboración

* **Roles Involucrados:** Desarrollador Backend, Desarrollador Frontend, Desarrollador Godot, Diseñador de Juego.
* **Puntos de Contacto:** La estrecha colaboración es esencial para que la lógica de juego en Godot refleje los datos del Backend.
* **Actualizaciones:** Asegurarse de que `CURRENT_TASK_PROGRESS.md` se actualice al finalizar esta tarea.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                   | Responsable |
| :---------- | :---------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición detallada para la tarea `2.2 - Bastión (Personaje Jugador)`. | AI          |