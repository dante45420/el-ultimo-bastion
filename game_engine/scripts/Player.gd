# el-ultimo-bastion/game_engine/scripts/Player.gd
# VERSIÓN COMPLETA Y DEFINITIVA CON TODAS LAS CORRECCIONES
extends CharacterBody3D
class_name Player

#-----------------------------------------------------------------------------
# EXPORTED VARIABLES - Propiedades configurables desde el editor de Godot
#-----------------------------------------------------------------------------
@export var speed = 7.0
@export var jump_velocity = 8.0
@export var mouse_sensitivity = 0.003

#-----------------------------------------------------------------------------
# CLASS VARIABLES - Propiedades internas del jugador
#-----------------------------------------------------------------------------
var camera_spring_arm: SpringArm3D
var data_loader: DataLoader
var bastion_id: int = 0
# ID del usuario a cargar. Corregido a 5 según tu base de datos.
var user_id_for_bastion: int = 5

# Stats del personaje
var current_health: int = 0
var max_health: int = 0
var current_hunger: int = 0
var max_hunger: int = 0

# Nodos de la UI
var ui_canvas: CanvasLayer
var health_label: Label
var hunger_label: Label

# Constantes de física
const GRAVITY = 9.8

#-----------------------------------------------------------------------------
# GODOT ENGINE FUNCTIONS - Métodos llamados automáticamente por el motor
#-----------------------------------------------------------------------------

# Se ejecuta una sola vez cuando el nodo entra en la escena.
func _ready():
	print("[PLAYER-DEBUG] _ready() INICIADO.")
	
	# 1. Configurar física desde el código para asegurar que se aplique.
	self.collision_layer = 2 # El jugador está en la capa 2 ("jugador")
	self.collision_mask = 1  # El jugador debe chocar con la capa 1 ("mundo")
	print(str("[PLAYER-DEBUG] Física configurada. Capa: ", self.collision_layer, ", Máscara: ", self.collision_mask))

	# 2. Configurar cámara para vista en tercera persona.
	camera_spring_arm = get_node_or_null("CameraSpringArm")
	if camera_spring_arm:
		camera_spring_arm.spring_length = 5.0
		print("[PLAYER-DEBUG] SpringArm encontrado. Longitud establecida a 5.0.")
	else:
		print("-----> ¡PLAYER-ERROR! No se encontró el nodo hijo 'CameraSpringArm'.")

	# 3. Capturar el ratón para controlar la cámara.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# 4. Conectar con el DataLoader para obtener datos del personaje.
	data_loader = get_node_or_null("/root/MainScene/World_Node/DataLoader") 
	if data_loader and is_instance_valid(data_loader):
		print("[PLAYER-DEBUG] DataLoader encontrado y válido.")
		data_loader.request_completed_success.connect(self._on_data_loader_success)
		data_loader.request_failed.connect(self._on_data_loader_failed)
		
		print(str("[PLAYER-DEBUG] Solicitando datos del Bastion para el usuario ID: ", user_id_for_bastion))
		data_loader.get_bastion_by_user_id(user_id_for_bastion)
	else:
		print("-----> ¡PLAYER-ERROR CRÍTICO! No se pudo encontrar el DataLoader en la ruta especificada.")
	
	# 5. Crear la interfaz de usuario de depuración.
	_setup_debug_ui()
	print("[PLAYER-DEBUG] _ready() COMPLETADO.")

# Se ejecuta cada frame de física. Ideal para movimiento y colisiones.
func _physics_process(delta):
	# Aplicar gravedad si no está en el suelo
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Manejar salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Obtener input de movimiento
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Aplicar movimiento
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Frenar suavemente si no hay input
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

