# res://scripts/components/InteractionComponent.gd
# VERSIÓN COMPLETA - MÚLTIPLES INTERACCIONES CON SELECCIÓN NUMÉRICA
extends Node
class_name InteractionComponent

signal interacted(action_type: String, interactor: Node)

@export var interaction_range: float = 3.0
var available_actions: Array[String] = []
var interaction_settings: Dictionary = {}
var npc_data: Dictionary = {}  # 🆕 Datos completos del NPC
var current_interactor: Node = null
var interaction_menu_active: bool = false

# UI Elements para mostrar prompts
var interaction_prompt: Label3D

func _ready():
	# Crear prompt visual
	interaction_prompt = Label3D.new()
	interaction_prompt.text = ""
	interaction_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interaction_prompt.position.y = 2.0
	interaction_prompt.modulate = Color.YELLOW
	interaction_prompt.outline_size = 2
	interaction_prompt.outline_modulate = Color.BLACK
	get_parent().add_child(interaction_prompt)

# 🆕 NUEVA FUNCIÓN: Manejar input numérico cuando hay menú activo
func _input(event):
	if not interaction_menu_active or not current_interactor:
		return
	
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		var selected_index = -1
		
		# Detectar teclas numéricas 1-9
		match key_code:
			KEY_1: selected_index = 0
			KEY_2: selected_index = 1
			KEY_3: selected_index = 2
			KEY_4: selected_index = 3
			KEY_5: selected_index = 4
			KEY_6: selected_index = 5
			KEY_7: selected_index = 6
			KEY_8: selected_index = 7
			KEY_9: selected_index = 8
			KEY_ESCAPE:
				_close_interaction_menu()
				return
		
		# Si se seleccionó una opción válida
		if selected_index >= 0 and selected_index < available_actions.size():
			var selected_action = available_actions[selected_index]
			_close_interaction_menu()
			_execute_interaction(selected_action, current_interactor)

func initialize_interactions(settings: Dictionary, full_npc_data: Dictionary = {}):
	interaction_settings = settings
	npc_data = full_npc_data
	
	# Obtener acciones disponibles
	var actions_from_data: Array = settings.get("actions", [])
	var typed_actions: Array[String] = []
	
	for action in actions_from_data:
		typed_actions.append(str(action))
		
	available_actions = typed_actions

	# 🆕 AGREGAR ACCIONES BASADAS EN ROL_NPC
	var rol_npc = npc_data.get("tipo_npc", {}).get("rol_npc", "GENERICO")
	_add_role_based_actions(rol_npc)
	
	_update_interaction_prompt()
	print(str("🤝 [INTERACTION] NPC inicializado con acciones: ", available_actions))

func _add_role_based_actions(rol_npc: String):
	match rol_npc:
		"COMERCIANTE":
			if not available_actions.has("trade"):
				available_actions.append("trade")
		"GUARDIA", "DEFENSOR":
			if not available_actions.has("recruit"):
				available_actions.append("recruit")
			if not available_actions.has("dismiss"):
				available_actions.append("dismiss")
		"CONSTRUCTOR", "ARTESANO":
			if not available_actions.has("build"):
				available_actions.append("build")
			if not available_actions.has("craft"):
				available_actions.append("craft")
		"CONVERSADOR", "GUIA":
			if not available_actions.has("talk"):
				available_actions.append("talk")
		"MASCOTA", "COMPANERO":
			if not available_actions.has("follow"):
				available_actions.append("follow")
			if not available_actions.has("stay"):
				available_actions.append("stay")

