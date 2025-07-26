# Tarea: 7.2 - Mundos Múltiples y Épocas

## 📝 Descripción General (Enfoque Scrum - Nivel de Feature)

Esta tarea implementa el sistema de múltiples mundos (Mundo del Clan dinámico y Mundos Personales) y el concepto de "Épocas" (ciclos de reinicio/reconfiguración del Mundo del Clan). Se permitirá a los jugadores transitar entre estos mundos y se gestionará la persistencia selectiva de sus atributos y recursos entre las Épocas. El Baluarte del Clan (`Clan.id_inventario_baluarte`) jugará un rol central en la transferencia de progreso.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

* **Backend - Gestión de Mundos y Épocas:**
    * API para gestionar transiciones entre `Mundo`s (`Bastion.posicion_actual.mundo`).
    * Lógica para el reinicio del `Mundo` del Clan al final de una Época (borrar `InstanciaNPC`, `InstanciaAnimal`, `InstanciaRecursoTerreno`, `InstanciaAldea`, `InstanciaEdificio` y generar nuevas instancias o resetear `Mundo.estado_actual_terreno`).
    * Lógica para transferir recursos y habilidades limitadas del `Bastion` al `Baluarte del Clan` al final de una Época, y viceversa al inicio de una nueva.
* **Godot Engine - Transición entre Mundos:**
    * Funcionalidad en el juego para que el `Bastion` cambie de `Mundo` (ej. a través de un portal o menú).
    * Godot carga la escena y las instancias de entidades correspondientes al `Mundo` al que se transiciona.
* **Persistencia de Épocas:**
    * Los datos del `Mundo` (`Mundo.semilla_generacion`, `estado_actual_terreno`, `configuracion_actual`) y las instancias de entidades se restablecen/generan según las reglas de la Época.
    * Los recursos seleccionados y las habilidades parciales persisten a través del `Baluarte del Clan`.

## 🚀 Relación con Fases Anteriores y Escalabilidad

* **Fundamento de `Mundo`:** Se construye directamente sobre la implementación de `Mundo` (Tanda 3) y `EventoGlobalActivo` (Tanda 7.1).
* **Baluarte Central:** El `Clan.id_inventario_baluarte` (Tanda 3 y 6.2) se vuelve crucial para la progresión entre Épocas.
* **Reutilización de Instancias:** `InstanciaNPC`, `InstanciaAnimal`, etc. (Tanda 4) son los que se "reinician" en cada nueva Época.
* **Escalabilidad:** Permite una rejugabilidad infinita con mundos dinámicos y narrativas que evolucionan sin tener que reiniciar todo el progreso del jugador cada vez.

## 🚧 Bloqueadores/Riesgos

* Complejidad de la lógica de reinicio de Época y gestión de transiciones de datos.
* Asegurar que solo los datos correctos persistan y el resto se borre/genere.
* Sincronización de transiciones de mundo en un entorno multijugador.

## 🤝 Colaboración

* **Roles:** Desarrollador Backend, Desarrollador Godot, Diseñador de Juego (reglas de persistencia de Época).

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                   | Responsable |
| :---------- | :---------------------------------------------------------------------------------------------- | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `7.2 - Mundos Múltiples y Épocas`. | AI          |