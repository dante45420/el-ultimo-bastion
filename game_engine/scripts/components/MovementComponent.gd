# res://scripts/components/MovementComponent.gd
extends Node
class_name MovementComponent

## Componente que gestiona el movimiento físico, la gravedad y las colisiones de una entidad.
## Es agnóstico a si es un jugador o un NPC. Recibe órdenes y las ejecuta.

# --- Variables Exportables ---
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 12.0

# --- Variables Internas ---
var parent_body: CharacterBody3D # Referencia al cuerpo físico que vamos a mover

# Esta variable almacenará la dirección deseada de movimiento,
# ya sea desde el input del jugador o desde la IA del NPC.
var move_direction: Vector3 = Vector3.ZERO

func _ready():
	# Es crucial que el padre de este nodo sea un CharacterBody3D.
	# Si no lo es, este componente no funcionará.
	if not get_parent() is CharacterBody3D:
		print("¡ERROR CRÍTICO! MovementComponent debe ser hijo de un CharacterBody3D.")
		queue_free() # Se autodestruye para evitar más errores.
		return
	parent_body = get_parent()

func _physics_process(delta):
	if not parent_body: return

	# 1. Aplicar Gravedad
	if not parent_body.is_on_floor():
		parent_body.velocity.y -= gravity * delta

	# 2. Procesar el movimiento horizontal
	# La dirección (move_direction) es establecida por una fuente externa (Player o AI)
	if move_direction:
		parent_body.velocity.x = move_direction.x * speed
		parent_body.velocity.z = move_direction.z * speed
	else:
		parent_body.velocity.x = move_toward(parent_body.velocity.x, 0, speed)
		parent_body.velocity.z = move_toward(parent_body.velocity.z, 0, speed)

	# 3. Ejecutar el movimiento
	parent_body.move_and_slide()

	# 4. Resetear la dirección para el siguiente frame.
	# Esto es importante para que la entidad se detenga si no recibe nuevas órdenes.
	move_direction = Vector3.ZERO

# --- Funciones Públicas (API del Componente) ---

## Esta es la función principal que el Player o la IA llamarán cada frame
## para decirle al componente hacia dónde moverse.
func set_move_direction(direction: Vector3):
	move_direction = direction

## Función para saltar.
func jump():
	if parent_body and parent_body.is_on_floor():
		parent_body.velocity.y = jump_velocity