func _update_interaction_prompt():
	if available_actions.is_empty():
		interaction_prompt.text = ""
		return
	
	var prompt_text = "Presiona E para "
	if available_actions.size() == 1:
		var action = available_actions[0]
		match action:
			"talk": prompt_text += "Hablar"
			"trade": prompt_text += "Comerciar"
			"recruit": prompt_text += "Reclutar"
			"dismiss": prompt_text += "Despedir"
			"build": prompt_text += "Construir"
			"craft": prompt_text += "Crear objeto"
			"follow": prompt_text += "Seguir"
			"stay": prompt_text += "Quedarse"
			_: prompt_text += "Interactuar"
	else:
		prompt_text += "Interactuar (" + str(available_actions.size()) + " opciones)"
	
	interaction_prompt.text = prompt_text

func interact(interactor: Node):
	if available_actions.is_empty():
		print("⚠️ [INTERACTION] No hay acciones disponibles")
		return
	
	if available_actions.size() == 1:
		# Una sola acción - ejecutar directamente
		var action = available_actions[0]
		_execute_interaction(action, interactor)
	else:
		# Múltiples acciones - mostrar menú
		current_interactor = interactor
		_show_interaction_menu(interactor)

func _execute_interaction(action: String, interactor: Node):
	print(str("🤝 [INTERACTION] Ejecutando acción: ", action))
	
	match action:
		"talk":
			_handle_dialogue(interactor)
		"trade":
			_handle_trade(interactor)
		"recruit":
			_handle_recruit(interactor)
		"dismiss":
			_handle_dismiss(interactor)
		"build":
			_handle_build(interactor)
		"craft":
			_handle_craft(interactor)
		"follow":
			_handle_follow(interactor)
		"stay":
			_handle_stay(interactor)
		_:
			print("❌ [INTERACTION] Acción no implementada: ", action)
	
	emit_signal("interacted", action, interactor)

# 🗣️ DIÁLOGOS
func _handle_dialogue(interactor: Node):
	var npc_name = npc_data.get("tipo_npc", {}).get("nombre", "NPC")
	var dialogue_text = _get_dialogue_text()
	
	_show_dialogue_ui(npc_name, dialogue_text, interactor)

func _get_dialogue_text() -> String:
	var rol_npc = npc_data.get("tipo_npc", {}).get("rol_npc", "GENERICO")
	var commerce_settings = npc_data.get("tipo_npc", {}).get("valores_rol", {}).get("commerce_settings", {})
	
	match rol_npc:
		"COMERCIANTE":
			return commerce_settings.get("saludo", "¡Bienvenido! ¿Qué quieres comprar?")
		"GUARDIA":
			return "¡Saludo! Estoy aquí para proteger el área."
		"CONSTRUCTOR":
			return "¿Necesitas que construya algo? ¡Tengo las mejores herramientas!"
		"MALVADO":
			return "¡GRRRRR! ¡Te haré pedazos!"
		_:
			return "¡Hola! ¿En qué puedo ayudarte?"

# 💰 COMERCIO MEJORADO
func _handle_trade(interactor: Node):
	var commerce_settings = npc_data.get("tipo_npc", {}).get("valores_rol", {}).get("commerce_settings", {})
	var puede_comerciar = commerce_settings.get("puede_comerciar", false)
	
	if not puede_comerciar:
		_show_dialogue_ui("Comerciante", "Lo siento, no tengo nada que vender ahora.", interactor)
		return
	
	_show_trade_ui(interactor)

# 🛡️ RECLUTAMIENTO
func _handle_recruit(interactor: Node):
	var recruitment_settings = npc_data.get("tipo_npc", {}).get("valores_rol", {}).get("recruitment_settings", {})
	var puede_ser_reclutado = recruitment_settings.get("puede_ser_reclutado", false)
	
	if not puede_ser_reclutado:
		_show_dialogue_ui("NPC", "No estoy interesado en unirme a ti.", interactor)
		return

	var requisitos = recruitment_settings.get("requisitos", [])
	
	# 🔧 VERIFICAR SI EL JUGADOR CUMPLE LOS REQUISITOS
	var can_recruit = _check_recruitment_requirements(requisitos, interactor)
	
	if can_recruit:
		# 🔧 REALIZAR RECLUTAMIENTO
		_execute_recruitment(requisitos, interactor)
	else:
		# Mostrar requisitos
		var req_text = "Para reclutarme necesitas:\n"
		
		for req in requisitos:
			var descripcion = req.get("descripcion", "Requisito desconocido")
			var cantidad = req.get("cantidad", 1)
			var tipo = req.get("tipo", "oro")
			
			if tipo == "objeto":
				req_text += "• " + descripcion + " x" + str(cantidad) + "\n"
			else:
				req_text += "• " + descripcion + "\n"
		
		_show_dialogue_ui("Reclutamiento", req_text, interactor)

