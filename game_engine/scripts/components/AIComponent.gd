# res://scripts/components/AIComponent.gd
# VERSIÓN CORREGIDA - SISTEMA DE ATAQUE FUNCIONAL
extends Node
class_name AIComponent

## El "cerebro" del NPC. Toma decisiones y da órdenes a otros componentes.

# --- Referencias a otros componentes ---
@onready var movement_component: MovementComponent = get_parent().get_node("MovementComponent")

# --- Estados de IA ---
enum AIState {
	IDLE,
	WANDERING, 
	CHASING,
	ATTACKING,
	FLEEING,
	FOLLOWING,     # 🆕 Siguiendo al jugador
	GUARDING,      # 🆕 Defendiendo un área
	PATROLLING     # 🆕 Patrullando puntos específicos
}

var current_state: AIState = AIState.IDLE

# --- Variables de Comportamiento ---
var can_wander: bool = true
var wander_range: float = 10.0
var wander_idle_time_min: float = 2.0
var wander_idle_time_max: float = 5.0

# --- Variables de Combate ---
var can_attack_player: bool = false
var vision_range: float = 20.0
var attack_range: float = 3.0
var attack_damage: float = 15.0
var attack_cooldown: float = 2.0
var current_target: Node = null

# --- Control de Tiempo ---
var last_attack_time: float = 0.0

var initial_position: Vector3
var wander_target_position: Vector3
var wander_timer: Timer

# --- Debugging ---
var debug_scan_timer: float = 0.0
var debug_scan_interval: float = 3.0  # Debug cada 3 segundos

# --- NUEVAS VARIABLES PARA ROLES ---
var role_type: String = "GENERICO"
var is_ally: bool = false
var ally_target: Node = null
var is_following: bool = false
var follow_target: Node = null
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0

func _ready():
	initial_position = get_parent().global_position
	wander_target_position = initial_position

	wander_timer = Timer.new()
	wander_timer.one_shot = true
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	add_child(wander_timer)
	
	_set_new_wander_timer()

func _process(delta):
	# Debugging periódico
	debug_scan_timer += delta
	if debug_scan_timer >= debug_scan_interval:
		debug_scan_timer = 0.0
		_debug_ai_status()
	
	# Máquina de estados de IA
	match current_state:
		AIState.IDLE:
			_process_idle()
		AIState.WANDERING:
			_process_wandering()
		AIState.CHASING:
			_process_chasing()
		AIState.ATTACKING:
			_process_attacking()
		AIState.FLEEING:
			_process_fleeing()
		AIState.FOLLOWING:
			_process_following()
		AIState.GUARDING:
			_process_guarding()
		AIState.PATROLLING:
			_process_patrolling()

# --- ESTADOS DE IA ---

func _process_idle():
	# Buscar objetivos si puede atacar
	if can_attack_player:
		_scan_for_targets()
	
	# Si no hay objetivos y puede deambular, cambiar a wandering
	if current_target == null and can_wander:
		current_state = AIState.WANDERING

func _process_wandering():
	# Buscar objetivos si puede atacar al jugador
	if can_attack_player:
		_scan_for_targets()
		if current_target:
			print("🎯 [AI] ", get_parent().name, " encontró objetivo - cambiando a CHASING")
			current_state = AIState.CHASING
			return
	
	# Continuar deambulando
	var distance_to_target = get_parent().global_position.distance_to(wander_target_position)
	if distance_to_target > 0.5:
		var direction = get_parent().global_position.direction_to(wander_target_position)
		movement_component.set_move_direction(direction)
	else:
		movement_component.set_move_direction(Vector3.ZERO)

