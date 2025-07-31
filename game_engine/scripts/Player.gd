# res://scripts/Player.gd
# VERSIÓN COMPLETA Y CORREGIDA
extends CharacterBody3D
class_name Player

@export var mouse_sensitivity = 0.003
@export var user_id_for_bastion: int = 1
@export var debug_mode: bool = true  # 🆕 NUEVO: Variable de debug

# --- DECLARACIONES DE VARIABLES (AQUÍ ESTABA EL PROBLEMA) ---
# Nos aseguramos de que TODAS las referencias a nodos estén aquí.
@onready var camera_spring_arm: SpringArm3D = $CameraSpringArm
@onready var camera: Camera3D = $CameraSpringArm/Camera3D
# La siguiente línea se había borrado accidentalmente:
var interaction_ray: RayCast3D  # Será creado dinámicamente

@onready var health_component: HealthComponent = $HealthComponent
@onready var hunger_component: HungerComponent = $HungerComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var visuals_component: VisualsComponent = $VisualsComponent

# --- Nodos de UI ---
var health_label: Label
var hunger_label: Label
var interaction_label: Label # Para el mensaje "[E] Interactuar"
var inventory_ui: Control    # 🆕 NUEVO: UI del inventario

# 🆕 UI de estadísticas
var stats_ui: Control

# --- Estado del inventario ---
var inventory_open: bool = false  # 🆕 NUEVO

# --- Variables de Interacción ---
var current_interactable: Node = null
var interaction_ui: Control = null

var data_loader: DataLoader
var bastion_id: int

func _ready():
	hunger_component.set_process(false)
	
	self.collision_layer = 2
	self.collision_mask = 1 | 4
	# Configurar captura del ratón
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# 🔧 VALIDACIONES CRÍTICAS: Verificar que los nodos existen
	if not camera_spring_arm:
		print("❌ [CRITICAL] Player: CameraSpringArm no encontrado!")
		return
	
	if not camera:
		print("❌ [CRITICAL] Player: Camera3D no encontrada!")
		return
	
	if not interaction_ray:
		print("⚠️  [WARNING] Player: InteractionRay no encontrado - las interacciones no funcionarán")
		# Continuar sin interaction_ray - no es crítico para el funcionamiento básico
	
	print("✅ [PLAYER] Nodos críticos verificados")
	
	# 🤝 CREAR INTERACTION RAY DINÁMICAMENTE
	_create_interaction_ray()

	# Configurar capas de colisión para detección de loot
	collision_layer = 2  # El jugador está en la capa 2
	collision_mask = 1   # El jugador colisiona con el suelo (capa 1)
	
	# Agregar al grupo "player" para que la IA pueda encontrarlo
	add_to_group("player")
	
	health_component.health_changed.connect(Callable(self, "_on_player_health_changed"))
	hunger_component.hunger_changed.connect(Callable(self, "_on_player_hunger_changed"))

	# 🚀 CREAR UI DE ESTADÍSTICAS
	_create_stats_ui()

	# 🔧 ELIMINAR las líneas 79-81 que buscan UI inexistente
	# health_label = get_node_or_null("/root/MainScene/UI/StatsPanel/HealthLabel")
	# hunger_label = get_node_or_null("/root/MainScene/UI/StatsPanel/HungerLabel")
	
	interaction_label = get_node_or_null("/root/MainScene/UI/InteractionLabel")
	if is_instance_valid(interaction_label): interaction_label.visible = false

	print("=== [DEBUG] Player: VERIFICANDO DATALOADER ===")
	data_loader = get_node_or_null("/root/MainScene/World_Node/DataLoader")
	if data_loader:
		print(str("[DEBUG] Player: ✅ DataLoader encontrado en: ", data_loader.get_path()))
		print(str("[DEBUG] Player: Script: ", data_loader.get_script().resource_path))
		print(str("[DEBUG] Player: tiene make_authenticated_request: ", data_loader.has_method("make_authenticated_request")))
	print("=== [DEBUG] Player: FIN VERIFICACIÓN ===")

	if data_loader:
		data_loader.get_bastion_by_user_id(
			user_id_for_bastion,
			Callable(self, "_on_bastion_loaded"),
			Callable(self, "_on_data_loader_failed")
		)
	else:
		print("ERROR: DataLoader no encontrado. No se pueden cargar datos del Bastion.")
		_on_data_loader_failed(-1, "DataLoader no encontrado")

	# 🆕 CREAR UI DE ESTADÍSTICAS
	_create_stats_ui()

