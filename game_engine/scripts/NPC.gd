# el-ultimo-bastion/game_engine/scripts/NPC.gd
# VERSIÓN CON HealthComponent y HungerComponent integrados, e InventoryComponent referenciado
extends CharacterBody3D
class_name NPC

@onready var name_label: Label3D = $NameLabel 
@onready var health_component: HealthComponent = $HealthComponent 
@onready var hunger_component: HungerComponent = $HungerComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent 

# --- CONSTANTES DE MOVIMIENTO ---
const GRAVITY = 9.8 
const DEFAULT_WANDER_SPEED = 0.5       
const WANDER_RANGE = 5.0       
const WANDER_IDLE_TIME_MIN = 3.0
const WANDER_IDLE_TIME_MAX = 8.0

# --- VARIABLES DE ESTADO ---
var initial_position: Vector3
var wander_target_position: Vector3
var wander_timer: float = 0.0
var can_wander: bool = false
var current_wander_speed: float = DEFAULT_WANDER_SPEED

var npc_id: int
var tipo_npc_id: int
var tipo_npc_data_full: Dictionary

func _ready():
	if not name_label:
		name_label = find_child("NameLabel") 
		if not name_label:
			print(str("-----> ¡ADVERTENCIA! NPC ID ", npc_id, ": NameLabel no encontrado por nombre en _ready(). Asegúrate de que el nodo Label3D se llama 'NameLabel'."))
	
	if health_component and is_instance_valid(health_component):
		health_component.died.connect(Callable(self, "_on_npc_died"))
	else:
		print(str("-----> ¡ERROR! NPC ID ", npc_id, ": HealthComponent no encontrado o no válido en _ready()."))
		
	if hunger_component and is_instance_valid(hunger_component):
		hunger_component.starved.connect(Callable(self, "_on_npc_starved"))
	else:
		print(str("-----> ¡ERROR! NPC ID ", npc_id, ": HungerComponent no encontrado o no válido en _ready()."))
	
	if inventory_component and is_instance_valid(inventory_component): 
		pass 
	else:
		print(str("-----> ¡ERROR! NPC ID ", npc_id, ": InventoryComponent no encontrado o no válido en _ready().")) 


