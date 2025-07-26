# el-ultimo-bastion/game_engine/scripts/NPC.gd
# VERSIÓN COMPLETA Y DEFINITIVA CON CORRECCIÓN DE ALTURA
extends CharacterBody3D
class_name NPC

@onready var name_label: Label3D = $NameLabel

const GRAVITY = 9.8 

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

func initialize_npc(instance_data: Dictionary):
	var pos_dict = instance_data.get("posicion", {"x":0, "y":5, "z":0})
	# CORRECCIÓN: Usamos global_position para asegurar que la altura sea absoluta y no relativa.
	self.global_position = Vector3(pos_dict.get("x"), pos_dict.get("y"), pos_dict.get("z"))
	
	self.collision_layer = 4 # Capa 3 para NPCs
	self.collision_mask = 1  # Choca con el mundo
	
	var npc_name = "NPC Desconocido"
	# Esta lógica es para el futuro, cuando el backend anide los datos del TipoNPC
	if instance_data.has("tipo_npc") and instance_data.get("tipo_npc") is Dictionary:
		npc_name = instance_data.get("tipo_npc").get("nombre", "Error Nombre")
		
	name_label.text = str(npc_name, " (ID: ", instance_data.get("id", 0), ")")

	_create_default_visual_and_hitbox()

func _create_default_visual_and_hitbox():
	for child in get_children():
		if (child is MeshInstance3D or child is CollisionShape3D) and child != name_label:
			child.queue_free()

	var default_visual = MeshInstance3D.new()
	var default_mesh = BoxMesh.new()
	default_mesh.size = Vector3(1, 1, 1)
	var npc_material = StandardMaterial3D.new()
	npc_material.albedo_color = Color.GREEN
	default_visual.material_override = npc_material
	default_visual.mesh = default_mesh
	# La posición del visual se levanta para que su base esté en y=0
	default_visual.position.y = 0.5 
	add_child(default_visual)

	var default_hitbox = CollisionShape3D.new()
	var default_shape = BoxShape3D.new()
	default_shape.size = Vector3(1, 1, 1)
	default_hitbox.shape = default_shape
	# La colisión también se levanta para coincidir con el visual
	default_hitbox.position.y = 0.5
	add_child(default_hitbox)