func _physics_process(_delta):
	# Movimiento del jugador
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	movement_component.set_move_direction(direction)
	
	# 🤝 DETECTAR INTERACCIONES
	_process_interactions()

# La función _input completa y corregida con validaciones
func _input(event):
	# 🔧 VALIDACIONES: Asegurar que los nodos existen antes de usarlos
	if not is_instance_valid(camera_spring_arm):
		if debug_mode: print("❌ [PLAYER] camera_spring_arm no válido, saltando input")
		return
	
	if not is_instance_valid(camera):
		if debug_mode: print("❌ [PLAYER] camera no válida, saltando input")
		return
	
	# Verificar que mouse_sensitivity tenga un valor válido
	if mouse_sensitivity == null or mouse_sensitivity <= 0:
		mouse_sensitivity = 0.003  # Valor por defecto
		if debug_mode: print("🔧 [PLAYER] mouse_sensitivity corregido a valor por defecto")
	
	# Lógica para rotar la cámara
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotación Izquierda/Derecha (Yaw): Se aplica al cuerpo del jugador
		rotation_degrees.y -= event.relative.x * mouse_sensitivity * 100.0
		# Rotación Arriba/Abajo (Pitch): Se aplica al SpringArm para no inclinar el cuerpo
		camera_spring_arm.rotation_degrees.x -= event.relative.y * mouse_sensitivity * 100.0
		camera_spring_arm.rotation_degrees.x = clamp(camera_spring_arm.rotation_degrees.x, -90, 70)
		return

	# Salir del juego (Escape)
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	# Liberar/Capturar el ratón (necesitas crear una acción "toggle_mouse_capture" y asignarle la tecla 'F')
	if Input.is_action_just_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Salto (Espacio)
	if Input.is_action_just_pressed("ui_accept"): # 'ui_accept' es la acción por defecto para Espacio
		if is_instance_valid(movement_component):
			movement_component.jump()

	# Ataque (Clic Izquierdo)
	if Input.is_action_just_pressed("attack") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		print("DEBUG Jugador: Acción 'attack' presionada.")
		if is_instance_valid(combat_component) and is_instance_valid(camera):
			combat_component.execute_attack(camera)
			
	# Interacción (tecla E)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			print("🔍 [INTERACTION] Tecla E presionada")
			_execute_interaction()
		elif event.keycode == KEY_ESCAPE:
			_close_any_dialogue()

	# 📦 Inventario (Tecla I) - USANDO UNA ACCIÓN MÁS COMÚN
	if Input.is_action_just_pressed("ui_home"): # Tecla "Home" por defecto
		print("📦 [DEBUG] Tecla de inventario presionada")
		toggle_inventory()

	# 🤲 Pickup Manual (Tecla R)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("🔍 [PICKUP] Buscando objetos de loot cercanos...")
			_try_pickup_nearby_loot()
		
		# 📦 Inventario (Tecla I)
		elif event.keycode == KEY_I:
			print("📦 [DEBUG] Tecla I presionada")
			toggle_inventory()

	# 🍖 Comer (Tecla F)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			print("🍖 [FOOD] Intentando comer...")
			_try_eat_food()