func initialize_npc(instance_data: Dictionary):
	print(str("[DEBUG] NPC ID ", instance_data.get("id", 0), ": initialize_npc() INICIADO."))
	
	npc_id = instance_data.get("id", 0)
	tipo_npc_id = instance_data.get("id_tipo_npc", 0)
	tipo_npc_data_full = instance_data.get("tipo_npc", {})

	var pos_dict = instance_data.get("posicion", {"x": 0.0, "y": 5.0, "z": 0.0})
	initial_position = Vector3(
		float(pos_dict.get("x", 0.0)),
		max(float(pos_dict.get("y", 0.0)), 0.0), 
		float(pos_dict.get("z", 0.0))
	)
	self.global_position = initial_position
	print(str("[DEBUG] NPC ID ", npc_id, ": Posición GLOBAL establecida en: ", self.global_position))
	
	self.collision_layer = 4
	self.collision_mask = 1 | 2 | 4 
	print(str("[DEBUG] NPC ID ", npc_id, ": Capa de colisión: ", self.collision_layer, ", Máscara: ", self.collision_mask))
	
	if name_label and is_instance_valid(name_label):
		name_label.text = str(tipo_npc_data_full.get("nombre", "NPC Desconocido"), " (ID: ", npc_id, ")")
		var visual_height_for_label = tipo_npc_data_full.get("valores_rol", {}).get("hitbox_dimensions", {}).get("height", 1.0)
		name_label.global_position = self.global_position + Vector3(0, visual_height_for_label + 0.5, 0)
		print(str("[DEBUG] NPC ID ", npc_id, ": NameLabel actualizado y posicionado a: ", name_label.text, " en ", name_label.global_position))
	else:
		print(str("-----> ¡ADVERTENCIA! NPC ID ", npc_id, ": NameLabel NO se pudo actualizar/posicionar. Asegúrate de que el nodo Label3D se llama 'NameLabel' y está en la escena."))
	
	var valores_rol = tipo_npc_data_full.get("valores_rol", {})
	can_wander = valores_rol.get("puede_deambular", false)
	current_wander_speed = tipo_npc_data_full.get("initial_velocidad_movimiento", DEFAULT_WANDER_SPEED)
	print(str("[DEBUG] NPC ID ", npc_id, ": Velocidad deambular: ", current_wander_speed))

	var visual_radius = valores_rol.get("hitbox_dimensions", {}).get("radius", 0.5)
	var visual_height = valores_rol.get("hitbox_dimensions", {}).get("height", 1.0)
	var visual_color_hex = valores_rol.get("color", "#00FF00")
	
	print(str("[DEBUG] NPC ID ", npc_id, ": Datos visuales obtenidos: Radio=", visual_radius, ", Altura=", visual_height, ", Color=", visual_color_hex))

	_create_visual_and_hitbox(visual_radius, visual_height, Color(visual_color_hex))
	
	if can_wander:
		_reset_wander_timer()
		print(str("[DEBUG] NPC ID ", npc_id, ": Puede deambular: ", can_wander, ". Temporizador iniciado."))
	else:
		print(str("[DEBUG] NPC ID ", npc_id, ": Puede deambular: ", can_wander, ". Permanecerá estático."))

	# --- Inicializar HealthComponent ---
	if health_component and is_instance_valid(health_component):
		var cvb_data = instance_data.get("criatura_viva_base", {})
		var danio_data = cvb_data.get("danio", {})
		
		var npc_max_health = danio_data.get("salud_max", 100)
		var npc_current_health = danio_data.get("salud_actual", 100)
		var npc_loot_table_id = danio_data.get("loot_table_id", -1)
		var npc_resistance_map = tipo_npc_data_full.get("resistencia_dano", {})

		health_component.initialize_health(npc_id, "NPC", npc_max_health, npc_current_health, npc_loot_table_id, npc_resistance_map)
		print(str("[DEBUG] NPC ID ", npc_id, ": HealthComponent inicializado. Salud: ", npc_current_health, "/", npc_max_health))
	else:
		print(str("-----> ¡ERROR! NPC ID ", npc_id, ": HealthComponent no encontrado o no válido."))

	# --- Inicializar HungerComponent ---
	if hunger_component and is_instance_valid(hunger_component):
		var cvb_data = instance_data.get("criatura_viva_base", {})
		
		var npc_max_hunger = cvb_data.get("hambre_max", 100)
		var npc_current_hunger = cvb_data.get("hambre_actual", 100)
		
		hunger_component.initialize_hunger(npc_id, "NPC", npc_max_hunger, npc_current_hunger)
		print(str("[DEBUG] NPC ID ", npc_id, ": HungerComponent inicializado. Hambre: ", npc_current_hunger, "/", npc_max_hunger))
	else:
		print(str("-----> ¡ERROR! NPC ID ", npc_id, ": HungerComponent no encontrado o no válido."))

	# --- Inicializar InventoryComponent ---
	if inventory_component and is_instance_valid(inventory_component): 
		var cvb_data = instance_data.get("criatura_viva_base", {})
		var inv_data = cvb_data.get("inventario", {})
		
		var npc_inventory_id = inv_data.get("id", -1)
		var npc_max_slots = inv_data.get("capacidad_slots", 10)
		var npc_max_weight = float(inv_data.get("capacidad_peso_kg", 100.0))
		var npc_items = inv_data.get("contenido", {}) 
		
		var default_item_data = {"nombre": "Item Desconocido", "peso_unidad": 1.0, "es_apilable": false}
		var items_with_data = {}
		for item_id_str in npc_items:
			var item_id_int = int(item_id_str)
			items_with_data[item_id_int] = {
				"quantity": npc_items[item_id_str].get("quantity", 0),
				"item_data": default_item_data
			}

		inventory_component.initialize_inventory(npc_id, "NPC", npc_inventory_id, npc_max_slots, npc_max_weight, items_with_data)
		print(str("[DEBUG] NPC ID ", npc_id, ": InventoryComponent inicializado. Slots: ", npc_max_slots, ", Peso: ", npc_max_weight))
	else:
		print(str("-----> ¡ERROR! NPC ID ", npc_id, ": InventoryComponent no encontrado o no válido."))


	print(str("[DEBUG] NPC ID ", npc_id, ": Inicialización COMPLETA."))

