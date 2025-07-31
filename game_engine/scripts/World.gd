# el-ultimo-bastion/game_engine/scripts/World.gd
# VERSIÓN CORREGIDA CON selected_world_id DECLARADA
extends Node3D
class_name World

var data_loader: DataLoader
var world_name_label: Label3D
var ground_container: Node3D
var npc_container: Node3D 

# --- VARIABLE QUE FALTABA ---
var selected_world_id = null

var current_world_data: Dictionary = {}
var block_mesh: Mesh = preload("res://assets/default_block_mesh.tres")
var block_material: Material = preload("res://assets/default_block_material.tres")

# Asegúrate que esta ruta es ABSOLUTAMENTE CORRECTA y que NPC.tscn es una escena válida
const NPC_SCENE = preload("res://scenes/NPC.tscn")

func _ready():
	print("[DEBUG] World: _ready() INICIADO.")
	npc_container = get_node("NPCContainer")
	if not npc_container:
		print("-----> ¡ERROR CRÍTICO! World: No se encontró el nodo 'NPCContainer'. Verifique la estructura de la escena.")
		return
	print("[DEBUG] World: Nodo 'NPCContainer' encontrado.")

	data_loader = get_node("/root/MainScene/World_Node/DataLoader")
	if not data_loader:
		print("-----> ¡ERROR CRÍTICO! World: DataLoader no encontrado en el autoload.")
		return

	# Crear suelo de emergencia
	_create_emergency_floor()
	
	# Cargar mundos disponibles
	_load_world_list()

func _create_emergency_floor():
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(200, 1, 200)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	static_body.position = Vector3(0, -5, 0)
	static_body.collision_layer = 1
	add_child(static_body)
	print("[DEBUG] World: Suelo de emergencia creado en la capa de colisión 1.")

func _load_world_list():
	print("[DEBUG] World: _load_world_list() iniciado")
	
	data_loader = get_node_or_null("/root/MainScene/World_Node/DataLoader")
	
	if data_loader:
		print("[DEBUG] World: ✅ DataLoader encontrado, solicitando mundos...")
		# USAR EL MÉTODO CORRECTO QUE SÍ EXISTE
		data_loader.get_mundos_list(
			Callable(self, "_on_world_list_loaded"),
			Callable(self, "_on_world_list_failed")
		)
		print("[DEBUG] World: Solicitud de mundos enviada exitosamente.")
	else:
		print("-----> ¡ERROR CRÍTICO! World: DataLoader no encontrado.")

func _on_world_list_loaded(data, status_code):
	print(str("[DEBUG] World: _on_world_list_loaded() llamado. Estado: ", status_code, ", Datos recibidos (truncated): ", str(data).left(150), "..."))
	if status_code == 200 and data is Array and data.size() > 0:
		# BUSCAR ESPECÍFICAMENTE EL MUNDO CON ID 1 (SANDBOX)
		var sandbox_world = null
		for world in data:
			if world.get("id", 0) == 1:  # Buscar mundo con ID 1
				sandbox_world = world
				break
		
		if sandbox_world:
			selected_world_id = sandbox_world.get("id")
			print(str("[DEBUG] World: Cargando mundo ID: ", selected_world_id, ", Nombre: ", sandbox_world.get("nombre_mundo", "Sin nombre")))
			_generate_world_from_data(sandbox_world)
		else:
			print("-----> ¡ADVERTENCIA! World: No se encontró mundo con ID 1.")
	else:
		print(str("-----> ¡ERROR! World: Error al cargar mundos. Estado: ", status_code, ", Datos: ", str(data).left(150), "..."))

func _on_world_list_failed(_status_code, _error_data):
	print(str("-----> ¡ERROR! World: Solicitud de mundos falló. Estado: ", _status_code, ", Error: ", _error_data))

func _generate_world_from_data(world_data):
	print("[DEBUG] World: _generate_world_from_data() INICIADO.")
	
	# Limpiar NPCs existentes
	if npc_container:
		for child in npc_container.get_children():
			child.queue_free()
		print("[DEBUG] World: Limpiado npc_container de NPCs existentes.")
	
	# Generar terreno básico
	var seed_str = world_data.get("semilla_generacion", "SANDBOX_SEED_1")
	var size = world_data.get("estado_actual_terreno", {}).get("size", 50)
	print(str("[DEBUG] World: Generando terreno con semilla '", seed_str, "' y tamaño ", size))
	_generate_terrain(seed_str, {"terrain_size": size})
	print("[DEBUG] World: Generación de terreno completada.")
	
	# Solicitar NPCs para este mundo
	if selected_world_id != null:
		print(str("[DEBUG] World: Solicitando NPCs para mundo ID: ", selected_world_id))
		# USAR EL MÉTODO CORRECTO QUE SÍ EXISTE
		data_loader.get_instancias_npc_by_mundo(
			selected_world_id,
			Callable(self, "_on_instancias_npc_loaded"),
			Callable(self, "_on_instancias_npc_failed")
		)
		print("[DEBUG] World: Solicitud de NPCs enviada exitosamente.")
	else:
		print("-----> ¡ADVERTENCIA! World: No hay ID de mundo válido para solicitar NPCs.")
	print("[DEBUG] World: _generate_world_from_data() COMPLETADO.")