# 🆕 NUEVA FUNCIÓN: Verificar requisitos de reclutamiento
func _check_recruitment_requirements(requisitos: Array, interactor: Node) -> bool:
	var player_inventory = interactor.get_node("InventoryComponent")
	if not player_inventory:
		return false
	
	var inventory_contents = player_inventory.get_inventory_contents()
	
	for req in requisitos:
		var tipo = req.get("tipo", "")
		var cantidad = req.get("cantidad", 1)
		var objeto_id = req.get("objeto_id", "")
		
		if tipo == "objeto":
			var has_item = false
			for item in inventory_contents:
				if str(item.get("id", "")) == str(objeto_id):
					if item.get("cantidad", 0) >= cantidad:
						has_item = true
						break
			
			if not has_item:
				print("💰 [RECRUIT] Falta objeto ID:", objeto_id, " cantidad:", cantidad)
				return false
		
		# Aquí puedes agregar otros tipos de requisitos (comida, oro, etc.)
	
	return true

# 🆕 NUEVA FUNCIÓN: Ejecutar reclutamiento
func _execute_recruitment(requisitos: Array, interactor: Node):
	var player_inventory = interactor.get_node("InventoryComponent")
	
	print("🐕 [RECRUIT] Ejecutando reclutamiento...")
	
	# 🔧 CONSUMIR REQUISITOS
	for req in requisitos:
		var tipo = req.get("tipo", "")
		var cantidad = req.get("cantidad", 1)
		var objeto_id = req.get("objeto_id", "")
		
		if tipo == "objeto":
			var removed = player_inventory.remove_item(int(objeto_id), cantidad)
			print("🐕 [RECRUIT] Removido objeto ID:", objeto_id, " cantidad:", cantidad, " éxito:", removed)
	
	# 🔧 MARCAR NPC COMO RECLUTADO
	var npc_node = get_parent()
	if npc_node.has_method("set_recruited"):
		npc_node.set_recruited(true)
	
	# 🔧 CAMBIAR COMPORTAMIENTO A ALIADO
	var ai_component = npc_node.get_node("AIComponent")
	if ai_component:
		# Cambiar a comportamiento de aliado
		ai_component.can_attack_player = false
		ai_component.current_state = "FOLLOWING"  # O el estado que uses para aliados
		print("🐕 [RECRUIT] IA configurada como aliado")
	
	print("✅ [RECRUIT] ¡Reclutamiento exitoso!")
	_show_dialogue_ui("Reclutado", "¡Excelente! Ahora soy tu aliado. Te seguiré y te protegeré.", interactor)
	_close_interaction_menu()

func _handle_dismiss(interactor: Node):
	var ai_component = get_parent().get_node_or_null("AIComponent")
	if ai_component:
		ai_component.set_ally_mode(false, null)
		_show_dialogue_ui("Guardia", "Entendido. Volveré a mi patrullaje.", interactor)

# 🔨 CONSTRUCCIÓN
func _handle_build(interactor: Node):
	_show_build_ui(interactor)

func _handle_craft(interactor: Node):
	_show_craft_ui(interactor)

# 🐕 SEGUIMIENTO
func _handle_follow(interactor: Node):
	var ai_component = get_parent().get_node_or_null("AIComponent")
	if ai_component:
		ai_component.set_follow_mode(true, interactor)

