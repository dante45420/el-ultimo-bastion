# res://components/HealthComponent.gd
extends Node
class_name HealthComponent

# --- Exported Variables (para configurar desde el editor o si se desea visibilidad) ---
@export var debug_mode: bool = true 
@export var health_regeneration_rate: float = 0.0 # Puntos de salud regenerados por segundo (por defecto 0)

# --- Variables internas del componente ---
var entity_id: int = -1 
var entity_type: String 
var max_health: int = 1 
var current_health: int = 1 
var loot_table_id: int = -1 
var resistance_map: Dictionary = {}

var data_loader: DataLoader

signal health_changed(new_health: int, max_health: int)
signal died(entity_id: int, entity_type: String)

func _ready():
	if debug_mode: print(str("[DEBUG] HealthComponent: _ready() para ", entity_type, " ID: ", entity_id))
	
	data_loader = get_node_or_null("/root/MainScene/World_Node/DataLoader")
	if not data_loader:
		if debug_mode: print("-----> ¡ERROR! HealthComponent: DataLoader no encontrado.")

func _process(delta):
	# Regeneración pasiva de salud
	if current_health < max_health and health_regeneration_rate > 0:
		heal(health_regeneration_rate * delta)

func initialize_health(p_entity_id: int, p_entity_type: String, p_max_health: int, p_current_health: int, p_loot_table_id: int = -1, p_resistance_map: Dictionary = {}):
	entity_id = p_entity_id
	entity_type = p_entity_type
	max_health = p_max_health
	current_health = p_current_health
	loot_table_id = p_loot_table_id
	resistance_map = p_resistance_map
	if debug_mode: print(str("[DEBUG] HealthComponent: Inicializado para ", entity_type, " ID: ", entity_id, ". Salud: ", current_health, "/", max_health, ". Resistencias: ", resistance_map))
	emit_signal("health_changed", current_health, max_health)

func take_damage(amount: float, damage_type: String = "PHYSICAL"):
	if current_health <= 0:
		if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " ya está muerto. No recibe más daño."))
		return

	var final_damage = amount
	if resistance_map.has(damage_type):
		final_damage *= resistance_map[damage_type]
		if debug_mode: print(str("[DEBUG] HealthComponent: Daño ", damage_type, " ajustado por resistencia. Final Damage: ", final_damage))
	
	current_health -= int(final_damage)
	current_health = max(0, current_health) 

	if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " recibió ", final_damage, " de daño (", damage_type, "). Salud actual: ", current_health))
	emit_signal("health_changed", current_health, max_health)

	if current_health <= 0:
		if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " ha MUERTO."))
		emit_signal("died", entity_id, entity_type)
		_handle_death_logic()

func heal(amount: float):
	if current_health <= 0:
		if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " muerto, no puede ser curado."))
		return
	current_health += int(amount)
	current_health = min(current_health, max_health) 
	if debug_mode: print(str("[DEBUG] HealthComponent: ", entity_type, " ID: ", entity_id, " curado por ", amount, ". Salud actual: ", current_health))
	emit_signal("health_changed", current_health, max_health)

func _handle_death_logic():
	if debug_mode: print(str("[DEBUG] HealthComponent: Lógica de muerte para ", entity_type, " ID: ", entity_id, " (loot_table_id: ", loot_table_id, ")"))
	
	# Desactivar la física y la visibilidad del nodo padre (CharacterBody3D)
	if get_parent() is CharacterBody3D:
		get_parent().set_collision_mask(0) # Deja de colisionar con todo
		get_parent().set_physics_process(false) # Detiene el movimiento
		
		# Ocultar visual del padre
		var visual_node = get_parent().find_child("DefaultVisualModel") # Para Player
		if not visual_node: visual_node = get_parent().find_child("NPCVisualModel") # Para NPC
		
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
			timer.wait_time = 5.0 
			timer.one_shot = true
			timer.timeout.connect(func(): get_parent().queue_free())
			timer.start()
