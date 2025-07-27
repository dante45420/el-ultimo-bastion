# el-ultimo-bastion/game_engine/scripts/Player.gd
# VERSIÓN COMPLETA Y CORREGIDA CON TODOS LOS COMPONENTES Y FUNCIONALIDADES
extends CharacterBody3D
class_name Player

#-----------------------------------------------------------------------------
# EXPORTED VARIABLES - Propiedades configurables desde el editor de Godot
#-----------------------------------------------------------------------------
@export var speed = 7.0
@export var jump_velocity = 8.0
@export var mouse_sensitivity = 0.003
@export var user_id_for_bastion: int = 2 # <--- ASEGÚRATE QUE ESTE ID COINCIDE CON TU player_one EN LA DB

@export var attack_ray_length: float = 5.0 # Longitud del rayo de ataque
@export var player_base_damage: float = 10.0 # Daño que el jugador inflige
@export var attack_debug_line_duration: float = 0.2 # Duración de la línea de depuración del ataque

#-----------------------------------------------------------------------------
# CLASS VARIABLES - Propiedades internas del jugador
#-----------------------------------------------------------------------------
var camera_spring_arm: SpringArm3D
var data_loader: DataLoader
var bastion_id: int = 0 # Declarada como variable de clase

@onready var health_component: HealthComponent = $HealthComponent
@onready var hunger_component: HungerComponent = $HungerComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent

# Stats del personaje (Variables de clase, actualizadas por componentes)
var current_health: int = 0 # Declarada como variable de clase
var max_health: int = 0     # Declarada como variable de clase
var current_hunger: int = 0
var max_hunger: int = 0

# Nodos de la UI
var ui_canvas: CanvasLayer
var health_label: Label
var hunger_label: Label
var debug_damage_button: Button
var debug_eat_button: Button
var debug_open_inventory_button: Button
var inventory_panel: PanelContainer
var inventory_label: Label

# Constantes de física
const GRAVITY = 9.8

#-----------------------------------------------------------------------------
# GODOT ENGINE FUNCTIONS - Métodos llamados automáticamente por el motor
#-----------------------------------------------------------------------------

func _ready():
	print("[PLAYER-DEBUG] _ready() INICIADO.")
	
	self.collision_layer = 2 # El jugador está en la capa 2 ("jugador")
	self.collision_mask = 1 | 4 # Jugador colisiona con Capa 1 (mundo) Y Capa 4 (NPCs)
	print(str("[PLAYER-DEBUG] Física configurada. Capa: ", self.collision_layer, ", Máscara: ", self.collision_mask))

	camera_spring_arm = get_node_or_null("CameraSpringArm")
	if camera_spring_arm:
		camera_spring_arm.spring_length = 5.0
		print("[PLAYER-DEBUG] SpringArm encontrado. Longitud establecida a 5.0.")
	else:
		print("-----> ¡PLAYER-ERROR! No se encontró el nodo hijo 'CameraSpringArm'.")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	data_loader = get_node_or_null("/root/MainScene/World_Node/DataLoader") 
	if data_loader and is_instance_valid(data_loader):
		print("[PLAYER-DEBUG] DataLoader encontrado y válido.")
		
		print(str("[PLAYER-DEBUG] Solicitando datos del Bastion para el usuario ID: ", user_id_for_bastion))
		data_loader.get_bastion_by_user_id(
			user_id_for_bastion,
			Callable(self, "_on_bastion_loaded"), 
			Callable(self, "_on_data_loader_failed")
		)
	else:
		print("-----> ¡PLAYER-ERROR CRÍTICO! No se pudo encontrar el DataLoader en la ruta especificada.")
	
	_setup_debug_ui()
	print("[PLAYER-DEBUG] _ready() COMPLETADO.")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _input(event):
	if event.is_action_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity * 100.0
		var current_pitch = camera_spring_arm.rotation_degrees.x - event.relative.y * mouse_sensitivity * 100.0
		camera_spring_arm.rotation_degrees.x = clamp(current_pitch, -70, 70)
	
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# --- Lógica de Ataque con Click Izquierdo ---
	if event.is_action_pressed("attack") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: 
		_perform_attack()

	# --- Abrir/Cerrar Inventario con 'I' ---
	if event.is_action_pressed("toggle_inventory"): 
		_toggle_inventory_ui()


#-----------------------------------------------------------------------------
# CUSTOM FUNCTIONS - Métodos propios de la clase
#-----------------------------------------------------------------------------