func _on_bastion_loaded(data, _status_code):
	print("DEBUG Jugador: Datos del Bastion cargados. Inicializando componentes.")
	bastion_id = data.get("id", 0)
	var pos_dict = data.get("posicion_actual", {"x":0.0, "y":10.0, "z":0.0}) 
	self.global_position = Vector3(float(pos_dict.get("x", 0.0)), float(pos_dict.get("y", 10.0)), float(pos_dict.get("z", 0.0)))

	var cvb_data = data.get("criatura_viva_base", {})
	var danio_data = cvb_data.get("danio", {})
	
	if is_instance_valid(visuals_component):
		visuals_component.create_visuals({})

	print("🔧 [PLAYER INIT] ===== INICIALIZANDO COMPONENTES =====")
	print("🔧 [PLAYER INIT] CVB Data: ", cvb_data)
	print("🔧 [PLAYER INIT] Hambre max en datos: ", cvb_data.get("hambre_max", 100))
	print("🔧 [PLAYER INIT] Hambre actual en datos: ", cvb_data.get("hambre_actual", 100))
	
	health_component.initialize_health(bastion_id, "Bastion", danio_data.get("salud_max", 100), danio_data.get("salud_actual", 100))
	
	# 🔧 FORZAR VALORES CORRECTOS DE HAMBRE
	var hambre_max = max(cvb_data.get("hambre_max", 100), 100)  # Mínimo 100
	var hambre_actual = max(cvb_data.get("hambre_actual", 80), 80)  # Mínimo 80
	
	print("🔧 [PLAYER INIT] Hambre FORZADA - Max: ", hambre_max, " Actual: ", hambre_actual)
	hunger_component.initialize_hunger(bastion_id, "Bastion", hambre_max, hambre_actual, 0.00278)
	
	print("🔧 [PLAYER INIT] Después de inicializar hambre:")
	print("🔧 [PLAYER INIT] hunger_component.current_hunger = ", hunger_component.current_hunger)
	print("🔧 [PLAYER INIT] hunger_component.max_hunger = ", hunger_component.max_hunger)
	
	print("🔧 [INIT DEBUG] Hambre inicializada. Current: ", hunger_component.current_hunger, " Max: ", hunger_component.max_hunger)
	hunger_component.set_process(true)
	
	movement_component.speed = cvb_data.get("velocidad_movimiento", 7.0)
	
	# *** NUEVO: Inicializar efectos de combate configurables ***
	var combat_config = {
		"base_damage": cvb_data.get("dano_ataque_base", 10.0),
		"attack_range": 10.0,  # *** DE VUELTA A 10.0 ***
		"attack_cooldown": 0.5,
		"visual_effects": {
			"type": "explosion",
			"size": 1.2,
			"color": "#FF6B35",
			"duration": 0.3
		}
	}
	combat_component.initialize_combat(combat_config)

func _on_data_loader_failed(_status_code, _error_data):
	print("ERROR: No se pudieron cargar los datos del Bastion. Usando valores por defecto.")
	if is_instance_valid(visuals_component):
		visuals_component.create_visuals({})

	health_component.initialize_health(0, "Bastion", 100, 100)
	hunger_component.initialize_hunger(0, "Bastion", 100, 100, 0.0139)  # 🔧 MÁS LENTO
	hunger_component.set_process(true)
	
	# *** NUEVO: Configuración por defecto de combate ***
	var default_combat_config = {
		"base_damage": 10.0,
		"attack_range": 3.0,
		"attack_cooldown": 0.5,
		"visual_effects": {
			"type": "explosion",
			"size": 1.0,
			"color": "#FF0000",
			"duration": 0.5
		}
	}
	combat_component.initialize_combat(default_combat_config)

func _on_player_health_changed(new_health, max_health):
	if is_instance_valid(health_label): 
		health_label.text = "❤️ Salud: %s/%s" % [new_health, max_health]
	_update_stats_ui()  # 🆕 ACTUALIZAR UI

func _on_player_hunger_changed(new_hunger, max_hunger):
	if is_instance_valid(hunger_label): 
		hunger_label.text = "🍖 Hambre: %s/%s" % [new_hunger, max_hunger]
	_update_stats_ui()  # 🆕 ACTUALIZAR UI

## Método para recibir daño de NPCs
func take_damage(damage: float, damage_type: String = "PHYSICAL_MELEE"):
	print(str("🩸 [PLAYER] Recibiendo ", damage, " de daño tipo ", damage_type))
	if is_instance_valid(health_component):
		health_component.take_damage(damage, damage_type)
		
		# Efecto visual de daño (flash rojo)
		if is_instance_valid(visuals_component):
			visuals_component.play_hit_flash()
	else:
		print("❌ [PLAYER] No se pudo aplicar daño - HealthComponent inválido")

## 📦 FUNCIÓN: Toggle Inventario
func toggle_inventory():
	print("📦 [DEBUG] toggle_inventory() llamado")
	inventory_open = !inventory_open
	
	if inventory_open:
		show_inventory()
	else:
		hide_inventory()

## 📦 FUNCIÓN: Mostrar Inventario  
func show_inventory():
	print("📦 [DEBUG] show_inventory() llamado")
	if not inventory_ui:
		create_inventory_ui()
	
	inventory_ui.visible = true
	inventory_open = true
	
	# Liberar el mouse para interactuar con la UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 🔧 ESPERAR UN FRAME ANTES DE ACTUALIZAR
	await get_tree().process_frame
	
	# Actualizar contenido del inventario
	update_inventory_display()
	
	print("📦 [INVENTARIO] Inventario abierto")

## 📦 FUNCIÓN: Ocultar Inventario
func hide_inventory():
	print("📦 [DEBUG] hide_inventory() llamado")
	if inventory_ui:
		inventory_ui.visible = false
	
	inventory_open = false
	
	# Volver a capturar el mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	print("📦 [INVENTARIO] Inventario cerrado")

