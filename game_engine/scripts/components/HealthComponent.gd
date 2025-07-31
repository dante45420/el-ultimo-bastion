# res://components/HealthComponent.gd
# VERSIÓN CON SISTEMA DE LOOT DROPS
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

# --- NUEVAS VARIABLES PARA LOOT ---
var loot_settings: Dictionary = {}

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

func initialize_health(p_entity_id: int, p_entity_type: String, p_max_health: int, p_current_health: int, p_loot_table_id: int = -1, p_resistance_map: Dictionary = {}, p_loot_settings: Dictionary = {}):
	entity_id = p_entity_id
	entity_type = p_entity_type
	max_health = p_max_health
	current_health = p_current_health
	loot_table_id = p_loot_table_id
	resistance_map = p_resistance_map
	loot_settings = p_loot_settings
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
	
	# 🎁 NUEVO: GENERAR LOOT ANTES DE OCULTAR EL NPC
	if entity_type == "NPC" and loot_settings.size() > 0:
		_generate_loot_drops()
	
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

# 🎁 NUEVA FUNCIÓN: GENERAR LOOT DROPS CON FORMATO NUEVO
func _generate_loot_drops():
	if debug_mode: print(str("🎁 [LOOT] Generando loot para ", entity_type, " ID: ", entity_id))
	if debug_mode: print(str("🎁 [LOOT] Settings: ", JSON.stringify(loot_settings)))
	
	var drop_position = get_parent().global_position
	var loot_items = []
	
	# 🆕 SISTEMA NUEVO: Usar loot_table del formulario
	var drops_loot = loot_settings.get("drops_loot_on_death", false)
	var loot_table = loot_settings.get("loot_table", [])
	
	if drops_loot and loot_table.size() > 0:
		if debug_mode: print("🎁 [LOOT] Usando nuevo sistema de loot_table")
		
		for loot_entry in loot_table:
			var probabilidad = loot_entry.get("probabilidad", 0.5)
			var random_chance = randf()
			
			if debug_mode: print(str("🎲 [LOOT] Objeto: ", loot_entry.get("nombre", "?"), " - Probabilidad: ", probabilidad, " - Tirada: ", random_chance))
			
			if random_chance <= probabilidad:
				var cantidad_min = loot_entry.get("cantidad_min", 1)
				var cantidad_max = loot_entry.get("cantidad_max", 1)
				var cantidad_final = randi_range(cantidad_min, cantidad_max)
				
				var item_data = {
					"tipo": "objeto_loot",
					"nombre": loot_entry.get("nombre", "Objeto desconocido"),
					"cantidad": cantidad_final,
					"objeto_id": loot_entry.get("objeto_id", null)
				}
				
				loot_items.append(item_data)
				if debug_mode: print(str("✅ [LOOT] ¡Drop exitoso! ", item_data.nombre, " x", cantidad_final))
			else:
				if debug_mode: print(str("❌ [LOOT] No dropea: ", loot_entry.get("nombre", "?")))
	
	# 🔄 SISTEMA LEGACY: Para compatibilidad con loot antiguo
	else:
		if debug_mode: print("🎁 [LOOT] Usando sistema legacy de loot")
		
		# 🥩 CARNE (drop_meat_chance y drop_meat_quantity)
		var meat_chance = loot_settings.get("drop_meat_chance", 0.0)
		var meat_quantity = loot_settings.get("drop_meat_quantity", 1.0)
		
		if randf() <= meat_chance:
			for i in range(int(meat_quantity)):
				loot_items.append({
					"tipo": "carne",
					"nombre": "Carne",
					"cantidad": 1,
					"objeto_id": 1  # Asumimos que "Carne" es el ID 1
				})
			if debug_mode: print(str("🥩 [LOOT] Dropeando ", int(meat_quantity), " unidades de carne"))
		
		# 📦 OBJETOS DEL INVENTARIO (drop_inventory_chance)
		var inventory_chance = loot_settings.get("drop_inventory_chance", 0.0)
		if randf() <= inventory_chance:
			if debug_mode: print("📦 [LOOT] Dropeando inventario del NPC (TODO)")
		
		# 💎 OBJETOS ESPECIALES (drop_objects_chance) 
		var objects_chance = loot_settings.get("drop_objects_chance", 0.0)
		if randf() <= objects_chance:
			if debug_mode: print("💎 [LOOT] Dropeando objetos especiales (TODO)")
	
	# 🌍 CREAR LOS OBJETOS EN EL MUNDO
	for i in range(loot_items.size()):
		var item = loot_items[i]
		var spread_position = drop_position + Vector3(
			randf_range(-2.0, 2.0),  # Spread horizontal
			1.0,                     # Altura para que aparezca visible
			randf_range(-2.0, 2.0)   # Spread horizontal
		)
		_create_world_loot_object(item, spread_position)
	
	if debug_mode: print(str("🎁 [LOOT] Total de objetos dropeados: ", loot_items.size()))