# Se ejecuta cada vez que hay un evento de input (teclado, ratón).
func _input(event):
	# CORRECCIÓN: Añadida acción para salir del juego con la tecla Escape.
	# Debes añadir una acción llamada "quit_game" en Proyecto -> Mapa de Entrada y asignarle la tecla Escape.
	if event.is_action_pressed("quit_game"):
		get_tree().quit()

	# Mover la cámara con el ratón
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotar el personaje horizontalmente
		rotation_degrees.y -= event.relative.x * mouse_sensitivity * 100.0
		# Rotar el SpringArm (cámara) verticalmente
		var current_pitch = camera_spring_arm.rotation_degrees.x - event.relative.y * mouse_sensitivity * 100.0
		camera_spring_arm.rotation_degrees.x = clamp(current_pitch, -70, 70)
	
	# Liberar/Capturar el cursor del ratón con la tecla 'F'
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#-----------------------------------------------------------------------------
# CUSTOM FUNCTIONS - Métodos propios de la clase
#-----------------------------------------------------------------------------

# Se llama cuando el DataLoader devuelve una respuesta exitosa.
func _on_data_loader_success(data, _status_code):
	# Filtra la respuesta para asegurarse de que es para este Bastion.
	if data is Dictionary and data.has("id_usuario") and data.has("nombre_personaje"):
		print("[PLAYER-DEBUG] ¡Datos del Bastion recibidos exitosamente desde el servidor!")
		_on_bastion_loaded(data)

# Se llama cuando el DataLoader devuelve un error.
func _on_data_loader_failed(status_code, error_data):
	var error_message = error_data.get("message", "")
	if str("usuario ", user_id_for_bastion) in error_message:
		print(str("-----> ¡PLAYER-ERROR! La solicitud de datos del Bastion falló. Código: ", status_code, ", Datos: ", error_data))
		print("-----> PLAYER: Creando un jugador por defecto porque la carga desde la DB falló.")
		_create_default_visual_and_hitbox(0.5, 1.8)

# Procesa los datos del Bastion una vez cargados.
func _on_bastion_loaded(data: Dictionary):
	print("[PLAYER-DEBUG] _on_bastion_loaded ejecutado. Datos recibidos: ", data)
	bastion_id = data.get("id", 0)
	
	# Usa una posición por defecto alta para asegurar que no aparezca bajo el suelo.
	var pos_dict = data.get("posicion_actual", {"x":0.0, "y":10.0, "z":0.0}) 
	self.global_position = Vector3(pos_dict.get("x", 0.0), pos_dict.get("y", 10.0), pos_dict.get("z", 0.0))
	print(str("[PLAYER-DEBUG] Posición del jugador establecida en: ", self.global_position))
	
	var hitbox_dims = pos_dict.get("hitbox_dimensions", {"radius": 0.4, "height": 1.7})
	
	print("[PLAYER-DEBUG] Creando visual del jugador.")
	_create_default_visual_and_hitbox(hitbox_dims.get("radius", 0.4), hitbox_dims.get("height", 1.7))

# Crea el modelo visual y la forma de colisión por defecto.
func _create_default_visual_and_hitbox(radius: float, height: float):
	# Limpia visuales o colisiones previas para evitar duplicados.
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
	
	# ---- ¡CORRECCIÓN VISUAL DEFINITIVA! ----
	# Levanta el modelo visual para que su base esté en el suelo (y=0 del CharacterBody).
	default_visual.position.y = height / 2.0
	add_child(default_visual)

	var default_hitbox = CollisionShape3D.new()
	default_hitbox.name = "DefaultHitboxCollision"
	var default_shape = CapsuleShape3D.new()
	default_shape.radius = radius
	default_shape.height = height
	default_hitbox.shape = default_shape
	# La colisión también se levanta para que coincida con el modelo visual.
	default_hitbox.position.y = height / 2.0
	add_child(default_hitbox)
	print("[PLAYER-DEBUG] Creado visual (Cápsula Magenta) y hitbox por defecto.")

# Configura la UI de depuración.
func _setup_debug_ui():
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.set_custom_minimum_size(Vector2(200, 80))
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

# Actualiza el texto de la UI.
func _update_debug_ui():
	if health_label and hunger_label:
		health_label.text = "Salud: %d / %d" % [current_health, max_health]
		hunger_label.text = "Hambre: %d / %d" % [current_hunger, max_hunger]