## 📦 FUNCIÓN MEJORADA: Crear UI del Inventario
func create_inventory_ui():
	print("📦 [DEBUG] create_inventory_ui() llamado")
	# Panel principal del inventario
	inventory_ui = Control.new()
	inventory_ui.name = "InventoryUI"
	inventory_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Fondo semi-transparente
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_ui.add_child(background)
	
	# Panel central del inventario
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 400)
	panel.position = Vector2(-300, -200)
	inventory_ui.add_child(panel)
	
	# Título
	var title = Label.new()
	title.text = "📦 INVENTARIO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.position = Vector2(0, 10)
	title.size = Vector2(600, 30)
	panel.add_child(title)
	
	# Lista de objetos (scroll container)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 50)
	scroll.size = Vector2(560, 300)
	panel.add_child(scroll)
	
	# 🔧 CREAR EL VBOXCONTAINER CON REFERENCIA DIRECTA
	var vbox = VBoxContainer.new()
	vbox.name = "InventoryList"
	scroll.add_child(vbox)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "❌ Cerrar (I)"
	close_button.position = Vector2(250, 360)
	close_button.size = Vector2(100, 30)
	close_button.pressed.connect(hide_inventory)
	panel.add_child(close_button)
	
	# Instrucciones
	var instructions = Label.new()
	instructions.text = "Presiona I para abrir/cerrar • R para recoger loot"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.position = Vector2(0, 330)
	instructions.size = Vector2(600, 20)
	instructions.add_theme_font_size_override("font_size", 12)
	panel.add_child(instructions)
	
	# Agregar al árbol de escena
	get_tree().root.add_child(inventory_ui)
	inventory_ui.visible = false
	print("📦 [DEBUG] UI del inventario creada con jerarquía:")
	print("  InventoryUI -> Panel -> ScrollContainer -> InventoryList")

## 📦 FUNCIÓN MEJORADA: Actualizar contenido del inventario
func update_inventory_display():
	print("📦 [DEBUG] update_inventory_display() llamado")
	if not inventory_ui or not inventory_component:
		print("📦 [DEBUG] inventory_ui o inventory_component no válidos")
		return
	
	# 🔧 BUSCAR EL VBOXCONTAINER DE FORMA MÁS ROBUSTA
	var vbox = null
	
	# Método 1: Buscar por find_child
	vbox = inventory_ui.find_child("InventoryList", true, false)
	
	# Método 2: Si no funciona, buscar manualmente
	if not vbox:
		print("📦 [DEBUG] find_child falló, buscando manualmente...")
		var panel = inventory_ui.get_child(1)  # El panel es el segundo hijo (después del background)
		if panel:
			var scroll = panel.get_child(1)  # El scroll es el segundo hijo del panel (después del título)
			if scroll:
				vbox = scroll.get_child(0)  # El vbox es el primer hijo del scroll
				print("📦 [DEBUG] VBox encontrado manualmente")
	
	if not vbox:
		print("❌ [DEBUG] InventoryList DEFINITIVAMENTE no encontrado")
		return
	
	print("✅ [DEBUG] InventoryList encontrado, actualizando contenido...")
	
	# Limpiar lista actual
	for child in vbox.get_children():
		child.queue_free()
	
	# Obtener datos del inventario desde InventoryComponent
	var inventory_data = inventory_component.get_inventory_contents()
	print(str("📦 [DEBUG] Datos del inventario: ", inventory_data.size(), " objetos"))
	
	if inventory_data.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "🏜️ Inventario vacío - Mata NPCs para obtener loot"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_label)
		print("📦 [DEBUG] Mostrado mensaje de inventario vacío")
	else:
		print("📦 [DEBUG] Creando elementos de inventario...")
		for i in range(inventory_data.size()):
			var item = inventory_data[i]
			print(str("📦 [DEBUG] Procesando item: ", item.get("nombre"), " x", item.get("cantidad")))
			
			var item_panel = Panel.new()
			item_panel.custom_minimum_size = Vector2(520, 60)
			
			var item_label = Label.new()
			item_label.text = str("🍖 ", item.get("nombre", "Objeto"), " x", item.get("cantidad", 1))
			item_label.position = Vector2(10, 10)
			item_label.size = Vector2(400, 40)
			item_label.add_theme_font_size_override("font_size", 16)
			
			var item_desc = Label.new()
			item_desc.text = str(item.get("descripcion", "Sin descripción"), " (", item.get("peso_total", 0), "kg)")
			item_desc.position = Vector2(10, 30)
			item_desc.size = Vector2(400, 20)
			item_desc.add_theme_font_size_override("font_size", 12)
			item_desc.modulate = Color(0.8, 0.8, 0.8)
			
			item_panel.add_child(item_label)
			item_panel.add_child(item_desc)
			vbox.add_child(item_panel)
			
			print(str("📦 [DEBUG] Item añadido a la UI: ", item.get("nombre")))
		
		print("📦 [DEBUG] Todos los items añadidos a la UI")