func _on_bastion_loaded(data, _status_code):
	if data is Dictionary and data.has("id_usuario") and data.has("nombre_personaje"):
		print("[PLAYER-DEBUG] ¡Datos del Bastion recibidos exitosamente desde el servidor!")
		bastion_id = data.get("id", 0) 
		
		var pos_dict = data.get("posicion_actual", {"x":0.0, "y":10.0, "z":0.0}) 
		self.global_position = Vector3(float(pos_dict.get("x", 0.0)), float(pos_dict.get("y", 10.0)), float(pos_dict.get("z", 0.0)))
		print(str("[PLAYER-DEBUG] Posición del jugador establecida en: ", self.global_position))
		
		var hitbox_dims = pos_dict.get("hitbox_dimensions", {"radius": 0.4, "height": 1.7})
		
		print("[PLAYER-DEBUG] Creando visual del jugador.")
		_create_default_visual_and_hitbox(hitbox_dims.get("radius", 0.4), hitbox_dims.get("height", 1.7))

		# Inicializar HealthComponent y conectar señal
		if health_component and is_instance_valid(health_component):
			var cvb_data = data.get("criatura_viva_base", {})
			var danio_data = cvb_data.get("danio", {})
			
			var player_max_health = danio_data.get("salud_max", 100)
			var player_current_health = danio_data.get("salud_actual", 100)
			
			health_component.initialize_health(bastion_id, "Bastion", player_max_health, player_current_health)
			health_component.health_changed.connect(Callable(self, "_on_player_health_changed"))
			health_component.died.connect(Callable(self, "_on_player_died"))
			
			_on_player_health_changed(player_current_health, player_max_health)

			print(str("[PLAYER-DEBUG] HealthComponent del jugador inicializado. Salud: ", player_current_health, "/", player_max_health))
		else:
			print("-----> ¡PLAYER-ERROR! HealthComponent no encontrado o no válido en el jugador.")

		# Inicializar HungerComponent y conectar señal
		if hunger_component and is_instance_valid(hunger_component):
			var cvb_data = data.get("criatura_viva_base", {})
			
			var player_max_hunger = cvb_data.get("hambre_max", 100)
			var player_current_hunger = cvb_data.get("hambre_actual", 100)
			
			hunger_component.initialize_hunger(bastion_id, "Bastion", player_max_hunger, player_current_hunger)
			hunger_component.hunger_changed.connect(Callable(self, "_on_player_hunger_changed"))
			hunger_component.starved.connect(Callable(self, "_on_player_starved"))

			_on_player_hunger_changed(player_current_hunger, player_max_hunger)

			print(str("[PLAYER-DEBUG] HungerComponent del jugador inicializado. Hambre: ", player_current_hunger, "/", player_max_hunger))
		else:
			print("-----> ¡PLAYER-ERROR! HungerComponent no encontrado o no válido en el jugador.")

		# Inicializar InventoryComponent y conectar señal
		if inventory_component and is_instance_valid(inventory_component): 
			var cvb_data = data.get("criatura_viva_base", {})
			var inv_data = cvb_data.get("inventario", {})
			
			var player_inventory_id = inv_data.get("id", -1)
			var player_max_slots = inv_data.get("capacidad_slots", 25)
			var player_max_weight = float(inv_data.get("capacidad_peso_kg", 50.0))
			var player_items = inv_data.get("contenido", {}) 
			
			# Obtener datos de TipoObjeto para los ítems del inventario si el backend los proporciona
			# Esto es un placeholder; idealmente, DataLoader tendría una función para obtener detalles de TipoObjeto
			var default_item_data = {"nombre": "Item Desconocido", "peso_unidad": 1.0, "es_apilable": false}
			var items_with_data = {}
			for item_id_str in player_items:
				var item_id_int = int(item_id_str)
				items_with_data[item_id_int] = {
					"quantity": player_items[item_id_str].get("quantity", 0),
					# Para simplificar, asumimos que todos los items iniciales tienen este default_item_data
					# En un juego real, aquí harías una llamada a la API para obtener el TipoObjeto completo
					"item_data": default_item_data
				}
			
			inventory_component.initialize_inventory(bastion_id, "Bastion", player_inventory_id, player_max_slots, player_max_weight, items_with_data)
			inventory_component.inventory_changed.connect(Callable(self, "_on_player_inventory_changed"))

			_on_player_inventory_changed(items_with_data)

			print(str("[PLAYER-DEBUG] InventoryComponent del jugador inicializado. Slots: ", player_max_slots, ", Peso: ", player_max_weight))
		else:
			print("-----> ¡PLAYER-ERROR! InventoryComponent no encontrado o no válido en el jugador.")


