# Tarea: 7.1 - Primer Evento/Desastre

## 📝 Descripción General (Enfoque Scrum - Nivel de Feature)

Esta tarea se enfoca en la implementación del primer sistema de eventos globales. Los diseñadores podrán crear `TipoEventoGlobal`s desde el panel de administración. El Backend gestionará la activación y progresión de estos eventos en el `Mundo` del Clan (`EventoGlobalActivo`), y Godot visualizará sus efectos, objetivos y consecuencias en el entorno y el gameplay.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

* **Backend API para Eventos:** Implementación de endpoints CRUD para `TipoEventoGlobal` y `EventoGlobalActivo`.
* **Frontend Panel de Administración:** Páginas para gestionar `TipoEventoGlobal` (creación, edición, listado) y para ver el estado de los `EventoGlobalActivo`s.
* **Godot Engine - Lógica de Eventos:**
    * `WorldManager.gd` se conecta al Backend para obtener el `EventoGlobalActivo` actual del `Mundo` del Clan.
    * Interpretación de `fase_actual` del evento para activar lógica específica en Godot (ej., aparecer enemigos, cambiar el clima).
    * Interpretación de `efectos_mundo` para modificar el terreno (ej. un cráter, un área contaminada).
    * Monitorización de `objetivos_clan` (ej. derrotar X goblins) y envío de actualizaciones al Backend para `EventoGlobalActivo.estado_logro_clanes`.
    * Aplicación de `recompensa_exito` o `consecuencia_fracaso` al finalizar el evento (actualizando DB).
* **Pistas:** `TipoPista`s asociados a eventos pueden ser mostrados en la UI de Godot cuando se liberan.
* **Sincronización:** El estado del evento (`fase_actual`, `estado_logro_clanes`) se mantiene sincronizado entre el Backend y Godot.

## 🚀 Relación con Fases Anteriores y Escalabilidad

* **Data-Driven:** `TipoEventoGlobal` y `TipoPista` (de Tanda 2) son la base de los eventos, permitiendo a los diseñadores crear nuevos eventos narrativos sin código.
* **Integración de Mundos:** Se basa en `Mundo` (Tanda 3) para afectar un `id_mundo_clan` específico.
* **Impacto en Entidades:** Afecta `InstanciaNPC`, `InstanciaAnimal`, `InstanciaRecursoTerreno` (Tanda 4) según los `efectos_mundo`.
* **Escalabilidad:** El sistema permite la creación de una narrativa dinámica y cambiante simplemente definiendo nuevos eventos y sus efectos en la base de datos.

## 🚧 Bloqueadores/Riesgos

* Complejidad de los efectos visuales y de juego de los eventos en Godot.
* Manejo de la lógica de tiempo y fases de los eventos en el servidor.
* Resolución de conflictos si múltiples clanes interactúan con el mismo evento.

## 🤝 Colaboración

* **Roles:** Desarrollador Backend, Desarrollador Godot, Diseñador de Juego (narrativa, balance), Artista 3D/2D (efectos visuales).

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                              | Responsable |
| :---------- | :--------------------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `7.1 - Primer Evento/Desastre`. | AI          |