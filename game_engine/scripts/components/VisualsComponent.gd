# res://scripts/components/VisualsComponent.gd
# VERSIÓN CORREGIDA SIN CÓDIGO DUPLICADO
extends Node
class_name VisualsComponent

## Gestiona la apariencia visual y la forma de colisión física de una entidad.
var parent_body: Node3D
var current_visual_model: MeshInstance3D
var current_collision_shape: CollisionShape3D

func _ready():
	parent_body = get_parent()
	if not parent_body is Node3D:
		print("¡ERROR! VisualsComponent debe ser hijo de un Node3D.")
		queue_free()

## Crea un visual y un hitbox basados en los datos proporcionados.
func create_visuals(visual_data: Dictionary):
	print(str("[DEBUG] VisualsComponent: create_visuals() llamado con datos: ", JSON.stringify(visual_data)))
	
	_clear_existing_visuals()

	var hitbox_dims = visual_data.get("hitbox_dimensions", {"radius": 0.5, "height": 1.8})
	var color_hex = visual_data.get("color", "#8A2BE2")
	
	print(str("[DEBUG] VisualsComponent: hitbox_dims = ", hitbox_dims))
	print(str("[DEBUG] VisualsComponent: color_hex = ", color_hex))

	current_visual_model = MeshInstance3D.new()
	current_visual_model.name = "VisualModel"
	
	current_collision_shape = CollisionShape3D.new()
	current_collision_shape.name = "HitboxCollision"

	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = hitbox_dims.get("radius", 0.5)
	capsule_shape.height = hitbox_dims.get("height", 1.8)
	
	print(str("[DEBUG] VisualsComponent: Cápsula creada - radio: ", capsule_shape.radius, ", altura: ", capsule_shape.height))
	
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = capsule_shape.radius
	capsule_mesh.height = capsule_shape.height
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color_hex)
	
	print(str("[DEBUG] VisualsComponent: Color aplicado: ", material.albedo_color))
	
	current_visual_model.mesh = capsule_mesh
	current_visual_model.material_override = material
	current_collision_shape.shape = capsule_shape
	
	var vertical_offset = capsule_shape.height / 2.0
	current_visual_model.position.y = vertical_offset
	current_collision_shape.position.y = vertical_offset
	
	parent_body.add_child(current_visual_model)
	parent_body.add_child(current_collision_shape)
	
	print(str("[DEBUG] VisualsComponent: ✅ Cuerpo visual y hitbox creados para ", parent_body.name, " en posición Y: ", vertical_offset))
	print(str("[DEBUG] VisualsComponent: Posición global final del parent: ", parent_body.global_position))

## ¡NUEVA FUNCIÓN! Se encarga de crear el parpadeo blanco.
func play_hit_flash():
	# Si no hay un modelo visual, no hacemos nada.
	if not is_instance_valid(current_visual_model): return
	
	# Obtenemos el material actual del modelo para poder manipularlo.
	var material = current_visual_model.get_active_material(0)
	if not material is StandardMaterial3D: return
	
	# Guardamos el color original para poder restaurarlo después.
	var original_color = material.albedo_color
	
	# Creamos una animación por código (Tween).
	var tween = create_tween()
	
	# La animación tiene 2 pasos:
	# 1. Cambia el color a blanco en 0.1 segundos.
	# 2. Inmediatamente después, lo cambia de vuelta al color original en otros 0.1 segundos.
	tween.tween_property(material, "albedo_color", Color.WHITE, 0.1)
	tween.tween_property(material, "albedo_color", original_color, 0.1)

## Función de ayuda para limpiar visuales antiguos.
func _clear_existing_visuals():
	# Usamos un bucle inverso para eliminar nodos de forma segura.
	for i in range(parent_body.get_child_count() - 1, -1, -1):
		var child = parent_body.get_child(i)
		if child.name == "VisualModel" or child.name == "HitboxCollision":
			child.queue_free()