func _process_chasing():
	if not current_target or not is_instance_valid(current_target):
		print("🔍 [AI] ", get_parent().name, " perdió objetivo - volviendo a WANDERING")
		current_target = null
		current_state = AIState.WANDERING
		return
	
	var distance_to_target = get_parent().global_position.distance_to(current_target.global_position)
	
	# Si está muy lejos, dejar de perseguir
	if distance_to_target > vision_range * 1.5:
		print("📏 [AI] ", get_parent().name, " objetivo muy lejos (", distance_to_target, ") - abandonando persecución")
		current_target = null
		current_state = AIState.WANDERING
		return
	
	# Si está cerca, atacar
	if distance_to_target <= attack_range:
		current_state = AIState.ATTACKING
		print("⚔️ [AI] ", get_parent().name, " en rango de ataque (", distance_to_target, ") - Cambiando a ATTACKING")
		return
	
	# Moverse hacia el objetivo
	var direction = get_parent().global_position.direction_to(current_target.global_position)
	movement_component.set_move_direction(direction)

func _process_attacking():
	if not current_target or not is_instance_valid(current_target):
		current_target = null
		current_state = AIState.WANDERING
		return
	
	var distance_to_target = get_parent().global_position.distance_to(current_target.global_position)
	
	# Si está fuera de rango, volver a perseguir
	if distance_to_target > attack_range:
		current_state = AIState.CHASING
		print("🏃 [AI] ", get_parent().name, " objetivo fuera de rango - volviendo a CHASING")
		return
	
	# Atacar si ha pasado el cooldown
	var current_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
	
	if current_time - last_attack_time >= attack_cooldown:
		print("💥 [AI] ", get_parent().name, " ATACANDO a ", current_target.name)
		_execute_attack()
		last_attack_time = current_time

func _process_fleeing():
	# Implementar lógica de huida si es necesario
	pass

func _process_following():
	if not follow_target or not is_instance_valid(follow_target):
		is_following = false
		current_state = AIState.WANDERING
		return
	
	var distance_to_target = get_parent().global_position.distance_to(follow_target.global_position)
	
	# Si está muy lejos, acercarse
	if distance_to_target > 5.0:
		var direction = get_parent().global_position.direction_to(follow_target.global_position)
		movement_component.set_move_direction(direction)
	# Si está muy cerca, detenerse
	elif distance_to_target < 2.0:
		movement_component.set_move_direction(Vector3.ZERO)

func _process_guarding():
	if not ally_target or not is_instance_valid(ally_target):
		is_ally = false
		current_state = AIState.WANDERING
		return
	
	# 🔍 BUSCAR ENEMIGOS que ataquen al aliado
	var enemies = get_tree().get_nodes_in_group("npcs")
	var closest_enemy: Node = null
	var min_distance = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == get_parent():
			continue
		
		# Verificar si el enemigo está atacando al aliado
		var enemy_ai = enemy.get_node_or_null("AIComponent")
		if enemy_ai and enemy_ai.current_target == ally_target:
			var distance = get_parent().global_position.distance_to(enemy.global_position)
			if distance < min_distance and distance <= vision_range:
				min_distance = distance
				closest_enemy = enemy
	
	if closest_enemy:
		current_target = closest_enemy
		current_state = AIState.CHASING
		print(str("⚔️ [AI GUARD] ", get_parent().name, " defendiendo al aliado contra ", closest_enemy.name))
	else:
		# Si no hay enemigos, seguir al aliado a cierta distancia
		var distance_to_ally = get_parent().global_position.distance_to(ally_target.global_position)
		if distance_to_ally > 8.0:
			var direction = get_parent().global_position.direction_to(ally_target.global_position)
			movement_component.set_move_direction(direction)
		elif distance_to_ally < 3.0:
			movement_component.set_move_direction(Vector3.ZERO)

func _process_patrolling():
	if patrol_points.is_empty():
		current_state = AIState.WANDERING
		return
	
	var target_point = patrol_points[current_patrol_index]
	var distance_to_point = get_parent().global_position.distance_to(target_point)
	
	if distance_to_point > 1.0:
		var direction = get_parent().global_position.direction_to(target_point)
		movement_component.set_move_direction(direction)
	else:
		# Llegar al punto, ir al siguiente
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		print(str("🚨 [AI PATROL] ", get_parent().name, " llegó al punto, yendo al siguiente"))

