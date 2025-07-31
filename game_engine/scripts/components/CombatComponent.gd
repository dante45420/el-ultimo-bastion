# res://scripts/components/CombatComponent.gd
# REVERTIDO A LA VERSIÓN QUE FUNCIONABA PERFECTAMENTE
extends Node
class_name CombatComponent

@export var base_damage: float = 10.0
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 0.5

# --- PROPIEDADES PARA EFECTOS VISUALES ---
var attack_effect_type: String = "explosion"
var attack_effect_size: float = 1.0
var attack_effect_color: Color = Color.RED
var attack_effect_duration: float = 0.5

var can_attack: bool = true
var cooldown_timer: Timer
var parent_body: CharacterBody3D

func _ready():
	parent_body = get_parent()
	if not parent_body is CharacterBody3D:
		print("¡ERROR CRÍTICO! El padre de CombatComponent debe ser un CharacterBody3D")
		queue_free()
		return

	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.timeout.connect(func(): can_attack = true)
	add_child(cooldown_timer)

func initialize_combat(combat_data: Dictionary):
	base_damage = combat_data.get("base_damage", 10.0)
	attack_range = combat_data.get("attack_range", 10.0)
	attack_cooldown = combat_data.get("attack_cooldown", 0.5)
	
	var visual_effects = combat_data.get("visual_effects", {})
	attack_effect_type = visual_effects.get("type", "explosion")
	attack_effect_size = visual_effects.get("size", 1.0)
	attack_effect_color = Color(visual_effects.get("color", "#FF0000"))
	attack_effect_duration = visual_effects.get("duration", 0.5)
	
	cooldown_timer.wait_time = attack_cooldown
	
	print("DEBUG CombatComponent: Inicializado - Daño: %s, Rango: %s, Efecto: %s" % [base_damage, attack_range, attack_effect_type])

func execute_attack(camera: Camera3D):
	if not can_attack or not is_instance_valid(camera): 
		return

	can_attack = false
	cooldown_timer.start()

	var space_state = parent_body.get_world_3d().direct_space_state
	if not space_state: 
		return

	# *** EXACTAMENTE IGUAL QUE FUNCIONABA ***
	var closest_npc = _find_closest_npc()
	var ray_start = camera.global_position
	var ray_direction: Vector3
	var ray_end: Vector3
	
	if closest_npc and camera.global_position.distance_to(closest_npc.global_position) <= attack_range:
		ray_direction = camera.global_position.direction_to(closest_npc.global_position)
		ray_end = ray_start + (ray_direction * attack_range)
		print("DEBUG Combate: Apuntando hacia NPC cercano en %s" % closest_npc.global_position)
	else:
		ray_direction = -camera.global_transform.basis.z.normalized()
		ray_end = ray_start + (ray_direction * attack_range)
		print("DEBUG Combate: Usando dirección de cámara tradicional")
	
	print("DEBUG Combate: Rayo desde %s hasta %s" % [ray_start, ray_end])

	var query = PhysicsRayQueryParameters3D.new()
	query.from = ray_start
	query.to = ray_end
	query.exclude = [parent_body.get_rid()]
	query.collision_mask = 4

	# Mostrar línea de debug cyan
	_draw_debug_ray(query.from, query.to)

	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		var hit_point = result.position
		print("DEBUG Combate: ¡IMPACTO! Golpeado '%s' en %s" % [collider.name, hit_point])
		
		# *** EXACTAMENTE IGUAL QUE FUNCIONABA ***
		_create_attack_effect(hit_point)
		_create_impact_effect(hit_point)
		
		var target_health_component = collider.get_node_or_null("HealthComponent")
		if is_instance_valid(target_health_component):
			print("DEBUG Combate: Aplicando %s de daño a '%s'." % [base_damage, collider.name])
			target_health_component.take_damage(base_damage, "PHYSICAL_MELEE")

			var target_visuals_component = collider.get_node_or_null("VisualsComponent")
			if is_instance_valid(target_visuals_component):
				target_visuals_component.play_hit_flash()
	else:
		print("DEBUG Combate: El ataque no golpeó nada.")
		# *** EXACTAMENTE IGUAL QUE FUNCIONABA ***
		var effect_position = ray_start + (ray_direction * 2.0)
		_create_attack_effect(effect_position)

