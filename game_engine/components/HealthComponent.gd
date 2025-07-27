# res://components/HealthComponent.gd
extends Node
class_name HealthComponent

# --- Exported Variables (para configurar desde el editor o si se desea visibilidad) ---
@export var debug_mode: bool = true # Para prints de depuración del componente

# --- Variables internas del componente ---
var entity_id: int = -1 # El ID de la entidad a la que pertenece este componente (NPC ID o Bastion ID)
var entity_type: String # "NPC" o "Bastion"
var max_health: int = 1 # Salud máxima
var current_health: int = 1 # Salud actual
var loot_table_id: int = -1 # ID de la tabla de loot si aplica (para NPCs)
var resistance_map: Dictionary = {} # {"FIRE": 0.5, "SLASHING": 1.2}

# Referencia al DataLoader para sincronizar con el backend
var data_loader: DataLoader

# --- Señales del componente (para que el padre o la UI se suscriban) ---
signal health_changed(new_health: int, max_health: int)
signal died(entity_id: int, entity_type: String) # Emite quién murió

func _ready():
	if debug_mode: print(str("[DEBUG] HealthComponent: _ready() para ", entity_type, " ID: ", entity_id))

	# Intentar obtener el DataLoader del árbol de la escena
	data_loader = get_node_or_null("/root/MainScene/World_Node/DataLoader")
	if not data_loader:
		if debug_mode: print("-----> ¡ERROR! HealthComponent: DataLoader no encontrado.")

# Función para inicializar el componente con datos de la entidad
func initialize_health(p_entity_id: int, p_entity_type: String, p_max_health: int, p_current_health: int, p_loot_table_id: int = -1, p_resistance_map: Dictionary = {}):
	entity_id = p_entity_id
	entity_type = p_entity_type
	max_health = p_max_health
	current_health = p_current_health
	loot_table_id = p_loot_table_id
	resistance_map = p_resistance_map
	if debug_mode: print(str("[DEBUG] HealthComponent: Inicializado para ", entity_type, " ID: ", entity_id, ". Salud: ", current_health, "/", max_health))
	emit_signal("health_changed", current_health, max_health)

# Función para recibir daño
func take_damage(amount: float, damage_type: String = "PHYSICAL"):
	if current_health <= 0:
		if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " ya está muerto. No recibe más daño."))
		return

	var final_damage = amount
	if resistance_map.has(damage_type):
		final_damage *= resistance_map[damage_type]
		if debug_mode: print(str("[DEBUG] HealthComponent: Daño ", damage_type, " ajustado por resistencia. Final Damage: ", final_damage))

	current_health -= int(final_damage)
	current_health = max(0, current_health) # Asegura que la salud no baje de 0

	if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " recibió ", final_damage, " de daño (", damage_type, "). Salud actual: ", current_health))
	emit_signal("health_changed", current_health, max_health)

	if current_health <= 0:
		if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " ha MUERTO."))
		emit_signal("died", entity_id, entity_type)
		_handle_death_logic()

# Función para curar
func heal(amount: float):
	if current_health <= 0:
		if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " muerto, no puede ser curado."))
		return
	current_health += int(amount)
	current_health = min(current_health, max_health) # Asegura que la salud no exceda la máxima
	if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " curado por ", amount, ". Salud actual: ", current_health))
	emit_signal("health_changed", current_health, max_health)

# Lógica que se ejecuta al morir
func _handle_death_logic():
	# TODO: Sincronizar la muerte con el backend (InstanciaNPC.esta_vivo = false)
	# TODO: Activar LootComponent para soltar ítems
	if debug_mode: print(str("[DEBUG] HealthComponent: Lógica de muerte para ", entity_type, " ID: ", entity_id, " (loot_table_id: ", loot_table_id, ")"))

	if data_loader and entity_type == "NPC":
		# Si es un NPC, notificamos al backend que ha muerto
		# El backend debe tener un endpoint para actualizar InstanciaNPC.esta_vivo
		# Por ahora, solo es un ejemplo de cómo llamarías al DataLoader
		# data_loader.update_instancia_npc_status(entity_id, {"esta_vivo": false}, Callable(self, "_on_npc_death_sync_success"), Callable(self, "_on_npc_death_sync_failed"))
		pass # No implementaremos el sync completo ahora

	# Desactivar la física y la visibilidad del nodo padre (NPC o Player)
	if get_parent() is CharacterBody3D:
		get_parent().set_collision_mask(0) # Deja de colisionar con todo
		get_parent().set_physics_process(false) # Detiene el movimiento
		# Si el nodo padre tiene un VisualComponent o MeshInstance3D, lo haremos invisible
		var visual_node = get_parent().find_child("NPCVisualModel") # O "DefaultVisualModel" para el jugador
		if visual_node and is_instance_valid(visual_node):
			visual_node.visible = false

		# Quitar la etiqueta de nombre
		var name_label_node = get_parent().find_child("NameLabel")
		if name_label_node and is_instance_valid(name_label_node):
			name_label_node.visible = false

		# Después de una pequeña pausa, liberar el nodo si es un NPC
		if entity_type == "NPC":
			var timer = Timer.new()
			add_child(timer)
			timer.wait_time = 5.0 # Espera 5 segundos antes de liberar
			timer.one_shot = true
			timer.timeout.connect(func(): get_parent().queue_free())
			timer.start()