# --- FUNCIONES DE IA ---

func _scan_for_targets():
	# Buscar el jugador en el rango de visión
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Buscar por nombre si no está en grupo
		player = get_node_or_null("/root/MainScene/PlayerCharacter")
	
	if player and is_instance_valid(player):
		var distance = get_parent().global_position.distance_to(player.global_position)
		if distance <= vision_range:
			current_target = player
			print("👁️ [AI] ", get_parent().name, " DETECTÓ JUGADOR a distancia ", distance)

func _execute_attack():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Verificar que el objetivo tenga el método take_damage
	if current_target.has_method("take_damage"):
		print("🗡️ [AI] ", get_parent().name, " aplicando ", attack_damage, " de daño a ", current_target.name)
		current_target.take_damage(attack_damage, "PHYSICAL_MELEE")
		
		# Crear efecto visual de ataque (opcional)
		_create_attack_effect()
	else:
		print("❌ [AI] ", get_parent().name, " - objetivo no tiene método take_damage")

func _create_attack_effect():
	# Crear un efecto visual simple entre el NPC y el objetivo
	var effect_position = get_parent().global_position.lerp(current_target.global_position, 0.5)
	
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission = Color.RED
	sphere.material_override = material
	
	sphere.global_position = effect_position
	get_tree().root.add_child(sphere)
	
	# Eliminar después de 0.5 segundos
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.5
	timer.timeout.connect(sphere.queue_free)
	timer.timeout.connect(timer.queue_free)
	add_child(timer)
	timer.start()

func _debug_ai_status():
	if can_attack_player:
		var player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_node_or_null("/root/MainScene/PlayerCharacter")
		
		if player:
			var distance = get_parent().global_position.distance_to(player.global_position)
			print("🤖 [AI DEBUG] ", get_parent().name, " - Estado: ", AIState.keys()[current_state], 
				  " | Puede atacar: ", can_attack_player, " | Distancia jugador: ", round(distance), 
				  " | Objetivo: ", current_target.name if current_target else "ninguno")

# --- EVENTOS ---

func _on_wander_timer_timeout():
	_set_new_wander_target()
	_set_new_wander_timer()

func _set_new_wander_target():
	var rand_x = randf_range(-wander_range, wander_range)
	var rand_z = randf_range(-wander_range, wander_range)
	wander_target_position = initial_position + Vector3(rand_x, 0, rand_z)

func _set_new_wander_timer():
	wander_timer.wait_time = randf_range(wander_idle_time_min, wander_idle_time_max)
	wander_timer.start()

# --- API PÚBLICA ---

