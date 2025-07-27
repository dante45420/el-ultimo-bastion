# el-ultimo-bastion/game_engine/scripts/Player.gd
# VERSIÓN CON HealthComponent Y HungerComponent integrados
extends CharacterBody3D
class_name Player

#-----------------------------------------------------------------------------
# EXPORTED VARIABLES - Propiedades configurables desde el editor de Godot
#-----------------------------------------------------------------------------
@export var speed = 7.0
@export var jump_velocity = 8.0
@export var mouse_sensitivity = 0.003
@export var user_id_for_bastion: int = 2 # <--- Asegúrate que este ID coincide con tu player_one en la DB

#-----------------------------------------------------------------------------
# CLASS VARIABLES - Propiedades internas del jugador
#-----------------------------------------------------------------------------
var camera_spring_arm: SpringArm3D
var data_loader: DataLoader
var bastion_id: int = 0 

@onready var health_component: HealthComponent = $HealthComponent
@onready var hunger_component: HungerComponent = $HungerComponent # <--- ¡NUEVA LÍNEA!

# Stats del personaje (Variables de clase, actualizadas por componentes)
var current_health: int = 0
var max_health: int = 0
var current_hunger: int = 0
var max_hunger: int = 0

# Nodos de la UI
var ui_canvas: CanvasLayer
var health_label: Label
var hunger_label: Label
var debug_damage_button: Button
var debug_eat_button: Button # Nuevo botón

# Constantes de física
const GRAVITY = 9.8

#-----------------------------------------------------------------------------
# GODOT ENGINE FUNCTIONS - Métodos llamados automáticamente por el motor
#-----------------------------------------------------------------------------

func _ready():
	print("[PLAYER-DEBUG] _ready() INICIADO.")

	self.collision_layer = 2 
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

			# Forzar actualización inicial de la UI de salud
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

			# Forzar actualización inicial de la UI de hambre
			_on_player_hunger_changed(player_current_hunger, player_max_hunger)

			print(str("[PLAYER-DEBUG] HungerComponent del jugador inicializado. Hambre: ", player_current_hunger, "/", player_max_hunger))
		else:
			print("-----> ¡PLAYER-ERROR! HungerComponent no encontrado o no válido en el jugador.")

func _on_data_loader_failed(status_code, error_data):
	var error_message = error_data.get("message", "")
	if str("usuario ", user_id_for_bastion) in error_message:
		print(str("-----> ¡PLAYER-ERROR! La solicitud de datos del Bastion falló. Código: ", status_code, ", Datos: ", error_data))
		print("-----> PLAYER: Creando un jugador por defecto porque la carga desde la DB falló.")
		_create_default_visual_and_hitbox(0.5, 1.8)

		# Inicializar HealthComponent con valores por defecto si falla la carga
		if health_component and is_instance_valid(health_component):
			health_component.initialize_health(0, "Bastion", 100, 100) # ID 0 si no se pudo cargar
			health_component.health_changed.connect(Callable(self, "_on_player_health_changed"))
			health_component.died.connect(Callable(self, "_on_player_died"))
			_on_player_health_changed(100, 100)
			print("[PLAYER-DEBUG] HealthComponent del jugador inicializado con valores por defecto.")

		# Inicializar HungerComponent con valores por defecto si falla la carga
		if hunger_component and is_instance_valid(hunger_component):
			hunger_component.initialize_hunger(0, "Bastion", 100, 100) # ID 0 si no se pudo cargar
			hunger_component.hunger_changed.connect(Callable(self, "_on_player_hunger_changed"))
			hunger_component.starved.connect(Callable(self, "_on_player_starved"))
			_on_player_hunger_changed(100, 100)
			print("[PLAYER-DEBUG] HungerComponent del jugador inicializado con valores por defecto.")

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
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.set_custom_minimum_size(Vector2(200, 150)) # Aumentar tamaño para más botones
	panel.position = Vector2(10, 10)
	ui_canvas.add_child(panel)
	var v_box = VBoxContainer.new()
	panel.add_child(v_box)
	health_label = Label.new()
	health_label.text = "Salud: N/A"
	v_box.add_child(health_label)
	hunger_label = Label.new()
	hunger_label.text = "Hambre: N/A"
	v_box.add_child(hunger_label)

	debug_damage_button = Button.new()
	debug_damage_button.text = "Recibir Daño (10)"
	debug_damage_button.pressed.connect(Callable(self, "_on_debug_damage_button_pressed"))
	v_box.add_child(debug_damage_button)

	debug_eat_button = Button.new() # <--- ¡NUEVO BOTÓN!
	debug_eat_button.text = "Comer (20 Hambre)"
	debug_eat_button.pressed.connect(Callable(self, "_on_debug_eat_button_pressed"))
	v_box.add_child(debug_eat_button)


# Slot para la señal health_changed del HealthComponent
func _on_player_health_changed(new_health: int, new_max_health: int):
	current_health = new_health
	max_health = new_max_health
	_update_debug_ui()
	print(str("[PLAYER-DEBUG] Salud del jugador actualizada: ", current_health, "/", max_health))

# Slot para la señal died del HealthComponent
func _on_player_died(entity_id: int, entity_type: String):
	print(str("-----> ¡PLAYER-EVENT! El jugador (", entity_type, " ID: ", entity_id, ") ha muerto."))
	# Aquí puedes añadir lógica de game over, reaparición, etc.
	# El HealthComponent ya se encarga de detener la física y ocultar el visual.

# Slot para la señal hunger_changed del HungerComponent
func _on_player_hunger_changed(new_hunger: int, new_max_hunger: int): # <--- ¡NUEVO SLOT!
	current_hunger = new_hunger
	max_hunger = new_max_hunger
	_update_debug_ui()
	print(str("[PLAYER-DEBUG] Hambre del jugador actualizada: ", current_hunger, "/", max_hunger))

# Slot para la señal starved del HungerComponent
func _on_player_starved(entity_id: int, entity_type: String): # <--- ¡NUEVO SLOT!
	print(str("-----> ¡PLAYER-EVENT! El jugador (", entity_type, " ID: ", entity_id, ") se ha muerto de hambre."))
	# Aquí puedes añadir efectos visuales o de audio para inanición


# Slot para el botón de daño
func _on_debug_damage_button_pressed():
	if health_component and is_instance_valid(health_component):
		health_component.take_damage(10, "TEST_DAMAGE") 
		print("[PLAYER-DEBUG] Botón de daño presionado. Infligiendo 10 de daño.")

# Slot para el botón de comer
func _on_debug_eat_button_pressed(): # <--- ¡NUEVO SLOT!
	if hunger_component and is_instance_valid(hunger_component):
		hunger_component.eat(20) # Restaura 20 puntos de hambre
		print("[PLAYER-DEBUG] Botón de comer presionado. Restaurando 20 de hambre.")


func _update_debug_ui():
	if health_label and hunger_label:
		health_label.text = "Salud: %d / %d" % [current_health, max_health]
		hunger_label.text = "Hambre: %d / %d" % [current_hunger, max_hunger]