func _on_data_loader_failed(status_code, error_data):
	var error_message = error_data.get("message", "")
	if str("usuario ", user_id_for_bastion) in error_message:
		print(str("-----> ¡PLAYER-ERROR! La solicitud de datos del Bastion falló. Código: ", status_code, ", Datos: ", error_data))
		print("-----> PLAYER: Creando un jugador por defecto porque la carga desde la DB falló.")
		_create_default_visual_and_hitbox(0.5, 1.8)

		if health_component and is_instance_valid(health_component):
			health_component.initialize_health(0, "Bastion", 100, 100) 
			health_component.health_changed.connect(Callable(self, "_on_player_health_changed"))
			health_component.died.connect(Callable(self, "_on_player_died"))
			_on_player_health_changed(100, 100)
			print("[PLAYER-DEBUG] HealthComponent del jugador inicializado con valores por defecto.")
		
		if hunger_component and is_instance_valid(hunger_component):
			hunger_component.initialize_hunger(0, "Bastion", 100, 100) 
			hunger_component.hunger_changed.connect(Callable(self, "_on_player_hunger_changed"))
			hunger_component.starved.connect(Callable(self, "_on_player_starved"))
			_on_player_hunger_changed(100, 100)
			print("[PLAYER-DEBUG] HungerComponent del jugador inicializado con valores por defecto.")
		
		if inventory_component and is_instance_valid(inventory_component): 
			inventory_component.initialize_inventory(0, "Bastion", -1, 25, 50.0)
			inventory_component.inventory_changed.connect(Callable(self, "_on_player_inventory_changed"))
			_on_player_inventory_changed({})
			print("[PLAYER-DEBUG] InventoryComponent del jugador inicializado con valores por defecto.")

func _create_default_visual_and_hitbox(radius: float, height: float):
	for child in get_children():
		if child is MeshInstance3D or child is CollisionShape3D:
			child.queue_free()

	print(str("[PLAYER-DEBUG] Creando visual por defecto con radio ", radius, " y altura ", height))
	var default_visual = MeshInstance3D.new()
	default_visual.name = "DefaultVisualModel"
	var default_mesh = CapsuleMesh.new()
	default_mesh.radius = radius
	default_mesh.height = height
	var player_material = StandardMaterial3D.new()
	player_material.albedo_color = Color.MAGENTA
	default_visual.material_override = player_material
	default_visual.mesh = default_mesh
	
	default_visual.position.y = height / 2.0
	add_child(default_visual)

	var default_hitbox = CollisionShape3D.new()
	default_hitbox.name = "DefaultHitboxCollision"
	var default_shape = CapsuleShape3D.new()
	default_shape.radius = radius
	default_shape.height = height
	default_hitbox.shape = default_shape
	default_hitbox.position.y = height / 2.0
	add_child(default_hitbox)
	print("[PLAYER-DEBUG] Creado visual (Cápsula Magenta) y hitbox por defecto.")

func _setup_debug_ui():
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)

	var stats_panel = PanelContainer.new()
	stats_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	stats_panel.set_custom_minimum_size(Vector2(200, 150))
	stats_panel.position = Vector2(10, 10)
	ui_canvas.add_child(stats_panel)
	var stats_v_box = VBoxContainer.new()
	stats_panel.add_child(stats_v_box)
	health_label = Label.new()
	health_label.text = "Salud: N/A"
	stats_v_box.add_child(health_label)
	hunger_label = Label.new()
	hunger_label.text = "Hambre: N/A"
	stats_v_box.add_child(hunger_label)

	debug_damage_button = Button.new()
	debug_damage_button.text = "Recibir Daño (10)"
	debug_damage_button.pressed.connect(Callable(self, "_on_debug_damage_button_pressed"))
	stats_v_box.add_child(debug_damage_button)

	debug_eat_button = Button.new()
	debug_eat_button.text = "Comer (20 Hambre)"
	debug_eat_button.pressed.connect(Callable(self, "_on_debug_eat_button_pressed"))
	stats_v_box.add_child(debug_eat_button)

	debug_open_inventory_button = Button.new()
	debug_open_inventory_button.text = "Abrir Inventario (I)"
	debug_open_inventory_button.pressed.connect(Callable(self, "_toggle_inventory_ui"))
	stats_v_box.add_child(debug_open_inventory_button)
	
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	inventory_panel.set_custom_minimum_size(Vector2(400, 300))
	inventory_panel.visible = false
	ui_canvas.add_child(inventory_panel)
	var inv_v_box = VBoxContainer.new()
	inventory_panel.add_child(inv_v_box)
	
	var inv_title = Label.new()
	inv_title.text = "INVENTARIO"
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_v_box.add_child(inv_title)

	inventory_label = Label.new()
	inventory_label.text = "Contenido: \nSlots: N/A / N/A\nPeso: N/A / N/A kg"
	inv_v_box.add_child(inventory_label)

	var close_inv_button = Button.new()
	close_inv_button.text = "Cerrar"
	close_inv_button.pressed.connect(Callable(self, "_toggle_inventory_ui"))
	inv_v_box.add_child(close_inv_button)


func _on_player_health_changed(new_health: int, new_max_health: int):
	current_health = new_health
	max_health = new_max_health
	_update_debug_ui()
	print(str("[PLAYER-DEBUG] Salud del jugador actualizada: ", current_health, "/", max_health))