## 🎒 NUEVA FUNCIÓN: Agregar objeto al inventario
func add_item_to_inventory(item_data: Dictionary):
	if inventory_component:
		var success = inventory_component.add_item(item_data)
		if success:
			print(str("✅ [INVENTARIO] Añadido: ", item_data.get("nombre"), " x", item_data.get("cantidad", 1)))
			
			# Actualizar UI si está abierta
			if inventory_open:
				update_inventory_display()
		else:
			print("❌ [INVENTARIO] No se pudo añadir el objeto (inventario lleno?)")
	else:
		print("❌ [INVENTARIO] InventoryComponent no disponible")

## 🤲 NUEVA FUNCIÓN: Pickup manual de objetos cercanos
func _try_pickup_nearby_loot():
	print("🔍 [PICKUP] Buscando objetos de loot cercanos...")
	
	# Buscar todos los objetos de loot en el mundo
	var loot_objects = get_tree().get_nodes_in_group("loot_objects")
	
	if loot_objects.size() == 0:
		# Si no hay grupo, buscar por meta
		loot_objects = []
		_find_loot_objects_recursive(get_tree().root, loot_objects)
	
	var picked_up = 0
	var pickup_range = 3.0  # Rango de pickup
	var closest_distance = pickup_range + 1.0
	var closest_loot = null
	
	print(str("🔍 [PICKUP] Encontrados ", loot_objects.size(), " objetos de loot en total"))
	
	for loot_obj in loot_objects:
		if not is_instance_valid(loot_obj):
			continue
			
		var distance = global_position.distance_to(loot_obj.global_position)
		print(str("📏 [PICKUP] ", loot_obj.name, " está a distancia: ", distance))
		
		if distance <= pickup_range:
			if distance < closest_distance:
				closest_distance = distance
				closest_loot = loot_obj
	
	# Recoger el objeto más cercano
	if closest_loot:
		var loot_data = closest_loot.get_meta("loot_data", {})
		if loot_data.size() > 0:
			add_item_to_inventory(loot_data)
			
			# 🎉 EFECTO VISUAL DE PICKUP
			var pickup_effect = _create_pickup_effect(closest_loot.global_position)
			get_tree().root.add_child(pickup_effect)
			
			closest_loot.queue_free()
			picked_up = 1
			print(str("🤲 [PICKUP] ¡Recogido! ", loot_data.get("nombre", "Objeto"), " x", loot_data.get("cantidad", 1)))
		else:
			print("❌ [PICKUP] Objeto sin loot_data")
	
	if picked_up == 0:
		print("🔍 [PICKUP] No hay objetos cercanos para recoger")
	else:
		print(str("✅ [PICKUP] Total recogido: ", picked_up, " objetos"))

## 🔍 FUNCIÓN HELPER: Buscar objetos de loot recursivamente
func _find_loot_objects_recursive(node: Node, results: Array):
	if node.has_meta("is_loot") and node.get_meta("is_loot") == true:
		results.append(node)
		print(str("🎯 [PICKUP] Encontrado objeto de loot: ", node.name))
	
	for child in node.get_children():
		_find_loot_objects_recursive(child, results)

## 🤝 NUEVA FUNCIÓN: Crear InteractionRay dinámicamente
func _create_interaction_ray():
	if not camera:
		print("❌ [INTERACTION] No se puede crear InteractionRay - cámara no válida")
		return
	
	interaction_ray = RayCast3D.new()
	interaction_ray.name = "InteractionRay"
	interaction_ray.target_position = Vector3(0, 0, -5.0)  # 5 metros hacia adelante
	interaction_ray.collision_mask = 4  # Capa de NPCs
	interaction_ray.enabled = true
	
	camera.add_child(interaction_ray)
	print("✅ [INTERACTION] InteractionRay creado correctamente")

## 🔍 NUEVA FUNCIÓN: Detectar objetos interactuables
func _process_interactions():
	if not is_instance_valid(interaction_ray):
		return
	
	var new_interactable: Node = null
	
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider and collider.has_node("InteractionComponent"):
			new_interactable = collider
	
	# Si cambió el objeto interactuable
	if new_interactable != current_interactable:
		_update_interaction_target(new_interactable)

