# Tarea: 6.1 - Integración Bastión-Entidades

## 📝 Descripción General (Enfoque Scrum - Nivel de Feature)

Esta tarea se centra en la implementación de las interacciones directas del jugador (Bastión) con las entidades del mundo: NPCs, animales y aldeas. Se cubrirán funcionalidades clave como el combate, la recolección, el comercio, la domesticación de animales y la interacción con misiones, utilizando los datos definidos en las tablas de `Tipo_` y actualizando las instancias en la base de datos.

## 🎯 Criterios de Aceptación (Definition of Done - DoD)

* **Combate Jugador-Entidad:**
    * El Bastión puede atacar a `InstanciaNPC` y `InstanciaAnimal`.
    * El daño se calcula utilizando `TipoObjeto.valores_especificos.tipo_dano` (del arma del Bastión) y `TipoNPC.resistencia_dano` / `TipoAnimal.resistencia_dano`.
    * La salud de la `CriaturaViva_Base` del objetivo se actualiza.
    * Al morir el objetivo, se activa `Daño.loot_table_id` y el loot aparece en el mundo o se añade al inventario del Bastión.
* **Recolección:**
    * El Bastión puede recolectar `InstanciaRecursoTerreno` utilizando `TipoObjeto` de tipo `HERRAMIENTA`.
    * La `salud_base` del recurso se reduce.
    * Se utilizan `TipoRecursoTerreno.efectividad_herramienta` para modificar la velocidad/cantidad de recolección.
    * Los recursos recolectados se añaden al inventario del Bastión.
* **Comercio:**
    * El Bastión puede interactuar con `InstanciaNPC` de tipo `COMERCIANTE`.
    * Se presenta la `TipoComercianteOferta` y se permite intercambiar objetos/moneda.
    * Los inventarios del Bastión y del NPC (`CriaturaViva_Base.id_inventario`) se actualizan atómicamente.
    * Las transacciones se registran en `InteraccionComercio`.
* **Domesticación/Montura:**
    * El Bastión puede interactuar con `InstanciaAnimal` para aumentar su `nivel_carino`.
    * Si el `nivel_carino` es suficiente y `TipoAnimal.es_montable`, el Bastión puede montar el animal.
    * El `id_dueno_usuario` de `InstanciaAnimal` se actualiza.
* **Misiones:**
    * El Bastión puede aceptar `TipoMision` de ciertos `InstanciaNPC`s.
    * El progreso de la misión (`MisionActiva.progreso_objetivos`) se actualiza automáticamente al cumplir objetivos (derrotar NPCs, recolectar ítems).
    * Las recompensas se otorgan al `Bastion` al completar la misión.

## 🚀 Relación con Fases Anteriores y Escalabilidad

* **Consolidación de Datos:** Esta fase es la culminación de la planificación data-driven. Todo lo definido en `TipoObjeto`, `TipoNPC`, `TipoAnimal`, `TipoMision`, `TipoLootTable` (Tandas 2) y las instancias dinámicas (Tanda 4) se pone en juego.
* **Reutilización de Lógica:** Las interacciones usan los componentes `Inventario`, `Daño`, `CriaturaViva_Base` (Tanda 1).
* **Escalabilidad:** Nuevos ítems, NPCs, animales o misiones se pueden crear en el panel y su interacción básica funcionará sin cambios de código, solo por los datos.

## 🚧 Bloqueadores/Riesgos

* Complejidad de la lógica de combate (cálculo de daño, detección de golpes).
* Sincronización en tiempo real de inventarios y estados de entidades entre jugadores en multijugador.
* Diseño de UI para interacciones (comercio, misiones).

## 🤝 Colaboración

* **Roles:** Desarrollador Godot (Interacciones, UI), Desarrollador Backend (APIs transaccionales), Diseñador de Juego (balance de combate, economía, misiones).

## 🗓️ Log de Actualizaciones de Tarea

| Fecha       | Actualización                                                                                                 | Responsable |
| :---------- | :------------------------------------------------------------------------------------------------------------ | :---------- |
| 2025-07-19  | Creación inicial de la definición de la tarea `6.1 - Integración Bastión-Entidades`. | AI          |