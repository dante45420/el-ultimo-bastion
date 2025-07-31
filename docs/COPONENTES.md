# Arquitectura de Componentes de "El Último Bastión"
Este documento detalla la arquitectura de componentes reutilizables diseñada para el motor de juego en Godot. El objetivo de esta arquitectura es promover la modularidad, la escalabilidad y un flujo de trabajo data-driven, permitiendo que la lógica compleja del juego se construya a partir de bloques simples y configurables desde la base de datos.

---

## 1. HealthComponent
🎯 Propósito Principal: Gestionar la vida, el daño, la curación y la muerte de cualquier entidad.

### Detalles del Componente
Controla:

* **current_health**: `int`: La salud actual de la entidad.
* **max_health**: `int`: La salud máxima de la entidad.
* **resistance_map**: `Dictionary`: Un mapa de resistencias y vulnerabilidades a tipos de daño (ej. `{"FIRE": 0.5, "ICE": 1.5, "POISON": 1.0}`).
* **health_regeneration_rate**: `float`: Puntos de salud regenerados por segundo.

### Lógica y Funciones Clave:

* `initialize_health(max, current, resistances)`: Establece los valores iniciales del componente.
* `take_damage(amount: float, damage_type: String)`: Función central para recibir daño. Calcula el daño final aplicando el multiplicador de `resistance_map`. Si `damage_type` no existe en el mapa, el multiplicador es 1.0. Asegura que la salud no baje de 0.
* `heal(amount: float)`: Aumenta la salud, asegurando que no supere `max_health`.

### Señales:

* `health_changed(new_health, max_health)`: Se emite cada vez que la salud cambia. Ideal para actualizar barras de vida en la UI.
* `died(entity_id, entity_type)`: Se emite una sola vez cuando `current_health` llega a 0. Es la señal que desencadena toda la lógica de muerte.

### Interactúa Con:

* **CombatComponent**, **HungerComponent**, **TerrainInteractionComponent**: Recibe llamadas a `take_damage`.
* **AIComponent**: Puede leer la salud para tomar decisiones (ej. huir si la salud es baja).
* **VisualsComponent**: Para mostrar efectos de daño o muerte.

### Configuración Data-Driven (Tipo...)
En TipoNPC o TipoAnimal:

* `initial_salud_max`: Integer.
* `resistencia_dano`: JSONB.

---

## 2. InventoryComponent
🎯 Propósito Principal: Gestionar el almacenamiento, peso y acceso a los ítems de una entidad.

### Detalles del Componente
Controla:

* **items**: `Dictionary`: El contenido del inventario (ej. `{ "item_id_1": {"quantity": 10, "item_data": {...}} }`).
* **max_slots**: `int`: El número máximo de tipos de ítems distintos.
* **max_weight_kg**: `float`: El peso máximo que puede cargar.
* **current_weight**: `float`: El peso actual, calculado dinámicamente.

### Lógica y Funciones Clave:

* `add_item(item_type: TipoObjeto, quantity: int)`: Añade ítems. Verifica si el ítem `es_apilable`. Valida contra `max_slots` y `max_weight_kg`.
* `remove_item(item_id: int, quantity: int)`: Quita ítems del inventario.
* `has_resources(recipe: Dictionary)`: Comprueba si el inventario contiene los materiales necesarios para una receta de crafteo.

### Señales:

* `inventory_changed(new_items_dict)`: Se emite cuando el contenido cambia, para actualizar la UI.
* `inventory_full`: Se emite cuando no hay más slots.
* `inventory_overweight`: Se emite cuando se supera el peso máximo.

### Interactúa Con:

* **ProductionComponent**: Provee los recursos y recibe los ítems fabricados.
* **InteractionComponent**: Permite al jugador transferir ítems.
* **QuestLogComponent**: Verifica la presencia de ítems de misión.

### Configuración Data-Driven (Tipo...)
En TipoNPC:

* `initial_inventario_capacidad_slots`: Integer.
* `initial_inventario_capacidad_peso_kg`: Numeric.
El contenido inicial se obtiene de la Instancia... o el Bastion.

---

## 3. MovementComponent
🎯 Propósito Principal: Centralizar toda la lógica de movimiento, física y colisiones.

### Detalles del Componente
Controla:

* **speed**: `float`: Velocidad de movimiento base.
* **gravity**: `float`: Valor de la gravedad a aplicar.
* **movement_mode**: `String`: El estado actual (`"walking"`, `"swimming"`, `"flying"`, `"climbing"`).
* **collision_layer**: `int` y **collision_mask**: `int`: Define con qué colisiona la entidad.

### Lógica y Funciones Clave:

* Contiene toda la lógica de `_physics_process` y la llamada a `move_and_slide()`.
* `move_to(destination)`: Función para la IA. Calcula la dirección y aplica velocidad.
* `set_movement_mode(new_mode)`: Cambia el comportamiento físico. En modo `"flying"`, la gravedad se ignora. En modo `"swimming"`, se aplica una física de flotabilidad.
* En `_physics_process`, detecta el tipo de cuerpo o área con el que está en contacto en el suelo/agua y notifica al TerrainInteractionComponent.

### Interactúa Con:

* **AIComponent** / **Player Input**: Recibe las órdenes de hacia dónde moverse.
* **TerrainInteractionComponent**: Le informa sobre el tipo de terreno que está pisando.
* **StateComponent**: Puede leer estados como `"is_slowed"` para reducir la velocidad.

### Configuración Data-Driven (Tipo...)
En TipoNPC:

* `initial_velocidad_movimiento`: Numeric.
La capa y máscara de colisión pueden ser fijas por tipo de entidad (Player, NPC, etc.) o configurables.

---

## 4. VisualsComponent
🎯 Propósito Principal: Gestionar la apariencia, animaciones y forma de colisión de la entidad.

### Detalles del Componente
Controla:

* El nodo `MeshInstance3D` (el modelo 3D).
* El nodo `CollisionShape3D` (el hitbox).
* El nodo `AnimationPlayer` o `AnimationTree` (para animaciones complejas).

### Lógica y Funciones Clave:

* `initialize_visuals(id_grafico, hitbox_data)`: Carga el recurso del modelo 3D. Basado en `hitbox_data` desde la BD, crea la `CollisionShape3D` apropiada (ej. `CapsuleShape3D`, `BoxShape3D`, o una `ConvexCollisionShape3D` generada a partir del mesh para un ajuste perfecto).
* `play_animation(name)`: Reproduce una animación. Puede usar un `AnimationTree` para mezclar animaciones de forma fluida (ej. caminar y apuntar al mismo tiempo).
* `attach_vfx(vfx_resource, socket_name)`: Instancia un efecto visual (ej. una explosión) en un punto de anclaje específico del esqueleto del modelo.

### Interactúa Con:

* **HealthComponent**: Al recibir la señal `died`, puede reproducir la animación de muerte.
* **MovementComponent**: Al moverse, le pide reproducir la animación de caminar/correr.
* **CombatComponent**: Le pide reproducir animaciones de ataque.

### Configuración Data-Driven (Tipo...)
En TipoNPC, TipoAnimal, etc:

* `id_grafico`: String.
* `valores_rol` o `valores_especificos`: Un JSONB que contiene los `hitbox_dimensions` y el color.

---

## 5. StateComponent
🎯 Propósito Principal: Actuar como una pizarra de estados central y dinámica para una entidad.

### Detalles del Componente
Controla:

* **states**: `Dictionary`: Un diccionario que almacena cualquier estado booleano o de valor (ej. `{"is_on_fire": true, "attack_multiplier": 1.5, "is_invisible": false}`).

### Lógica y Funciones Clave:

* `set_state(state_name, value)`: Modifica o añade un estado.
* `get_state(state_name, default_value)`: Consulta un estado.
* `has_state(state_name)`: Verifica si un estado existe.

### Señales:

* `state_changed(state_name, new_value)`: Se emite cuando un estado cambia, permitiendo que otros componentes reaccionen de forma desacoplada.

### Interactúa Con:

* **TODOS** los demás componentes. Es el nexo de comunicación interno. El **AIComponent** lee el estado `is_in_combat`. El **CombatComponent** aplica el `attack_multiplier`. El **VisualsComponent** reacciona a `is_on_fire` para mostrar llamas.

### Configuración Data-Driven (Tipo...)
Generalmente no se configura desde la base de datos, ya que representa el estado dinámico en tiempo de ejecución. Sin embargo, algunos estados iniciales podrían definirse si es necesario.

---

## 6. InteractionComponent
🎯 Propósito Principal: Gestionar la capacidad de una entidad para iniciar o ser objeto de interacciones no combativas.

