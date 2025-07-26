# Tarea: 5.2 - Sistema de Aldeas Completo

## 📝 Descripción General (Enfoque Scrum - Nivel de Feature)

Esta tarea se enfoca en desarrollar el sistema completo de aldeas. Los jugadores podrán interactuar con `InstanciaAldea`s existentes (neutrales o del clan) que contendrán `InstanciaEdificio`s. Se implementará la lógica de producción de recursos de la aldea, el inventario compartido, y la interacción de los NPCs (`InstanciaNPC` de rol "CONSTRUCTOR") con los edificios y recursos de la aldea.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

* **Backend API para Aldeas y Edificios:** Implementación de endpoints CRUD para `InstanciaAldea` e `InstanciaEdificio`.
* **Frontend Panel de Administración:** Páginas para gestionar `InstanciaAldea`s e `InstanciaEdificio`s (creación, edición, listado).
* **Godot Engine - Lógica de Aldeas:**
    * Carga y visualización de `InstanciaAldea`s y sus `InstanciaEdificio`s.
    * Lógica de producción de recursos de la aldea (basada en `TipoEdificio.efectos_aldea` y añadida a `InstanciaAldea.id_inventario_aldea`).
    * NPCs Constructores interactúan con `InstanciaEdificio`s en estado "EN_PROGRESO" y consumen recursos del `InstanciaAldea.id_inventario_aldea`.
    * Visualización de daños y estados de construcción en `InstanciaEdificio` y `InstanciaAldea`.
* **Interacciones Básicas:** Jugadores pueden ver el inventario de la aldea (si son propietarios) y el estado de sus edificios.

## 🚀 Relación con Fases Anteriores y Escalabilidad

* **Reutilización de Componentes:** Las aldeas y edificios usan `Inventario` y `Daño` (de Tanda 1).
* **Data-Driven:** `TipoEdificio` y `TipoNPC` (de Tanda 2 y 3) definen el comportamiento y los costos, permitiendo a los diseñadores crear nuevos edificios y roles de NPC Constructores sin código.
* **Integración Profunda:** Se integra con `InstanciaNPC` (de Tanda 4) para los constructores, y con `Mundo` (de Tanda 3) para su ubicación.

## 🚧 Bloqueadores/Riesgos

* Complejidad de la IA de los constructores para planificar la construcción.
* Gestión del inventario compartido de la aldea y acceso multi-usuario/NPC.
* Sincronización de estados de construcción y producción en multijugador.

## 🤝 Colaboración

* **Roles:** Desarrollador Backend, Desarrollador Frontend, Desarrollador Godot, Diseñador de Juego.

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                              | Responsable |
| :---------- | :--------------------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `5.2 - Sistema de Aldeas Completo`. | AI          |