# 🌍 FUNCIÓN MEJORADA: CREAR OBJETO LOOT CON COLORES POR TIPO
func _create_world_loot_object(item_data: Dictionary, position: Vector3):
	var loot_object = StaticBody3D.new()
	loot_object.name = str("Loot_", item_data.get("nombre", "Unknown"))
	
	# 🤲 MARCAR COMO LOOT PARA PICKUP
	loot_object.set_meta("is_loot", true)
	loot_object.set_meta("loot_data", item_data)
	loot_object.add_to_group("loot_objects")  # Agregar al grupo para búsqueda fácil
	
	# Visual del objeto (una cápsula por ahora)
	var mesh_instance = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	mesh_instance.mesh = mesh
	
	# Material del objeto (color según el nombre/tipo)
	var material = StandardMaterial3D.new()
	var nombre = item_data.get("nombre", "").to_lower()
	
	# Colores por tipo de objeto
	if "carne" in nombre:
		material.albedo_color = Color(0.8, 0.4, 0.3)  # Rojo carne
	elif "oro" in nombre:
		material.albedo_color = Color(1.0, 0.8, 0.0)  # Dorado
	elif "hierro" in nombre:
		material.albedo_color = Color(0.6, 0.6, 0.7)  # Gris metálico
	elif "pocion" in nombre or "poción" in nombre:
		material.albedo_color = Color(0.2, 0.8, 0.2)  # Verde
	elif "gema" in nombre or "cristal" in nombre:
		material.albedo_color = Color(0.8, 0.2, 0.8)  # Púrpura
	elif "hueso" in nombre:
		material.albedo_color = Color(0.9, 0.9, 0.8)  # Blanco hueso
	else:
		material.albedo_color = Color(0.7, 0.7, 0.7)  # Gris por defecto
	
	material.emission = Color(0.2, 0.2, 0.1)  # Brillo sutil
	mesh_instance.material_override = material
	
	# Collision shape para el loot
	var collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.2
	shape.height = 0.4
	collision_shape.shape = shape
	
	# 🤲 Area3D para detección de pickup automático
	var pickup_area = Area3D.new()
	pickup_area.name = "PickupArea"
	pickup_area.collision_layer = 0  # No colisiona físicamente
	pickup_area.collision_mask = 2   # Detecta al jugador (capa 2)
	
	var pickup_shape = CollisionShape3D.new()
	var pickup_collision = SphereShape3D.new()
	pickup_collision.radius = 1.5  # Radio de pickup automático
	pickup_shape.shape = pickup_collision
	pickup_area.add_child(pickup_shape)
	
	# 🆕 CONECTAR SEÑAL PARA PICKUP AUTOMÁTICO
	pickup_area.body_entered.connect(_on_pickup_area_entered.bind(loot_object, item_data))
	
	# Label con el nombre del objeto
	var label = Label3D.new()
	label.text = str(item_data.get("nombre", "?"), " x", item_data.get("cantidad", 1))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 0.8
	label.modulate = Color.WHITE
	label.outline_size = 2
	label.outline_modulate = Color.BLACK
	
	# 🆕 PROMPT DE PICKUP (sin font_size_override que causa error)
	var pickup_label = Label3D.new()
	pickup_label.text = "Presiona R para recoger"
	pickup_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pickup_label.position.y = 1.2
	pickup_label.modulate = Color.YELLOW
	pickup_label.outline_size = 1
	pickup_label.outline_modulate = Color.BLACK
	pickup_label.visible = false  # Solo visible cuando el jugador esté cerca
	
	# Ensamblar el objeto
	loot_object.add_child(mesh_instance)
	loot_object.add_child(collision_shape)
	loot_object.add_child(pickup_area)
	loot_object.add_child(label)
	loot_object.add_child(pickup_label)
	
	# Posicionarlo
	loot_object.global_position = position
	
	# Agregar al mundo
	get_tree().root.add_child(loot_object)
	
	# 🎆 EFECTO VISUAL: Animación de aparición
	var tween = get_tree().create_tween()
	loot_object.scale = Vector3.ZERO
	tween.tween_property(loot_object, "scale", Vector3.ONE, 0.3)
	tween.tween_property(loot_object, "position:y", position.y + 0.2, 0.2)
	tween.tween_property(loot_object, "position:y", position.y, 0.2)
	
	print(str("💎 [LOOT] Objeto creado en el mundo: ", item_data.nombre, " en posición ", position))

# 🆕 NUEVA FUNCIÓN: Manejar pickup cuando el jugador entra al área
func _on_pickup_area_entered(body: Node, loot_object: StaticBody3D, item_data: Dictionary):
	if body.has_method("add_item_to_inventory"):
		print(str("🤲 [LOOT] Pickup automático: ", item_data.get("nombre", "Objeto")))
		
		# 🆕 ARREGLAR ID DE OBJETO: convertir string a int
		var objeto_id = item_data.get("objeto_id", null)
		if objeto_id is String:
			objeto_id = int(objeto_id)
		elif objeto_id == null:
			objeto_id = -1  # Para objetos personalizados sin ID
		
		# Crear datos corregidos para el inventario
		var corrected_data = {
			"tipo": item_data.get("tipo", "objeto_loot"),
			"nombre": item_data.get("nombre", "Objeto desconocido"),
			"cantidad": item_data.get("cantidad", 1),
			"tipo_objeto_id": objeto_id  # ✅ ID corregido
		}
		
		print(str("🔧 [LOOT] Datos corregidos: ", corrected_data))
		body.add_item_to_inventory(corrected_data)
		loot_object.queue_free()
	
	# Mostrar prompt de pickup manual también
	var pickup_label = loot_object.get_node_or_null("Label3D2")  # El segundo label3D
	if pickup_label:
		pickup_label.visible = true