func _generate_terrain(p_seed: String, config: Dictionary):
	if not ground_container: return

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
	
	for x_idx in range(terrain_size):
		for z_idx in range(terrain_size):
			var noise_val = noise.get_noise_2d(float(x_idx), float(z_idx))
			var height = int(noise_val * terrain_height_scale) + base_height_offset
			for y_idx in range(height + 1):
				var static_body = StaticBody3D.new()
				static_body.collision_layer = 1
				var collision_shape = CollisionShape3D.new()
				collision_shape.shape = block_mesh.create_trimesh_shape()
				var mesh_instance = MeshInstance3D.new()
				mesh_instance.mesh = block_mesh
				mesh_instance.material_override = block_material
				static_body.add_child(mesh_instance)
				static_body.add_child(collision_shape)
				var pos = Vector3((x_idx * block_scale) - offset_x, y_idx * block_scale, (z_idx * block_scale) - offset_z)
				static_body.position = pos
				ground_container.add_child(static_body)

	print("[DEBUG] World: Generación de terreno completada.")
	
func _on_instancias_npc_loaded(data, status_code):
	print(str("[DEBUG] World: _on_instancias_npc_loaded() llamado. Estado: ", status_code))
	print(str("[DEBUG] World: DATOS COMPLETOS: ", JSON.stringify(data)))
	if status_code == 200 and data is Array: # Asegurarse de que 'data' sea un array
		_generate_npcs(data)
	else:
		print(str("-----> ¡ERROR! World: Falló la carga o la data no es un Array. Estado: ", status_code, ", Datos: ", str(data).left(150), "..."))

func _on_instancias_npc_failed(_status_code, _error_data):
	print(str("-----> ¡ERROR! World: Solicitud de instancias de NPC falló. Estado: ", _status_code, ", Error: ", _error_data))

func _generate_npcs(npcs_data: Array):
	print(str("[DEBUG] World: _generate_npcs() INICIADO. Total NPCs a procesar: ", npcs_data.size()))
	if not npc_container or not is_instance_valid(npc_container):
		print("-----> ¡ERROR CRÍTICO! World: npc_container es nulo o inválido. No se pueden añadir NPCs.")
		return

	# --- CORRECCIÓN DE LA VALIDACIÓN DE PackedScene ---
	if not NPC_SCENE: # Verifica si la precarga falló y el recurso es nulo
		print("-----> ¡ERROR CRÍTICO! World: NPC_SCENE es nulo. No se precargó correctamente. Ruta: ", preload("res://scenes/NPC.tscn").resource_path if preload("res://scenes/NPC.tscn") else "N/A")
		return
	
	# También verifica que es una PackedScene antes de intentar instanciar
	if not NPC_SCENE is PackedScene:
		print(str("-----> ¡ERROR CRÍTICO! World: NPC_SCENE no es una PackedScene. Tipo detectado: ", typeof(NPC_SCENE), ". Asegúrate que res://scenes/NPC.tscn es una escena guardada."))
		return
	# Fin de la corrección de PackedScene

	for npc_instance_data in npcs_data:
		var npc_id_from_data = npc_instance_data.get("id", "N/A")
		var tipo_npc_name_from_data = npc_instance_data.get("tipo_npc", {}).get("nombre", "Desconocido")
		print(str("[DEBUG] World: Procesando NPC instancia ID: ", npc_id_from_data, ", Tipo: ", tipo_npc_name_from_data, " en World.gd"))
		
		# DEBUGGING SEGURO - ESTRUCTURA COMPLETA DEL NPC
		print(str("[DEBUG] World: Datos completos NPC ID ", npc_id_from_data, ": ", JSON.stringify(npc_instance_data)))
		
		# DEBUGGING SEGURO - VERIFICAR TIPO_NPC ESPECÍFICO
		var tipo_npc_data = npc_instance_data.get("tipo_npc", {})
		print(str("[DEBUG] World: Tipo NPC completo: ", JSON.stringify(tipo_npc_data)))
		print(str("[DEBUG] World: Nombre extraído: '", tipo_npc_name_from_data, "'"))

		var npc_node = NPC_SCENE.instantiate()
		
		if not is_instance_valid(npc_node):
			print(str("-----> ¡ERROR CRÍTICO! World: La instanciación de NPC_SCENE falló para ID: ", npc_id_from_data, ". El nodo es inválido después de instanciar."))
			continue

		print(str("[DEBUG] World: NPC_NODE instanciado para ID: ", npc_id_from_data, ". Tipo de nodo: ", typeof(npc_node), ", Clase del nodo: ", npc_node.get_class()))
		
		if not npc_node.get_script():
			print(str("-----> ¡ERROR CRÍTICO! World: El nodo instanciado para NPC ID: ", npc_id_from_data, " NO TIENE UN SCRIPT ASIGNADO en su escena NPC.tscn. Por favor, abre NPC.tscn y asigna el script NPC.gd a su nodo raíz."))
		else:
			print(str("[DEBUG] World: Script detectado en nodo instanciado para NPC ID: ", npc_id_from_data, ": ", npc_node.get_script().resource_path))
			
		npc_container.add_child(npc_node)
		print(str("[DEBUG] World: NPC_NODE ID ", npc_id_from_data, " AÑADIDO como hijo de npc_container (Path: ", npc_container.get_path(), ")."))

		if npc_node.has_method("initialize_npc"):
			print(str("[DEBUG] World: Llamando initialize_npc con datos: ", JSON.stringify(npc_instance_data)))
			npc_node.initialize_npc(npc_instance_data)
			print(str("[DEBUG] World: Llamado initialize_npc() para NPC ID: ", npc_id_from_data, " en World.gd."))
		else:
			print(str("-----> ¡ERROR CRÍTICO! World: El nodo instanciado para NPC ID: ", npc_id_from_data, " NO TIENE EL MÉTODO 'initialize_npc'. Esto significa que el script NPC.gd no está correctamente asignado o no extiende CharacterBody3D."))
	print("[DEBUG] World: _generate_npcs() COMPLETADO.")