## 🎯 NUEVA FUNCIÓN: Actualizar objetivo de interacción
func _update_interaction_target(new_target: Node):
	# Limpiar objetivo anterior
	if current_interactable:
		_hide_interaction_prompt()
	
	current_interactable = new_target
	
	# Configurar nuevo objetivo
	if current_interactable:
		_show_interaction_prompt()

## 💬 NUEVA FUNCIÓN: Mostrar prompt de interacción
func _show_interaction_prompt():
	if not current_interactable:
		return
	
	var interaction_component = current_interactable.get_node("InteractionComponent")
	if not interaction_component:
		return
	
	# Crear UI de prompt si no existe
	if not interaction_ui:
		_create_interaction_ui()
	
	# Actualizar texto del prompt
	var prompt_text = interaction_component.interaction_prompt.text
	if prompt_text.is_empty():
		prompt_text = "Presiona E para interactuar"
	
	var prompt_label = interaction_ui.find_child("PromptLabel")
	if prompt_label:
		prompt_label.text = prompt_text
	
	interaction_ui.visible = true

## 🚫 NUEVA FUNCIÓN: Ocultar prompt de interacción
func _hide_interaction_prompt():
	if interaction_ui:
		interaction_ui.visible = false

## 🎨 NUEVA FUNCIÓN: Crear UI de prompt de interacción
func _create_interaction_ui():
	interaction_ui = Control.new()
	interaction_ui.name = "InteractionUI"
	interaction_ui.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var background = Panel.new()
	background.custom_minimum_size = Vector2(300, 50)
	background.position = Vector2(-150, -25)
	background.modulate = Color(1, 1, 1, 0.9)
	interaction_ui.add_child(background)
	
	var prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = "Presiona E para interactuar"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(0, 0)
	prompt_label.size = Vector2(300, 50)
	prompt_label.add_theme_font_size_override("font_size", 14)
	background.add_child(prompt_label)
	
	get_tree().root.add_child(interaction_ui)
	interaction_ui.visible = false

## ⚡ NUEVA FUNCIÓN: Ejecutar interacción
func _execute_interaction():
	if not current_interactable:
		print("⚠️ [INTERACTION] No hay objeto interactuable")
		return
	
	var interaction_component = current_interactable.get_node_or_null("InteractionComponent")
	if not interaction_component:
		print("❌ [INTERACTION] InteractionComponent no encontrado")
		return
	
	print(str("🤝 [INTERACTION] Interactuando con ", current_interactable.name))
	interaction_component.interact(self)

## 🚪 NUEVA FUNCIÓN: Cerrar cualquier diálogo abierto
func _close_any_dialogue():
	var dialogues = get_tree().get_nodes_in_group("dialogue_ui")
	for dialogue in dialogues:
		if is_instance_valid(dialogue):
			dialogue.queue_free()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# 🎉 FUNCIÓN: Crear efecto visual de pickup
func _create_pickup_effect(position: Vector3) -> Node3D:
	var effect = Node3D.new()
	effect.global_position = position
	
	# Crear label que flota hacia arriba (SIN font_size_override)
	var label = Label3D.new()
	label.text = "¡Recogido!"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.GREEN
	label.outline_size = 2
	label.outline_modulate = Color.BLACK
	# ❌ REMOVIDO: label.add_theme_font_size_override("font_size", 16)  # Esta línea causa error
	effect.add_child(label)
	
	# Animación del efecto flotante
	var tween = get_tree().create_tween()
	tween.tween_property(label, "position:y", 2.0, 1.0)  # Flota hacia arriba
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)  # Se desvanece
	tween.tween_callback(func(): effect.queue_free())  # Se elimina al final
	
	return effect