### Detalles del Componente
Controla:

* `interaction_range`: `float` (en el Player).
* `available_interactions`: `Array` (en el objetivo, ej. `["talk", "trade"]`).

### Lógica y Funciones Clave:

* En el Player: Usa un `RayCast3D` para detectar entidades. Si la entidad golpeada tiene un `InteractionComponent`, llama a `get_available_interactions()` para saber qué puede hacer y muestra la UI (`"Pulsa E para Hablar"`).
* En el Objetivo (NPC, Objeto):
    * `get_available_interactions()`: Devuelve la lista de acciones posibles, que puede depender de su **StateComponent** (ej. no se puede comerciar si está en combate).

### Señales:

* `interacted_with(interaction_type, interactor_node)`: Se emite cuando el jugador activa la interacción.

### Interactúa Con:

* **Player Input**: Para el trigger de interacción.
* **AIComponent**: Escucha la señal `interacted_with` para iniciar un diálogo o una acción.
* **QuestLogComponent**: Puede ser activado para aceptar o entregar una misión.

### Configuración Data-Driven (Tipo...)
En TipoNPC:

* El `rol_npc` (`"Comerciante"`, `"Guía"`) define implícitamente las interacciones disponibles.

---

## 7. CombatComponent
🎯 Propósito Principal: Encapsular toda la lógica de ataque, daño y uso de habilidades de combate.

### Detalles del Componente
Controla:

* `base_damage`: `float`.
* `attack_range`: `float`.
* `attack_cooldown`: `float`.
* `skills`: `Dictionary`: Habilidades activas con sus cooldowns actuales.

### Lógica y Funciones Clave:

* `execute_attack(target_entity)`: Realiza un ataque básico. Obtiene el daño final aplicando buffs/debuffs del **StateComponent** y llama a `take_damage` en el **HealthComponent** del objetivo.
* `use_skill(skill_id, target)`: Activa una habilidad de la lista, aplica su efecto y pone la habilidad en cooldown.
* La lógica de apuntado y selección de objetivos puede residir aquí o ser dictada por el **AIComponent**.

### Interactúa Con:

* **HealthComponent**: Llama a `take_damage` en el objetivo.
* **StateComponent**: Lee sus propios buffs (más daño) y puede aplicar debuffs al objetivo (veneno, ralentización).
* **AIComponent** / **Player Input**: Recibe la orden de atacar o usar una habilidad.

### Configuración Data-Driven (Tipo...)
En TipoNPC:

* `initial_dano_ataque_base`: Integer.
* `habilidades_base`: ARRAY(db.Integer).

---

## 8. AIComponent
🎯 Propósito Principal: Ser el cerebro de la entidad, tomando decisiones basadas en su rol, estado y entorno.

### Detalles del Componente
Controla:

* Una máquina de estados o un árbol de comportamiento (BehaviorTree).
* `perception_radius`: `float`: Rango de visión/oído.
* `current_target`: `Node`: El objetivo actual (un enemigo, un recurso, un punto de patrulla).

### Lógica y Funciones Clave: (Ciclo "Sense-Think-Act")

* **Sense**: Escanea el entorno en busca de jugadores, enemigos, recursos, etc.
* **Think**: Procesa la información. Basado en su `rol_npc`, `comportamiento_ia` y su estado actual (**StateComponent**), decide la acción prioritaria (ej. `"Salud baja -> Huir"`, `"Enemigo a la vista -> Atacar"`, `"Rol Artesano y ocioso -> Buscar trabajo"`).
* **Act**: Emite órdenes a los otros componentes:
    * `MovementComponent.move_to(target.global_position)`.
    * `CombatComponent.execute_attack(current_target)`.
    * `ProductionComponent.start_crafting(recipe)`.

### Interactúa Con:

* Da órdenes a casi todos los demás componentes.
* Lee información del **StateComponent**, **HealthComponent**, e **InventoryComponent** para tomar decisiones.

### Configuración Data-driven (Tipo...)
En TipoNPC:

* `rol_npc`: String.
* `comportamiento_ia`: Text.

---

## 9. OwnershipComponent
🎯 Propósito Principal: Gestionar la propiedad y lealtad de una entidad (NPC, Animal, Aldea).

### Detalles del Componente
Controla:

