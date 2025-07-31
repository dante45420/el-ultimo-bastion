# res://scripts/NPC.gd
# VERSIÓN FINAL CON INICIALIZACIÓN COMPLETA DE TODOS LOS COMPONENTES
extends CharacterBody3D
class_name NPC

# --- Referencias a Nodos y Componentes ---
# La anotación @onready asegura que Godot asigne estas variables
# justo antes de que se llame a la función _ready().
@onready var name_label: Label3D = $NameLabel
@onready var health_component: HealthComponent = $HealthComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var ai_component: AIComponent = $AIComponent
@onready var interaction_component: InteractionComponent = $InteractionComponent
@onready var visuals_component: VisualsComponent = $VisualsComponent
@onready var combat_component: CombatComponent = $CombatComponent
# Añade aquí @onready var para los otros componentes cuando los agregues a la escena

var npc_id: int

## La única función pública del script. Es llamada por World.gd al crear el NPC.
## Su trabajo es distribuir los datos del backend a cada componente para que se inicialice.
func initialize_npc(instance_data: Dictionary):
	var tipo_npc_data = instance_data.get("tipo_npc", {})
	var valores_rol = tipo_npc_data.get("valores_rol", {})
	npc_id = instance_data.get("id", 0)

	# --- Posición y Física ---
	var pos_dict = instance_data.get("posicion", {"x": 0.0, "y": 5.0, "z": 0.0})
	self.global_position = Vector3(pos_dict.x, pos_dict.y, pos_dict.z)
	self.collision_layer = 4  # Capa "npcs"
	self.collision_mask = 1 | 2 | 4 # Colisiona con "mundo", "jugador" y otros "npcs"

	# --- Inicialización de Componentes (con comprobaciones de seguridad) ---
	
	if is_instance_valid(visuals_component):
		print(str("[DEBUG] NPC: Llamando create_visuals con valores_rol: ", JSON.stringify(valores_rol)))
		visuals_component.create_visuals(valores_rol)
		print(str("[DEBUG] NPC: create_visuals completado para NPC ID: ", npc_id))

	var cvb_data = instance_data.get("criatura_viva_base", {})
	var danio_data = cvb_data.get("danio", {})
	
	if is_instance_valid(health_component):
		# OBTENER LOOT SETTINGS
		var loot_settings = valores_rol.get("loot_settings", {})
		
		health_component.initialize_health(
			npc_id, "NPC",
			danio_data.get("salud_max", 100),
			danio_data.get("salud_actual", 100),
			-1,  # loot_table_id (por ahora -1)
			tipo_npc_data.get("resistencia_dano", {}),  # resistance_map
			loot_settings  # NUEVO: pasar loot_settings
		)
		health_component.died.connect(Callable(self, "_on_death"))

	if is_instance_valid(movement_component):
		movement_component.speed = tipo_npc_data.get("initial_velocidad_movimiento", 3.0)
	
	if is_instance_valid(ai_component):
		ai_component.initialize_ai(instance_data)
	else:
		print("¡ERROR GRAVE en NPC ID ", npc_id, "! No se encontró el nodo AIComponent. El NPC no tendrá inteligencia.")

	if is_instance_valid(combat_component):
		var combat_settings = valores_rol.get("combat_settings", {})
		combat_component.base_damage = tipo_npc_data.get("initial_dano_ataque_base", 5.0)
		combat_component.attack_range = combat_settings.get("range", 1.5)
		combat_component.attack_cooldown = combat_settings.get("cooldown", 2.0)

	if is_instance_valid(interaction_component):
		var interaction_settings = valores_rol.get("interaction_settings", {})
		interaction_component.initialize_interactions(interaction_settings, instance_data)
		# (Opcional) Conectar la señal de interacción a la IA para futuras reacciones
		# interaction_component.interacted.connect(ai_component.on_interacted)

	# --- UI ---
	if is_instance_valid(name_label):
		name_label.text = str(tipo_npc_data.get("nombre", "NPC"), " (", npc_id, ")")
		var visual_height = valores_rol.get("hitbox_dimensions", {}).get("height", 1.8)
		name_label.global_position = self.global_position + Vector3(0, visual_height + 0.2, 0)

## Se conecta a la señal 'died' del HealthComponent.
func _on_death(_entity_id, _entity_type):
	# Cuando morimos, le decimos a los componentes relevantes que dejen de funcionar.
	if is_instance_valid(ai_component):
		ai_component.set_process(false) # La IA deja de pensar.
	
	if is_instance_valid(interaction_component):
		interaction_component.available_actions = [] # No se puede interactuar con un cuerpo muerto.
	
	if is_instance_valid(name_label):
		name_label.visible = false # Ocultamos el nombre.
	
	# La lógica de desaparecer el cuerpo ya está en HealthComponent.gd, lo cual es perfecto.
