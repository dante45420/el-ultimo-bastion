# Tarea: 6.2 - Sistema de Clanes

## 📝 Descripción General (Enfoque Scrum - Nivel de Feature)

Esta tarea se centra en la implementación del sistema de clanes, que es el corazón de la colaboración social del juego. Los jugadores podrán crear, unirse, gestionar y salir de clanes. Las funcionalidades incluirán la visualización de miembros, la gestión del inventario compartido del Baluarte del Clan, y la acumulación de experiencia del clan.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

* **Backend API para Clanes:** Implementación de endpoints CRUD para `Clan` (ya iniciado en Tanda 3) y nuevas APIs para gestión de miembros (invitar, unirse, salir, expulsar) y acceso al Baluarte.
* **Frontend Panel de Administración:** Páginas para gestionar clanes (creación, edición, listado) y sus miembros.
* **Godot Engine - Funcionalidades de Clan:**
    * UI de clan en el juego (mostrar nombre, miembros, nivel, Baluarte).
    * Funcionalidad para que un Bastión (jugador) se una/salga de un clan.
    * Gestión de inventario del Baluarte del Clan (`Clan.id_inventario_baluarte`) accesible para miembros del clan.
    * El `nivel_experiencia` del clan se actualiza en el backend (inicialmente de forma manual o por eventos de debug).
* **Persistencia:** Todos los cambios en la membresía y el Baluarte del Clan persisten en la base de datos.

## 🚀 Relación con Fases Anteriores y Escalabilidad

* **Reutilización de Modelos:** Utiliza `Clan` (Tanda 3) y `Inventario` (Tanda 1) directamente.
* **API Existente:** Se expanden las APIs de `Usuario` y `Bastion` (Tanda 3) para la gestión de membresía.
* **Escalabilidad:** El sistema permite la creación de muchos clanes y la gestión de sus atributos de forma data-driven. La experiencia del clan es clave para la competitividad futura.

## 🚧 Bloqueadores/Riesgos

* Manejo de concurrencia y conflictos en la gestión de miembros de clan y el inventario del Baluarte en un entorno multijugador.
* Diseño de la UI de gestión de clan en Godot.

## 🤝 Colaboración

* **Roles:** Desarrollador Backend, Desarrollador Frontend, Desarrollador Godot, Diseñador de Juego.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                             | Responsable |
| :---------- | :---------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `6.2 - Sistema de Clanes`. | AI          |