## 🆕 FUNCIÓN: Crear UI de estadísticas permanente
func _create_stats_ui():
	print("🔧 [UI DEBUG] ===== CREANDO UI CON MÉTODO ALTERNATIVO =====")
	
	# 🔧 CREAR UI COMO CHILD DIRECTO DEL PLAYER
	stats_ui = Control.new()
	stats_ui.name = "StatsUI_DirectChild"
	stats_ui.z_index = 2000  # Z-index súper alto
	stats_ui.visible = true
	
	# 🔧 CONFIGURAR COMO OVERLAY
	stats_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stats_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 🔧 CREAR PANEL MUY VISIBLE
	var stats_panel = Panel.new()
	stats_panel.position = Vector2(50, 50)  # Más alejado del borde
	stats_panel.size = Vector2(400, 150)
	stats_panel.visible = true
	
	# 🔧 ESTILO LLAMATIVO
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.0, 1.0, 0.0, 0.8)  # 🟢 VERDE BRILLANTE
	style_box.border_width_left = 5
	style_box.border_width_top = 5
	style_box.border_width_right = 5
	style_box.border_width_bottom = 5
	style_box.border_color = Color.RED  # Borde rojo
	stats_panel.add_theme_stylebox_override("panel", style_box)
	
	stats_ui.add_child(stats_panel)
	
	# 🔧 LABELS MUY GRANDES Y VISIBLES
	health_label = Label.new()
	health_label.position = Vector2(20, 20)
	health_label.size = Vector2(350, 35)
	health_label.text = "❤️ VIDA: 100/100"
	health_label.add_theme_color_override("font_color", Color.BLACK)
	health_label.add_theme_font_size_override("font_size", 24)
	health_label.visible = true
	stats_panel.add_child(health_label)
	
	hunger_label = Label.new()
	hunger_label.position = Vector2(20, 60)
	hunger_label.size = Vector2(350, 35)
	hunger_label.text = "🍖 HAMBRE: 100/100"
	hunger_label.add_theme_color_override("font_color", Color.BLACK)
	hunger_label.add_theme_font_size_override("font_size", 24)
	hunger_label.visible = true
	stats_panel.add_child(hunger_label)
	
	var test_label = Label.new()
	test_label.position = Vector2(20, 100)
	test_label.size = Vector2(350, 35)
	test_label.text = "🔧 SI VES ESTO, LA UI FUNCIONA"
	test_label.add_theme_color_override("font_color", Color.RED)
	test_label.add_theme_font_size_override("font_size", 20)
	test_label.visible = true
	stats_panel.add_child(test_label)
	
	# 🔧 AGREGAR COMO CHILD DEL PLAYER (NO DEL VIEWPORT)
	add_child(stats_ui)
	print("🔧 [UI DEBUG] UI agregada como child del Player")
	
	# 🔧 VERIFICAR
	await get_tree().process_frame
	print("🔧 [UI DEBUG] Parent de stats_ui: ", stats_ui.get_parent())
	print("🔧 [UI DEBUG] Stats UI en árbol: ", stats_ui.is_inside_tree())
	print("🔧 [UI DEBUG] Stats UI visible: ", stats_ui.visible)
	
	call_deferred("_update_stats_ui")
	print("✅ [UI DEBUG] ===== UI CREADA COMO CHILD DEL PLAYER =====")

# 🆕 FUNCIÓN: Actualizar UI de estadísticas
func _update_stats_ui():
	print("🔧 [UI DEBUG] _update_stats_ui() llamado")
	print("🔧 [UI DEBUG] health_label válido: ", is_instance_valid(health_label))
	print("🔧 [UI DEBUG] hunger_label válido: ", is_instance_valid(hunger_label))
	
	if not health_label or not hunger_label:
		print("🔧 [UI DEBUG] Labels no válidos, saliendo")
		return
	
	var current_health = 100
	var max_health = 100
	var current_hunger = 100
	var max_hunger = 100
	
	# Obtener estadísticas reales del HealthComponent y HungerComponent
	if is_instance_valid(health_component):
		current_health = health_component.current_health
		max_health = health_component.max_health
		print("🔧 [UI DEBUG] Salud obtenida: ", current_health, "/", max_health)
	
	if is_instance_valid(hunger_component):
		current_hunger = hunger_component.current_hunger
		max_hunger = hunger_component.max_hunger
		print("🔧 [UI DEBUG] Hambre obtenida: ", current_hunger, "/", max_hunger)
	
	# Actualizar textos
	var new_health_text = str("❤️ Vida: ", current_health, "/", max_health)
	var new_hunger_text = str("🍖 Hambre: ", current_hunger, "/", max_hunger)
	
	health_label.text = new_health_text
	hunger_label.text = new_hunger_text
	
	print("🔧 [UI DEBUG] Textos actualizados:")
	print("🔧 [UI DEBUG] Health: ", new_health_text)
	print("🔧 [UI DEBUG] Hunger: ", new_hunger_text)
	
	# Cambiar colores según el estado
	if current_health < max_health * 0.3:
		health_label.add_theme_color_override("font_color", Color.RED)
	elif current_health < max_health * 0.7:
		health_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		health_label.add_theme_color_override("font_color", Color.GREEN)
	
	if current_hunger < max_hunger * 0.3:
		hunger_label.add_theme_color_override("font_color", Color.RED)
	elif current_hunger < max_hunger * 0.7:
		hunger_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		hunger_label.add_theme_color_override("font_color", Color.ORANGE)