func _handle_stay(interactor: Node):
	var ai_component = get_parent().get_node_or_null("AIComponent")
	if ai_component:
		ai_component.set_follow_mode(false, null)

# 🎨 UI FUNCTIONS
func _show_dialogue_ui(npc_name: String, text: String, interactor: Node):
	print(str("💬 [DIALOGUE] ", npc_name, ": \"", text, "\""))
	
	# Crear UI de diálogo simple
	var dialogue_ui = _create_dialogue_ui(npc_name, text)
	get_tree().root.add_child(dialogue_ui)
	
	# Liberar mouse para cerrar diálogo
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _show_trade_ui(interactor: Node):
	print("💰 [TRADE] Abriendo interfaz de comercio")
	
	var commerce_settings = npc_data.get("tipo_npc", {}).get("valores_rol", {}).get("commerce_settings", {})
	var trade_offers = commerce_settings.get("ofertas_comercio", [])
	
	if trade_offers.is_empty():
		_show_dialogue_ui("Comerciante", "No tengo ofertas disponibles ahora.", interactor)
		return
	
	# 🔧 CREAR MENÚ DE COMERCIO FUNCIONAL
	var trade_text = "💰 OFERTAS DISPONIBLES:\n\n"
	
	for i in range(trade_offers.size()):
		var offer = trade_offers[i]
		var requiere = offer.get("requiere", {})
		var ofrece = offer.get("ofrece", {})
		
		trade_text += str(i + 1) + ". " 
		trade_text += str(requiere.get("nombre", "?")) + " x" + str(requiere.get("cantidad", 1))
		trade_text += " → " + str(ofrece.get("nombre", "?")) + " x" + str(ofrece.get("cantidad", 1)) + "\n"
	
	trade_text += "\n(Presiona el número para comerciar o ESC para cancelar)"
	
	# 🔧 CREAR UI DE COMERCIO CON BOTONES FUNCIONALES
	_show_trade_menu(trade_offers, interactor)

# 🆕 NUEVA FUNCIÓN: Menú de comercio funcional
func _show_trade_menu(trade_offers: Array, interactor: Node):
	var trade_ui = Control.new()
	trade_ui.name = "TradeUI"
	trade_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trade_ui.add_to_group("interaction_menu")
	
	# Fondo
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trade_ui.add_child(background)
	
	# Panel principal
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 400)
	panel.position = Vector2(-250, -200)
	trade_ui.add_child(panel)
	
	# Título
	var title = Label.new()
	title.text = "💰 COMERCIO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.position = Vector2(0, 10)
	title.size = Vector2(500, 30)
	panel.add_child(title)
	
	# Lista de ofertas
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 50)
	scroll.size = Vector2(460, 280)
	panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	# 🔧 CREAR BOTONES PARA CADA OFERTA
	for i in range(trade_offers.size()):
		var offer = trade_offers[i]
		var requiere = offer.get("requiere", {})
		var ofrece = offer.get("ofrece", {})
		
		var offer_button = Button.new()
		offer_button.text = str(requiere.get("nombre", "?")) + " x" + str(requiere.get("cantidad", 1)) + " → " + str(ofrece.get("nombre", "?")) + " x" + str(ofrece.get("cantidad", 1))
		offer_button.custom_minimum_size = Vector2(400, 40)
		
		# 🔧 CONECTAR FUNCIONALIDAD DE COMERCIO
		offer_button.pressed.connect(func(): _execute_trade(offer, interactor))
		
		vbox.add_child(offer_button)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "❌ Cerrar"
	close_button.position = Vector2(200, 350)
	close_button.size = Vector2(100, 30)
	close_button.pressed.connect(func(): _close_interaction_menu())
	panel.add_child(close_button)
	
	get_tree().root.add_child(trade_ui)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# 🆕 NUEVA FUNCIÓN: Ejecutar comercio real
