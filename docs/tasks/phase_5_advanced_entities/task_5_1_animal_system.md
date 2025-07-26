# Tarea: 5.1 - Sistema de Animales

## 📝 Descripción General (Enfoque Scrum - Nivel de Feature)

Esta tarea se enfoca en la implementación del sistema de animales, que incluye la definición de sus tipos (`TipoAnimal`) en el panel de administración y la creación de sus instancias (`InstanciaAnimal`) en el juego. Se implementará una IA básica para los animales (pacíficos, hostiles, territoriales), así como la capacidad de obtener recursos de ellos sin matarlos (ej. leche, lana) y la lógica de domesticación y montura.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

* **Backend API para Animales:** Implementación de endpoints CRUD para `TipoAnimal` e `InstanciaAnimal`.
* **Frontend Panel de Administración:** Páginas para gestionar `TipoAnimal` e `InstanciaAnimal` (creación, edición, listado).
* **Godot Engine - Comportamiento de Animales:**
    * Carga y visualización de `InstanciaAnimal`s con sus `id_grafico`s y atributos.
    * IA básica para `TipoAnimal.comportamiento_tipo` (ej., huir para pacíficos, perseguir para hostiles).
    * Implementación de interacciones para `recursos_obtenibles` (ej., ordeñar una vaca).
    * Lógica de `nivel_carino` y `id_dueno_usuario` para la domesticación/montura.
* **Persistencia:** La posición de los animales y su estado (`nivel_carino`, `esta_vivo`) persisten en la base de datos.

## 🚀 Relación con Fases Anteriores y Escalabilidad

* **Reutilización de Modelos Base:** Se basa fuertemente en `CriaturaViva_Base`, `Daño` e `Inventario` (de Tanda 1), asegurando la consistencia en atributos de salud, hambre e inventario.
* **Configuración Data-Driven:** `TipoAnimal` se define completamente desde la base de datos (con `resistencia_dano`, `recursos_obtenibles`), permitiendo a los diseñadores crear nuevos tipos de animales sin código.
* **Integración de UI/API:** Reutiliza el patrón de conexión Backend-Frontend establecido en Fase 2 y 3 para la administración.
* **Escalabilidad:** Al ser data-driven, la creación de nuevos tipos de animales es puramente una tarea de diseño/arte. La lógica de IA y recursos es genérica y se adapta a los datos definidos.

## 🚧 Bloqueadores/Riesgos

* Complejidad de la IA (especialmente para pathfinding y comportamiento de grupo).
* Sincronización de animaciones y estados de montura en multijugador.

## 🤝 Colaboración

* **Roles:** Desarrollador Godot (IA, animaciones), Diseñador de Juego (comportamientos, recursos), Artista 3D/2D (modelos).

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                  | Responsable |
| :---------- | :----------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `5.1 - Sistema de Animales`. | AI          |