## 🍖 FUNCIÓN: Intentar comer comida del inventario
func _try_eat_food():
	print("🍖 [FOOD DEBUG] ===== _try_eat_food() INICIADO =====")
	print("🍖 [FOOD DEBUG] InventoryComponent válido: ", is_instance_valid(inventory_component))
	print("🍖 [FOOD DEBUG] HungerComponent válido: ", is_instance_valid(hunger_component))
	
	if not is_instance_valid(inventory_component):
		print("❌ [FOOD] InventoryComponent no válido")
		return
	
	if not is_instance_valid(hunger_component):
		print("❌ [FOOD] HungerComponent no válido")
		return
	
	# Buscar comida en el inventario
	print("🍖 [FOOD DEBUG] Obteniendo contenidos del inventario...")
	var inventory_data = inventory_component.get_inventory_contents()
	print("🍖 [FOOD DEBUG] Datos del inventario obtenidos. Cantidad de items: ", inventory_data.size())
	
	for i in range(inventory_data.size()):
		var item = inventory_data[i]
		print("🍖 [FOOD DEBUG] Item ", i, ": ", item)
		
		var item_name = item.get("nombre", "").to_lower()
		print("🍖 [FOOD DEBUG] Nombre del item en minúsculas: '", item_name, "'")
		
		# 🔧 VERIFICACIÓN MÁS AMPLIA DE COMIDA
		var is_food = false
		if "carne" in item_name:
			print("🍖 [FOOD DEBUG] ¡Contiene 'carne'!")
			is_food = true
		elif "comida" in item_name:
			print("🍖 [FOOD DEBUG] ¡Contiene 'comida'!")
			is_food = true
		elif "fruta" in item_name:
			print("🍖 [FOOD DEBUG] ¡Contiene 'fruta'!")
			is_food = true
		elif "pan" in item_name:
			print("🍖 [FOOD DEBUG] ¡Contiene 'pan'!")
			is_food = true
		elif "basica" in item_name:
			print("🍖 [FOOD DEBUG] ¡Contiene 'basica'!")
			is_food = true
		else:
			print("🍖 [FOOD DEBUG] No es comida reconocida")
		
		if is_food:
			print("🍖 [FOOD DEBUG] ¡COMIDA ENCONTRADA! Nombre: ", item.get("nombre", "Comida"))
			
			# Hambre actual antes de comer
			var hunger_before = hunger_component.current_hunger
			print("🍖 [FOOD DEBUG] Hambre antes de comer: ", hunger_before)
			
			# Restaurar hambre (cada comida restaura 30 puntos)
			hunger_component.restore_hunger(30)
			
			# Hambre después de comer
			var hunger_after = hunger_component.current_hunger
			print("🍖 [FOOD DEBUG] Hambre después de comer: ", hunger_after)
			
			# 🔧 REMOVER 1 unidad del inventario
			var item_id = item.get("id", -1)
			print("🍖 [FOOD DEBUG] ID del item a remover: ", item_id)
			
			if item_id != -1:
				var removed = inventory_component.remove_item(item_id, 1)
				print("🍖 [FOOD DEBUG] Item removido exitosamente: ", removed)
				print("🍖 [FOOD DEBUG] Consumido 1x ", item.get("nombre", "Comida"))
			
			print("🍖 [FOOD DEBUG] ===== COMIDA CONSUMIDA EXITOSAMENTE =====")
			return
	
	print("🍖 [FOOD DEBUG] ===== NO SE ENCONTRÓ COMIDA =====")
	print("❌ [FOOD] No hay comida disponible en el inventario")
	
	# Mostrar mensaje en pantalla
	var no_food_label = Label.new()
	no_food_label.text = "❌ Sin comida disponible"
	no_food_label.position = Vector2(get_viewport().size.x / 2 - 100, 150)
	no_food_label.add_theme_color_override("font_color", Color.RED)
	no_food_label.add_theme_font_size_override("font_size", 20)
	get_tree().current_scene.add_child(no_food_label)
	
	# Eliminar el mensaje después de 3 segundos
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if is_instance_valid(no_food_label):
			no_food_label.queue_free()
		timer.queue_free()
	)
	get_tree().current_scene.add_child(timer)
	timer.start()