func _execute_trade(offer: Dictionary, interactor: Node):
	var requiere = offer.get("requiere", {})
	var ofrece = offer.get("ofrece", {})
	
	var req_nombre = requiere.get("nombre", "")
	var req_cantidad = requiere.get("cantidad", 1)
	var req_objeto_id = str(requiere.get("objeto_id", ""))
	
	var offer_nombre = ofrece.get("nombre", "")
	var offer_cantidad = ofrece.get("cantidad", 1)
	var offer_objeto_id = str(ofrece.get("objeto_id", ""))
	
	print("💰 [TRADE] Intentando comercio: ", req_nombre, " x", req_cantidad, " → ", offer_nombre, " x", offer_cantidad)
	
	# 🔧 VERIFICAR SI EL JUGADOR TIENE LOS OBJETOS REQUERIDOS
	var player_inventory = null
	
	# 🔍 BUSCAR InventoryComponent en el jugador (puede ser hijo directo o componente)
	if interactor.has_node("InventoryComponent"):
		player_inventory = interactor.get_node("InventoryComponent")
	else:
		# 🔍 BUSCAR como variable/componente directo
		if interactor.get("inventory_component"):
			player_inventory = interactor.inventory_component
		else:
			# 🔍 BUSCAR en los hijos del jugador
			for child in interactor.get_children():
				if child.get_script() and "InventoryComponent" in str(child.get_script().get_path()):
					player_inventory = child
					break
	
	if not player_inventory:
		print("❌ [TRADE] No se encontró inventario del jugador")
		return
	
	var inventory_contents = player_inventory.get_inventory_contents()
	var has_required_item = false
	var player_item_quantity = 0
	
	for item in inventory_contents:
		if item.get("nombre", "").to_lower() == req_nombre.to_lower():
			player_item_quantity = item.get("cantidad", 0)
			if player_item_quantity >= req_cantidad:
				has_required_item = true
			break
	
	print("💰 [TRADE] Jugador tiene ", player_item_quantity, " de ", req_nombre, " (necesita ", req_cantidad, ")")
	
	if not has_required_item:
		_show_dialogue_ui("Comerciante", "No tienes suficiente " + req_nombre + ". Necesitas x" + str(req_cantidad) + " pero solo tienes x" + str(player_item_quantity), interactor)
		return
	
	# 🔧 REALIZAR EL INTERCAMBIO
	var removed = player_inventory.remove_item(int(req_objeto_id), req_cantidad)
	if removed:
		# Agregar el objeto ofrecido
		var item_data = {
			"nombre": offer_nombre,
			"tipo_objeto": "RECURSO",
			"peso_unidad": 0.2,
			"es_apilable": true,
			"descripcion": "Obtenido por comercio"
		}
		player_inventory.add_item(int(offer_objeto_id), offer_cantidad, item_data)
		
		print("✅ [TRADE] Comercio exitoso!")
		_show_dialogue_ui("Comerciante", "¡Excelente! Has intercambiado " + req_nombre + " x" + str(req_cantidad) + " por " + offer_nombre + " x" + str(offer_cantidad), interactor)
		_close_interaction_menu()
	else:
		print("❌ [TRADE] Error al remover items del inventario")
		_show_dialogue_ui("Comerciante", "Hubo un problema con el intercambio.", interactor)

func _show_build_ui(interactor: Node):
	print("🔨 [BUILD] Abriendo interfaz de construcción")
	_show_dialogue_ui("Constructor", "¿Qué quieres que construya?\n\n1. Casa de madera (20 madera, 10 piedra)\n2. Cerca (5 madera)\n3. Pozo (15 piedra)\n\n(Sistema en desarrollo...)", interactor)