func _create_visual_and_hitbox(radius: float, height: float, color: Color):
	print(str("[DEBUG] NPC ID ", npc_id, ": _create_visual_and_hitbox() llamado. Param: R=", radius, ", H=", height, ", C=", color))
	
	for child in get_children():
		if (child is MeshInstance3D and child.name == "NPCVisualModel") or \
		   (child is CollisionShape3D and child.name == "NPCHitboxCollision"):
			print(str("[DEBUG] NPC ID ", npc_id, ": Eliminando hijo existente: ", child.name))
			child.queue_free()
		
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "NPCVisualModel" 
	
	var visual_mesh = CapsuleMesh.new()
	visual_mesh.radius = radius
	visual_mesh.height = height
	mesh_instance.mesh = visual_mesh
	
	var npc_material = StandardMaterial3D.new()
	npc_material.albedo_color = color
	mesh_instance.material_override = npc_material
	
	mesh_instance.position.y = height / 2.0 
	add_child(mesh_instance)
	print(str("[DEBUG] NPC ID ", npc_id, ": Nuevo MeshInstance3D 'NPCVisualModel' creado y añadido. Posición local Y: ", mesh_instance.position.y))

	var default_hitbox = CollisionShape3D.new()
	default_hitbox.name = "NPCHitboxCollision" 
	var default_shape = CapsuleShape3D.new()
	default_shape.radius = radius
	default_shape.height = height
	default_hitbox.shape = default_shape
	
	default_hitbox.position.y = height / 2.0
	add_child(default_hitbox)
	print(str("[DEBUG] NPC ID ", npc_id, ": Nuevo CollisionShape3D 'NPCHitboxCollision' creado y añadido. Posición local Y: ", default_hitbox.position.y))

	print(str("[DEBUG] NPC ID ", npc_id, ": _create_visual_and_hitbox() COMPLETO."))


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0

	if can_wander:
		if global_position.distance_to(wander_target_position) < 0.5:
			wander_timer -= delta
			if wander_timer <= 0:
				_set_new_wander_target()
				_reset_wander_timer()
		else:
			var direction = global_position.direction_to(wander_target_position)
			velocity.x = direction.x * current_wander_speed
			velocity.z = direction.z * current_wander_speed
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _reset_wander_timer():
	wander_timer = randf_range(WANDER_IDLE_TIME_MIN, WANDER_IDLE_TIME_MAX)

func _set_new_wander_target():
	var rand_x = randf_range(-WANDER_RANGE, WANDER_RANGE)
	var rand_z = randf_range(-WANDER_RANGE, WANDER_RANGE)
	wander_target_position = initial_position + Vector3(rand_x, 0, rand_z)
	print(str("[DEBUG] NPC ID ", npc_id, ": Nuevo objetivo de deambulación: ", wander_target_position))

func _on_npc_died(entity_id: int, entity_type: String):
	print(str("[DEBUG] NPC ID ", npc_id, ": Recibida señal de muerte de HealthComponent. Murió ID: ", entity_id, ", Tipo: ", entity_type))
	pass

func _on_npc_starved(entity_id: int, entity_type: String):
	print(str("[DEBUG] NPC ID ", npc_id, ": Recibida señal de inanición de HungerComponent. NPC (", entity_type, " ID: ", entity_id, ") se ha muerto de hambre."))
	pass