func _on_player_died(entity_id: int, entity_type: String):
	print(str("-----> ¡PLAYER-EVENT! El jugador (", entity_type, " ID: ", entity_id, ") ha muerto."))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 

func _on_player_hunger_changed(new_hunger: int, new_max_hunger: int):
	current_hunger = new_hunger
	max_hunger = new_max_hunger
	_update_debug_ui()
	print(str("[PLAYER-DEBUG] Hambre del jugador actualizada: ", current_hunger, "/", max_hunger))

func _on_player_starved(entity_id: int, entity_type: String):
	print(str("-----> ¡PLAYER-EVENT! El jugador (", entity_type, " ID: ", entity_id, ") se ha muerto de hambre."))
	
func _perform_attack():
	print("[PLAYER-DEBUG] Realizando ataque con clic izquierdo.")
	
	var camera = camera_spring_arm.get_node("Camera3D")
	if not camera or not is_instance_valid(camera):
		print("-----> ¡PLAYER-ERROR! Cámara no válida para ataque.")
		return

	var ray_origin = camera.global_transform.origin 
	var ray_end = camera.global_transform.origin + (-camera.global_transform.basis.z * attack_ray_length)

	# --- Visualización del Rayo de Ataque (Depuración) ---
	var debug_line_node = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = debug_line_node
	get_tree().get_root().add_child(mesh_instance) # Añadir a la raíz de la escena para visibilidad global
	
	debug_line_node.surface_begin(Mesh.PRIMITIVE_LINES)
	debug_line_node.surface_add_vertex(ray_origin)
	debug_line_node.surface_set_color(Color.RED)
	debug_line_node.surface_add_vertex(ray_end)
	debug_line_node.surface_set_color(Color.RED)
	debug_line_node.surface_end()

	# Desaparecer la línea después de un tiempo
	var timer = Timer.new()
	mesh_instance.add_child(timer)
	timer.wait_time = attack_debug_line_duration
	timer.one_shot = true
	timer.timeout.connect(func(): mesh_instance.queue_free())
	timer.start()

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collide_with_bodies = true
	query.collision_mask = 4 # Solo colisionar con NPCs (Capa 4)
	
	var result = space.intersect_ray(query)
	
	if result:
		var collider_node = result.collider
		print(str("[PLAYER-DEBUG] Rayo de ataque golpeó: ", collider_node.name, " en posición: ", result.position))
		
		if collider_node is CharacterBody3D and collider_node.has_node("HealthComponent"):
			var target_health_component = collider_node.get_node("HealthComponent")
			if target_health_component and is_instance_valid(target_health_component):
				target_health_component.take_damage(player_base_damage, "PHYSICAL")
				print(str("[PLAYER-DEBUG] Infligiendo ", player_base_damage, " de daño a ", collider_node.name, "."))
			else:
				print("-----> ¡PLAYER-DEBUG! Collider no tiene HealthComponent válido.")
		else:
			print("-----> ¡PLAYER-DEBUG! Collider no es un CharacterBody3D con HealthComponent.")
	else:
		print("[PLAYER-DEBUG] Ataque no golpeó nada.")

func _toggle_inventory_ui():
	if inventory_panel and is_instance_valid(inventory_panel):
		inventory_panel.visible = not inventory_panel.visible
		if inventory_panel.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			# Revertido a la versión anterior del inventario
			# Opcional: Centrar el panel al abrir (Puedes re-implementarlo aquí si lo deseas, buscando el Viewport.size)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print(str("[PLAYER-DEBUG] Inventario visible: ", inventory_panel.visible))
	else:
		print("-----> ¡PLAYER-ERROR! Panel de inventario no encontrado o no válido.")

func _on_player_inventory_changed(new_items: Dictionary):
	var inv_text = "Contenido:\n"
	if new_items.is_empty():
		inv_text += "    Vacío\n"
	else:
		for item_id_int in new_items: 
			var item_data = new_items[item_id_int].item_data
			var quantity = new_items[item_id_int].quantity
			inv_text += str("    - ", item_data.get("nombre", "Item Desconocido"), " (ID: ", item_id_int, "): ", quantity, "\n")
	
	if inventory_component and is_instance_valid(inventory_component):
		inv_text += str("Slots: ", inventory_component.items.size(), " / ", inventory_component.max_slots, "\n")
		inv_text += str("Peso: %.2f / %.2f kg" % [inventory_component.current_weight, inventory_component.max_weight_kg])
	
	inventory_label.text = inv_text
	print("[PLAYER-DEBUG] UI de Inventario actualizada.")


func _update_debug_ui():
	if health_label and hunger_label:
		health_label.text = "Salud: %d / %d" % [current_health, max_health]
		hunger_label.text = "Hambre: %d / %d" % [current_hunger, max_hunger]