* `owner_user_id`: `int` o `owner_clan_id`: `int`.
* `is_public`: `bool`.
* `loyalty`: `float` (0.0 a 100.0).

### Lógica y Funciones Clave:

* `set_owner(new_owner)`: Asigna un nuevo dueño.
* `update_loyalty(amount)`: La lealtad se modifica por acciones (alimentar, cuidar) o inacciones (hambre, abandono).
* `has_permission(user_id)`: Verifica si un jugador tiene derecho a dar órdenes.

### Señales:

* `loyalty_changed(new_loyalty)`.
* `rebelled`: Se emite si la lealtad cae a cero. La entidad se vuelve salvaje/hostil.

### Interactúa Con:

* **AIComponent**: La lealtad influye en sus decisiones (un NPC leal podría sacrificarse).
* **InteractionComponent**: Determina qué interacciones están disponibles para qué jugador.

### Configuración Data-Driven (Tipo...)
La propiedad se establece en la Instancia... (`id_clan_pertenece`, `id_dueno_usuario`, etc.).

---

## 10. ProductionComponent
🎯 Propósito Principal: Gestionar la capacidad de una entidad (NPC o edificio) para fabricar ítems.

### Detalles del Componente
Controla:

* `crafting_recipes`: `Array`: Lista de `TipoObjetos` que puede crear.
* `production_queue`: `Array`: Cola de trabajos de crafteo.
* `crafting_speed_multiplier`: `float`.

### Lógica y Funciones Clave:

* `queue_crafting_job(recipe_id)`: Añade un trabajo a la cola.
* En su `_process`, si no está ocupado, toma el siguiente trabajo de la cola.
* Llama a `InventoryComponent.has_resources()` para verificar materiales. Si los tiene, los consume e inicia un `Timer`.
* Al finalizar el `Timer`, llama a `InventoryComponent.add_item()` para añadir el producto final.

### Interactúa Con:

* **InventoryComponent**: Para consumir recursos y depositar productos.
* **AIComponent**: Recibe órdenes para empezar a craftear.
* **StructureComponent**: Puede requerir estar cerca de una estación de trabajo (**StructureComponent**) para poder craftear ciertas recetas.

### Configuración Data-Driven (Tipo...)
En TipoNPC o TipoEdificio:

* Una lista de IDs de recetas que puede fabricar, almacenada en `valores_especificos` o `valores_rol`.

---

## 11. QuestLogComponent
🎯 Propósito Principal: Gestionar el estado y progreso de las misiones activas de un jugador.

### Detalles del Componente
Controla:

* `active_missions`: `Dictionary`: Almacena el estado de cada `MisionActiva`, incluyendo el `progreso_objetivos`.

### Lógica y Funciones Clave:

* Se suscribe a señales globales del juego (ej. `GlobalSignals.entity_killed`, `GlobalSignals.item_acquired`).
* Cuando recibe una de estas señales, itera sobre sus misiones activas y actualiza el progreso si el evento es relevante para algún objetivo.
* `add_mission(mission_data)`: Añade una misión y sus objetivos al diccionario.
* `turn_in_mission(mission_id)`: Verifica si todos los objetivos están completos y otorga la recompensa.

### Interactúa Con:

* **InteractionComponent**: Para aceptar misiones de NPCs.
* **InventoryComponent**: Para recibir ítems de recompensa o entregar ítems de misión.
* **DataLoader**: Para sincronizar el `progreso_objetivos` con el backend.

### Configuración Data-Driven (Tipo...)
Los datos de la misión (`TipoMision` y `MisionActiva`) provienen enteramente de la base de datos.

---

## 12. StructureComponent
🎯 Propósito Principal: Definir las propiedades de una entidad estática y funcional, como un edificio o un recurso de terreno.

### Detalles del Componente
Controla:

* Su propio **HealthComponent** (para representar su durabilidad).
* `functionality`: `Dictionary`: Describe lo que hace el edificio (ej. `{"type": "crafting_station", "category": "smithing"}` o `{"type": "storage", "capacity": 100}`).

### Lógica y Funciones Clave:

* Actúa principalmente como un proveedor de "funcionalidad" a su alrededor. No tiene una lógica de `_process` activa.
* Los **AIComponent** de los NPCs pueden escanear en busca de **StructureComponents** cercanos para realizar tareas. Un NPC Herrero buscará una Forja (**StructureComponent** de tipo `crafting_station`).

