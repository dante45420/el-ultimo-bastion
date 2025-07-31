# res://components/HungerComponent.gd
extends Node
class_name HungerComponent

@export var debug_mode: bool = true

var entity_id: int = -1
var entity_type: String 
var max_hunger: int = 100
var current_hunger: int = 100
var hunger_decay_rate: float = 0.00278  # Solo para referencia
var damage_per_starvation_tick: float = 5.0 
var starvation_tick_interval: float = 5.0

# 🔧 TIMERS SEPARADOS
var hunger_decay_timer: Timer  # Para reducir hambre cada 5 segundos
var starvation_timer: Timer    # Para aplicar daño cuando hambre = 0

@onready var health_component: HealthComponent = get_parent().find_child("HealthComponent")

signal hunger_changed(new_hunger: int, max_hunger: int)
signal starved(entity_id: int, entity_type: String)

func _ready():
	if debug_mode: print(str("[DEBUG] HungerComponent: _ready() para ", entity_type, " ID: ", entity_id))
	
	# 🔧 CREAR TIMER DE REDUCCIÓN DE HAMBRE (cada 5 segundos)
	hunger_decay_timer = Timer.new()
	add_child(hunger_decay_timer)
	hunger_decay_timer.wait_time = 5.0  # Cada 5 segundos
	hunger_decay_timer.one_shot = false
	hunger_decay_timer.timeout.connect(Callable(self, "_on_hunger_decay_timer_timeout"))
	# NO iniciar aún - esperar a que se inicialice
	
	# 🔧 CREAR TIMER DE INANICIÓN (cada 5 segundos cuando hambre = 0)
	starvation_timer = Timer.new()
	add_child(starvation_timer)
	starvation_timer.wait_time = starvation_tick_interval
	starvation_timer.one_shot = false
	starvation_timer.timeout.connect(Callable(self, "_on_starvation_timer_timeout"))
	# NO iniciar aún

	if not health_component:
		if debug_mode: print("-----> ¡ERROR! HungerComponent: HealthComponent no encontrado.")

func initialize_hunger(p_entity_id: int, p_entity_type: String, p_max_hunger: int, p_current_hunger: int, p_decay_rate: float = 0.00278):
	print("🔧 [HUNGER INIT] ===== INICIALIZANDO HAMBRE =====")
	print("🔧 [HUNGER INIT] Entity: ", p_entity_type, " ID: ", p_entity_id)
	print("🔧 [HUNGER INIT] Hambre: ", p_current_hunger, "/", p_max_hunger)
	
	entity_id = p_entity_id
	entity_type = p_entity_type
	max_hunger = p_max_hunger
	current_hunger = p_current_hunger
	hunger_decay_rate = p_decay_rate
	
	# 🔧 INICIAR TIMER DE HAMBRE
	if hunger_decay_timer:
		hunger_decay_timer.start()
		print("🔧 [HUNGER INIT] Timer de reducción de hambre iniciado (cada 5 segundos)")
	
	print("🔧 [HUNGER INIT] ===== INICIALIZACIÓN COMPLETA =====")
	emit_signal("hunger_changed", current_hunger, max_hunger)

# 🔧 NUEVA FUNCIÓN: Se llama cada 5 segundos para reducir hambre
func _on_hunger_decay_timer_timeout():
	if entity_id == -1:
		return  # No procesamos si no está inicializado
	
	if current_hunger > 0:
		var old_hunger = current_hunger
		# 🔧 REDUCIR 1 PUNTO DE HAMBRE CADA 5 SEGUNDOS
		current_hunger = max(0, current_hunger - 1)
		
		print("🍖 [HUNGER] ", entity_type, " ID:", entity_id, " - Hambre: ", old_hunger, " -> ", current_hunger, " (-1 cada 5 seg)")
		
		emit_signal("hunger_changed", current_hunger, max_hunger)
		
		if current_hunger == 0:
			print("🍖 [HUNGER] ", entity_type, " ID: ", entity_id, " ha llegado a 0 de hambre! Iniciando inanición...")
			# Iniciar timer de inanición
			if starvation_timer:
				starvation_timer.start()
			emit_signal("starved", entity_id, entity_type)

# 🔧 FUNCIÓN DE INANICIÓN: Se llama cada 5 segundos cuando hambre = 0
func _on_starvation_timer_timeout():
	if current_hunger == 0:
		print("💀 [STARVATION] ", entity_type, " ID: ", entity_id, " recibiendo daño por inanición (", damage_per_starvation_tick, " daño)")
		if health_component and is_instance_valid(health_component):
			health_component.take_damage(damage_per_starvation_tick, "STARVATION")
		else:
			print("-----> ¡ADVERTENCIA! HungerComponent: No se pudo aplicar daño por inanición.")
	else:
		# Si la hambre ya no es 0, detener el timer de inanición
		starvation_timer.stop()
		print("🍖 [HUNGER] Inanición detenida - hambre restaurada")

func eat(amount: float):
	current_hunger += int(amount)
	current_hunger = min(current_hunger, max_hunger)
	print("🍖 [FOOD] ", entity_type, " ID: ", entity_id, " comió. Hambre actual: ", current_hunger)
	emit_signal("hunger_changed", current_hunger, max_hunger)
	
	# Si la hambre ya no es 0, detener timer de inanición
	if current_hunger > 0 and starvation_timer.is_stopped() == false:
		starvation_timer.stop()
		print("🍖 [HUNGER] Timer de inanición detenido")

func restore_hunger(amount: int):
	var old_hunger = current_hunger
	current_hunger = min(current_hunger + amount, max_hunger)
	print("🍖 [FOOD] Hambre restaurada: ", old_hunger, " -> ", current_hunger, " (+", amount, ")")
	emit_signal("hunger_changed", current_hunger, max_hunger)
	
	# Si la hambre ya no es 0, detener timer de inanición
	if current_hunger > 0 and starvation_timer.is_stopped() == false:
		starvation_timer.stop()
		print("🍖 [HUNGER] Timer de inanición detenido")