func _find_closest_npc():
	var space_state = parent_body.get_world_3d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters3D.new()
	
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = attack_range + 2.0
	shape_query.shape = sphere_shape
	shape_query.transform.origin = parent_body.global_position
	shape_query.collision_mask = 4
	
	var npcs_found = space_state.intersect_shape(shape_query)
	
	if npcs_found.is_empty():
		return null
	
	var closest_npc = null
	var closest_distance = INF
	
	for npc_data in npcs_found:
		var npc = npc_data.collider
		var distance = parent_body.global_position.distance_to(npc.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_npc = npc
	
	return closest_npc

func _draw_debug_ray(from_pos: Vector3, to_pos: Vector3):
	var line_drawer = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color.CYAN
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.flags_unshaded = true
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(from_pos)
	immediate_mesh.surface_add_vertex(to_pos)
	immediate_mesh.surface_end()
	
	line_drawer.mesh = immediate_mesh
	get_tree().root.add_child(line_drawer)
	
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(line_drawer):
		line_drawer.queue_free()

func _create_attack_effect(position: Vector3):
	match attack_effect_type:
		"explosion":
			_create_explosion_effect(position)
		"beam":
			_create_beam_effect(parent_body.global_position, position)
		"slash":
			_create_slash_effect(position)
		_:
			_create_explosion_effect(position)

# *** EXACTAMENTE LA MISMA EXPLOSIÓN ***
func _create_explosion_effect(position: Vector3):
	var explosion = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = attack_effect_color
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	
	sphere_mesh.radius = attack_effect_size * 0.5
	sphere_mesh.height = attack_effect_size
	
	explosion.mesh = sphere_mesh
	explosion.material_override = material
	explosion.global_position = position
	
	get_tree().root.add_child(explosion)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	explosion.scale = Vector3.ZERO
	tween.tween_property(explosion, "scale", Vector3.ONE * attack_effect_size, attack_effect_duration * 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, attack_effect_duration)
	
	await tween.finished
	if is_instance_valid(explosion):
		explosion.queue_free()

func _create_beam_effect(from_pos: Vector3, to_pos: Vector3):
	var beam = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = attack_effect_color
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var distance = from_pos.distance_to(to_pos)
	cylinder_mesh.top_radius = 0.05 * attack_effect_size
	cylinder_mesh.bottom_radius = 0.05 * attack_effect_size
	cylinder_mesh.height = distance
	
	beam.mesh = cylinder_mesh
	beam.material_override = material
	beam.global_position = (from_pos + to_pos) / 2
	beam.look_at(to_pos, Vector3.UP)
	
	get_tree().root.add_child(beam)
	
	var tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, attack_effect_duration)
	
	await tween.finished
	if is_instance_valid(beam):
		beam.queue_free()

func _create_slash_effect(position: Vector3):
	var slash = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = attack_effect_color
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	quad_mesh.size = Vector2(attack_effect_size, attack_effect_size * 0.1)
	
	slash.mesh = quad_mesh
	slash.material_override = material
	slash.global_position = position
	slash.rotation_degrees = Vector3(0, randf() * 360, randf() * 45)
	
	get_tree().root.add_child(slash)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(slash, "rotation_degrees:z", slash.rotation_degrees.z + 90, attack_effect_duration)
	tween.tween_property(material, "albedo_color:a", 0.0, attack_effect_duration)
	
	await tween.finished
	if is_instance_valid(slash):
		slash.queue_free()

func _create_impact_effect(position: Vector3):
	var particles = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color.WHITE
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	
	particles.mesh = sphere_mesh
	particles.material_override = material
	particles.global_position = position
	
	get_tree().root.add_child(particles)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(particles, "scale", Vector3.ONE * 2.0, 0.2)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.2)
	
	await tween.finished
	if is_instance_valid(particles):
		particles.queue_free()