### Interactúa Con:

* **HealthComponent**: Para ser dañado y destruido.
* **AIComponent**: Los NPCs lo utilizan como estación de trabajo.
* **ProductionComponent**: Puede tener su propio **ProductionComponent** si es un edificio productor autónomo.

### Configuración Data-Driven (Tipo...)
En TipoEdificio:

* `efectos_aldea`, `recursos_costo`.

---

## 13. AldeaMetabolismComponent
🎯 Propósito Principal: Simular la economía y el bienestar general de una aldea.

### Detalles del Componente
Controla:

* `update_cycle_seconds`: `float`: Frecuencia con la que se actualiza el metabolismo.
* `consumption_rates`: `Dictionary`: Cuánto de cada recurso (comida, madera, etc.) se consume por ciclo.

### Lógica y Funciones Clave:

* Mediante un `Timer`, se activa periódicamente.
* **Fase de Consumo**: Itera sobre todos los NPCs y edificios de la aldea, suma sus necesidades y resta los recursos del **InventoryComponent** central de la aldea.
* **Fase de Producción**: Suma toda la producción de los edificios y NPCs y la añade al inventario central.
* **Fase de Consecuencias**: Basado en el balance (superávit o déficit), actualiza el **StateComponent** de la aldea (`"is_prosperous"`, `"is_starving"`) y la lealtad de los NPCs en su **OwnershipComponent**.

### Interactúa Con:

* El **InventoryComponent** central de la `InstanciaAldea`.
* Lee los **ProductionComponent** y **HungerComponent** de todos los miembros de la aldea.
* Modifica el **StateComponent** de la aldea y el **OwnershipComponent** de los NPCs.

### Configuración Data-Driven (Tipo...)
Las tasas de consumo y los efectos del estado de la aldea se pueden configurar en un `TipoAldea` si existiera, o en la propia `InstanciaAldea`.

---

## 14. TerrainInteractionComponent
🎯 Propósito Principal: Aplicar los efectos del entorno (terreno, clima) a una entidad.

### Detalles del Componente
Controla:

* `active_effects`: `Dictionary`: Un registro de los efectos de terreno activos y su duración.

### Lógica y Funciones Clave:

* Recibe notificaciones del **MovementComponent** (ej. `on_terrain_entered("lava")`).
* Al recibir la notificación, consulta una tabla de efectos (puede ser un recurso en Godot) para saber qué hacer.
* Aplica el efecto: Llama a `Health.take_damage()`, cambia el **StateComponent** a `{"is_on_fire": true}`, o le dice al **MovementComponent** que cambie de modo.
* Maneja la salida del terreno (`on_terrain_exited`) para remover el efecto.

### Interactúa Con:

* **MovementComponent**: Recibe información del terreno.
* **HealthComponent**: Para aplicar daño.
* **StateComponent**: Para aplicar efectos de estado.

### Configuración Data-Driven (Tipo...)
Los efectos de cada tipo de terreno serían un recurso de configuración en Godot, pero la resistencia de una entidad a estos efectos vendría de su `resistencia_dano` en la BD.

---

## 15. SocialComponent
🎯 Propósito Principal: Gestionar las relaciones de afinidad entre NPCs para crear dinámicas sociales emergentes.

### Detalles del Componente
Controla:

* `relationships`: `Dictionary`: Mapa de afinidad con otras entidades (ej. `{"entity_id_5": 80, "entity_id_8": -50}`).

### Lógica y Funciones Clave:

* `update_affinity(target_id, amount)`: Modifica la afinidad con otra entidad.
* `get_affinity(target_id)`: Consulta el nivel de relación.
* Se puede suscribir a eventos de área para "presenciar" acciones. Si ve al NPC 8 robarle al NPC 5, su afinidad con el 8 disminuirá.

### Interactúa Con:

* **AIComponent**: Usa los datos de afinidad para tomar decisiones sociales. Un NPC protegerá a sus amigos (alta afinidad) y podría sabotear o negarse a trabajar con sus enemigos (baja afinidad).

### Configuración Data-Driven (Tipo...)
Las afinidades iniciales entre `TipoNPCs` podrían definirse en la BD (ej. "los guardias y los ladrones empiezan con -100 de afinidad"). El resto es dinámico.






Falta un componente de LOOT!!!!!!! para ver cuanto deja y para ver los objetos con sus iconos que deja