## Esta función será llamada por NPC.gd durante la inicialización
func initialize_ai(instance_data: Dictionary):
	print("🧠 [AI INIT] ", get_parent().name, " inicializando IA...")
	
	var tipo_npc_data = instance_data.get("tipo_npc", {})
	var valores_rol = tipo_npc_data.get("valores_rol", {})
	var combat_settings = valores_rol.get("combat_settings", {})
	var ai_settings = valores_rol.get("ai_settings", {})
	
	# 🆕 DETECTAR ROL DEL NPC
	role_type = tipo_npc_data.get("rol_npc", "GENERICO")
	print(str("🎭 [AI INIT] Rol detectado: ", role_type))
	
	# Configuración específica por rol
	match role_type:
		"GUARDIA", "DEFENSOR":
			vision_range = 25.0
			can_attack_player = false  # Los guardias no atacan por defecto
			print("🛡️ [AI INIT] Configurado como GUARDIA")
		"COMERCIANTE":
			can_attack_player = false
			can_wander = false  # Los comerciantes se quedan en su lugar
			print("💰 [AI INIT] Configurado como COMERCIANTE")
		"CONSTRUCTOR", "ARTESANO":
			can_attack_player = false
			vision_range = 15.0
			print("🔨 [AI INIT] Configurado como CONSTRUCTOR")
		"MASCOTA", "COMPANERO":
			can_attack_player = false
			vision_range = 20.0
			print("🐕 [AI INIT] Configurado como MASCOTA")
		"MALVADO":
			# 💀 CONFIGURACIÓN ESPECÍFICA PARA ENEMIGOS
			can_attack_player = true  # ¡Importante! Los malvados SÍ atacan
			vision_range = 20.0
			attack_damage = 25.0  # Más daño que otros NPCs
			attack_cooldown = 1.5  # Atacan más rápido
			print("💀 [AI INIT] Configurado como MALVADO - ¡MODO HOSTIL ACTIVADO!")
		"MAGO":
			can_attack_player = false  # Por defecto pacífico
			vision_range = 30.0  # Visión mágica extendida
			attack_range = 5.0  # Ataques a distancia
			print("🔮 [AI INIT] Configurado como MAGO")
	
	# Configuración desde datos del backend (puede sobrescribir defaults)
	can_wander = ai_settings.get("puede_deambular", can_wander)
	wander_range = ai_settings.get("wander_range", 10.0)
	
	# 🆕 IMPORTANTE: Permitir que backend sobrescriba configuraciones
	var backend_can_attack = combat_settings.get("puede_atacar_jugador", null)
	if backend_can_attack != null:
		can_attack_player = backend_can_attack
		print(str("⚠️ [AI INIT] Backend sobrescribió can_attack_player: ", can_attack_player))
	
	vision_range = valores_rol.get("rango_vision", vision_range)
	attack_range = combat_settings.get("range", attack_range)
	attack_cooldown = combat_settings.get("cooldown", attack_cooldown)
	
	# 🆕 CONFIGURACIONES ADICIONALES PARA AGRESIVIDAD
	var aggro_settings = valores_rol.get("aggro_settings", {})
	var es_agresivo = aggro_settings.get("es_agresivo", false)
	var ataca_first_sight = aggro_settings.get("ataca_first_sight", false)
	
	if es_agresivo or ataca_first_sight:
		can_attack_player = true
		print("💢 [AI INIT] NPC configurado como agresivo - forzando can_attack_player = true")
	
	print("✅ [AI INIT] ", get_parent().name, " configurado:")
	print("   - rol: ", role_type)
	print("   - puede_deambular: ", can_wander, " (rango: ", wander_range, ")")
	print("   - puede_atacar_jugador: ", can_attack_player)  # 🆕 DEBE SER TRUE PARA MALVADOS
	print("   - vision_range: ", vision_range)
	print("   - attack_range: ", attack_range)
	print("   - attack_damage: ", attack_damage)
	print("   - attack_cooldown: ", attack_cooldown)
	
	current_state = AIState.IDLE

## 🛡️ NUEVO: Configurar como aliado/guardia
func set_ally_mode(is_ally_now: bool, target: Node = null):
	is_ally = is_ally_now
	ally_target = target
	
	if is_ally and target:
		current_state = AIState.GUARDING
		vision_range = 25.0  # Aumentar rango de visión como guardia
		print(str("🛡️ [AI] ", get_parent().name, " ahora es ALIADO y protegerá al jugador"))
	else:
		current_state = AIState.WANDERING
		print(str("🚶 [AI] ", get_parent().name, " ya no es aliado"))

## 🐕 NUEVO: Configurar modo seguimiento
func set_follow_mode(should_follow: bool, target: Node = null):
	is_following = should_follow
	follow_target = target
	
	if should_follow and target:
		current_state = AIState.FOLLOWING
		print(str("🐕 [AI] ", get_parent().name, " ahora sigue al jugador"))
	else:
		current_state = AIState.WANDERING
		print(str("🏠 [AI] ", get_parent().name, " se queda en el lugar"))

## 🚨 NUEVO: Configurar patrullaje
func set_patrol_mode(points: Array[Vector3]):
	patrol_points = points
	current_patrol_index = 0
	current_state = AIState.PATROLLING
	print(str("🚨 [AI] ", get_parent().name, " patrullando ", points.size(), " puntos"))
