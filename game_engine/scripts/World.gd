# el-ultimo-bastion/game_engine/scripts/World.gd
extends Node3D
class_name World

var data_loader: DataLoader
var world_name_label: Label3D
var ground_container: Node3D
var npc_container: Node3D

var current_world_data: Dictionary = {}
var block_mesh: Mesh = preload("res://assets/default_block_mesh.tres")
var block_material: Material = preload("res://assets/default_block_material.tres")

const NPC_SCENE = preload("res://scenes/NPC.tscn")

func _ready():
	# Esta parte no cambia, sigue siendo correcta
	print("[DEBUG] World: _ready() INICIADO.")
	data_loader = get_node("DataLoader")
	world_name_label = get_node("WorldNameLabel")
	ground_container = get_node("GroundContainer")
	npc_container = get_node("NPCContainer")

	var emergency_floor = StaticBody3D.new()
	emergency_floor.collision_layer = 1
	var floor_shape = CollisionShape3D.new()
	var floor_mesh = MeshInstance3D.new()
	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(500, 1, 500)
	floor_mesh.mesh = plane_mesh
	floor_shape.shape = plane_mesh.create_convex_shape()
	emergency_floor.add_child(floor_mesh)
	emergency_floor.add_child(floor_shape)
	emergency_floor.position.y = -10
	add_child(emergency_floor)
	print("[DEBUG] World: Suelo de emergencia creado en la capa de colisión 1.")

	if data_loader:
		data_loader.request_completed_success.connect(self._on_world_list_loaded)
		data_loader.request_failed.connect(self._on_world_list_failed)
		print("[DEBUG] World: Solicitando lista de mundos...")
		data_loader.get_mundos_list()
	else:
		print("-----> ¡ERROR! World: No se encontró el DataLoader. Generando mundo por defecto.")
		_generate_default_world()


func _generate_terrain(p_seed: String, config: Dictionary):
	if not ground_container: return

	# Esta parte de la configuración del ruido no cambia
	var terrain_size = int(config.get("terrain_size", 50))
	var terrain_height_scale = float(config.get("terrain_height_scale", 10.0))
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = 0.03
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.0
	noise.seed = p_seed.hash()
	noise.frequency = float(config.get("noise_frequency", noise.frequency))
	noise.fractal_octaves = int(config.get("noise_octaves", noise.fractal_octaves))
	noise.fractal_lacunarity = float(config.get("noise_lacunarity", noise.fractal_lacunarity))
	var base_height_offset = -5
	var block_scale = 1.0
	var offset_x = (terrain_size * block_scale) / 2.0
	var offset_z = (terrain_size * block_scale) / 2.0

	print(str("[DEBUG] World: Generando terreno con semilla '", p_seed, "' y tamaño ", terrain_size))
	
	# ---- SECCIÓN DE CÓDIGO COMPLETAMENTE REESCRITA Y CORREGIDA ----
	for x_idx in range(terrain_size):
		for z_idx in range(terrain_size):
			var noise_val = noise.get_noise_2d(float(x_idx), float(z_idx))
			var height = int(noise_val * terrain_height_scale) + base_height_offset
			for y_idx in range(height + 1):
				# 1. Crear el cuerpo físico. ¡Este es el que lleva las propiedades de colisión!
				var static_body = StaticBody3D.new()
				static_body.collision_layer = 1 # Se asigna la capa de colisión AL CUERPO FÍSICO.
				
				# 2. Crear la forma de la colisión.
				var collision_shape = CollisionShape3D.new()
				collision_shape.shape = block_mesh.create_trimesh_shape()
				
				# 3. Crear el modelo visual (el cubo que vemos).
				var mesh_instance = MeshInstance3D.new()
				mesh_instance.mesh = block_mesh
				mesh_instance.material_override = block_material
				
				# 4. Unir todo en el orden correcto.
				static_body.add_child(mesh_instance) # El visual es hijo del cuerpo.
				static_body.add_child(collision_shape) # La forma de colisión también es hija del cuerpo.
				
				# 5. Posicionar el cuerpo completo.
				var pos = Vector3((x_idx * block_scale) - offset_x, y_idx * block_scale, (z_idx * block_scale) - offset_z)
				static_body.position = pos
				
				# 6. Añadir el cuerpo completo (con sus hijos) a la escena.
				ground_container.add_child(static_body)

	print("[DEBUG] World: Generación de terreno completada.")
	
	# El resto de las funciones no necesitan cambios.
	# ...
func _on_world_list_loaded(data, status_code):
	data_loader.request_completed_success.disconnect(self._on_world_list_loaded)
	data_loader.request_failed.disconnect(self._on_world_list_failed)
	if status_code == 200 and data is Array and data.size() > 0:
		var sandbox_mundo = data.filter(func(mundo): return mundo.get("nombre_mundo") == "Mundo Sandbox para Devs")
		current_world_data = sandbox_mundo[0] if not sandbox_mundo.is_empty() else data[0]
		_generate_world_from_data()
	else:
		_generate_default_world()

func _on_world_list_failed(_status_code, _error_data):
	data_loader.request_completed_success.disconnect(self._on_world_list_loaded)
	data_loader.request_failed.disconnect(self._on_world_list_failed)
	_generate_default_world()

func _generate_default_world():
	current_world_data = {
		"id": -1, "nombre_mundo": "Mundo por Defecto", "semilla_generacion": "DEFAULT_SEED",
		"configuracion_actual": {"terrain_size": 30, "terrain_height_scale": 5.0}
	}
	_generate_world_from_data()

func _generate_world_from_data():
	for child in ground_container.get_children(): child.queue_free()
	for child in npc_container.get_children(): child.queue_free()
	var p_seed = current_world_data.get("semilla_generacion", "DEFAULT_SEED")
	var world_config = current_world_data.get("configuracion_actual", {})
	world_name_label.text = "Mundo: " + current_world_data.get("nombre_mundo", "Mundo Desconocido")
	_generate_terrain(p_seed, world_config)
	var world_id = current_world_data.get("id", -1)
	if world_id != -1:
		data_loader.request_completed_success.connect(self._on_instancias_npc_loaded)
		data_loader.request_failed.connect(self._on_instancias_npc_failed)
		data_loader.get_instancias_npc_by_mundo(world_id)

func _on_instancias_npc_loaded(data, status_code):
	data_loader.request_completed_success.disconnect(self._on_instancias_npc_loaded)
	data_loader.request_failed.disconnect(self._on_instancias_npc_failed)
	if status_code == 200 and data is Array: _generate_npcs(data)

func _on_instancias_npc_failed(_status_code, _error_data):
	data_loader.request_completed_success.disconnect(self._on_instancias_npc_loaded)
	data_loader.request_failed.disconnect(self._on_instancias_npc_failed)

func _generate_npcs(npcs_data: Array):
	if not npc_container: return
	for npc_instance_data in npcs_data:
		var npc_node = NPC_SCENE.instantiate()
		npc_container.add_child(npc_node)
		if npc_node.has_method("initialize_npc"):
			npc_node.initialize_npc(npc_instance_data)
