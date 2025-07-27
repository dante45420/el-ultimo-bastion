# res://components/HungerComponent.gd
extends Node
class_name HungerComponent

@export var debug_mode: bool = true

var entity_id: int = -1
var entity_type: String 
var max_hunger: int = 1
var current_hunger: int = 1
var hunger_decay_rate: float = 0.1 # <--- AJUSTADO: Hambre perdida por segundo (0.1 puntos/seg, mucho más lento)
var damage_per_starvation_tick: float = 5.0 
var starvation_tick_interval: float = 5.0 # Cada cuántos segundos se aplica daño por inanición

var starvation_timer: Timer

@onready var health_component: HealthComponent = get_parent().find_child("HealthComponent")


signal hunger_changed(new_hunger: int, max_hunger: int)
signal starved(entity_id: int, entity_type: String)

func _ready():
	if debug_mode: print(str("[DEBUG] HungerComponent: _ready() para ", entity_type, " ID: ", entity_id))

	starvation_timer = Timer.new()
	add_child(starvation_timer)
	starvation_timer.wait_time = starvation_tick_interval
	starvation_timer.one_shot = false
	starvation_timer.timeout.connect(Callable(self, "_on_starvation_timer_timeout"))
	starvation_timer.start()

	if not health_component:
		if debug_mode: print("-----> ¡ERROR! HungerComponent: HealthComponent no encontrado. No se podrá aplicar daño por inanición.")


func initialize_hunger(p_entity_id: int, p_entity_type: String, p_max_hunger: int, p_current_hunger: int, p_decay_rate: float = 0.1): # <--- AJUSTADO el default aquí también
	entity_id = p_entity_id
	entity_type = p_entity_type
	max_hunger = p_max_hunger
	current_hunger = p_current_hunger
	hunger_decay_rate = p_decay_rate
	if debug_mode: print(str("[DEBUG] HungerComponent: Inicializado para ", entity_type, " ID: ", entity_id, ". Hambre: ", current_hunger, "/", max_hunger, ", Decay: ", hunger_decay_rate, "pts/seg"))
	emit_signal("hunger_changed", current_hunger, max_hunger)


func _process(delta):
	if current_hunger > 0:
		current_hunger -= hunger_decay_rate * delta
		current_hunger = max(0, int(current_hunger))
		emit_signal("hunger_changed", current_hunger, max_hunger)
		if current_hunger == 0:
			if debug_mode: print(str("[DEBUG] HungerComponent: ", entity_type, " ID: ", entity_id, " ha llegado a 0 de hambre."))
			emit_signal("starved", entity_id, entity_type)

func eat(amount: float):
	current_hunger += int(amount)
	current_hunger = min(current_hunger, max_hunger)
	if debug_mode: print(str("[DEBUG] HungerComponent: ", entity_type, " ID: ", entity_id, " comió. Hambre actual: ", current_hunger))
	emit_signal("hunger_changed", current_hunger, max_hunger)

func _on_starvation_timer_timeout():
	if current_hunger == 0:
		if debug_mode: print(str("[DEBUG] HungerComponent: ", entity_type, " ID: ", entity_id, " recibiendo daño por inanición."))
		if health_component and is_instance_valid(health_component):
			health_component.take_damage(damage_per_starvation_tick, "STARVATION")
		else:
			if debug_mode: print("-----> ¡ADVERTENCIA! HungerComponent: No se pudo aplicar daño por inanición, HealthComponent no válido.")