func _show_craft_ui(interactor: Node):
	print("⚒️ [CRAFT] Abriendo interfaz de crafteo")
	_show_dialogue_ui("Artesano", "Puedo crear herramientas y armas básicas.\n\n• Espada básica (3 hierro)\n• Hacha (2 hierro, 1 madera)\n• Armadura (5 hierro)\n\n(Sistema en desarrollo...)", interactor)

func _show_interaction_menu(interactor: Node):
	print("📋 [MENU] Mostrando menú de interacciones")
	interaction_menu_active = true
	
	var menu_text = "¿Qué quieres hacer?\n\n"
	for i in range(available_actions.size()):
		var action = available_actions[i]
		menu_text += str(i + 1, ". ", _get_action_display_name(action), "\n")
	
	menu_text += "\n(Presiona el número de la opción o ESC para cancelar)"
	
	var dialogue_ui = _create_interaction_menu_ui("Opciones", menu_text)
	get_tree().root.add_child(dialogue_ui)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_interaction_menu():
	interaction_menu_active = false
	current_interactor = null
	
	# Cerrar cualquier diálogo abierto
	var dialogues = get_tree().get_nodes_in_group("interaction_menu")
	for dialogue in dialogues:
		if is_instance_valid(dialogue):
			dialogue.queue_free()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _get_action_display_name(action: String) -> String:
	match action:
		"talk": return "Hablar"
		"trade": return "Comerciar"
		"recruit": return "Reclutar como aliado"
		"dismiss": return "Despedir"
		"build": return "Construir"
		"craft": return "Crear objeto"
		"follow": return "Seguir"
		"stay": return "Quedarse aquí"
		_: return action.capitalize()

func _create_interaction_menu_ui(title: String, text: String) -> Control:
	var menu_ui = Control.new()
	menu_ui.name = "InteractionMenuUI"
	menu_ui.add_to_group("interaction_menu")
	menu_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Fondo semi-transparente
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_ui.add_child(background)
	
	# Panel de menú
	var menu_panel = Panel.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_panel.custom_minimum_size = Vector2(400, 250)
	menu_panel.position = Vector2(-200, -125)
	menu_ui.add_child(menu_panel)
	
	# Título
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 10)
	title_label.size = Vector2(400, 30)
	menu_panel.add_child(title_label)
	
	# Texto del menú
	var menu_label = Label.new()
	menu_label.text = text
	menu_label.position = Vector2(20, 50)
	menu_label.size = Vector2(360, 150)
	menu_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_panel.add_child(menu_label)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "Cancelar (ESC)"
	close_button.position = Vector2(150, 210)
	close_button.size = Vector2(100, 30)
	close_button.pressed.connect(func(): _close_interaction_menu())
	menu_panel.add_child(close_button)
	
	return menu_ui

func _create_dialogue_ui(npc_name: String, text: String) -> Control:
	var dialogue_ui = Control.new()
	dialogue_ui.name = "DialogueUI"
	dialogue_ui.add_to_group("dialogue_ui")
	dialogue_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Fondo semi-transparente
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_ui.add_child(background)
	
	# Panel de diálogo
	var dialogue_panel = Panel.new()
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialogue_panel.custom_minimum_size = Vector2(500, 200)
	dialogue_panel.position = Vector2(-250, -100)
	dialogue_ui.add_child(dialogue_panel)
	
	# Nombre del NPC
	var name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(460, 30)
	dialogue_panel.add_child(name_label)
	
	# Texto del diálogo
	var dialogue_label = Label.new()
	dialogue_label.text = text
	dialogue_label.position = Vector2(20, 50)
	dialogue_label.size = Vector2(460, 100)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_panel.add_child(dialogue_label)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.text = "Cerrar (ESC)"
	close_button.position = Vector2(200, 160)
	close_button.size = Vector2(100, 30)
	close_button.pressed.connect(func(): 
		dialogue_ui.queue_free()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	)
	dialogue_panel.add_child(close_button)
	
	return dialogue_ui
