# res://scripts/components/InventoryComponent.gd
# VERSIÓN COMPLETA Y CORREGIDA - SISTEMA DE INVENTARIO
extends Node
class_name InventoryComponent

@export var debug_mode: bool = true

var entity_id: int = -1 # El ID de la entidad a la que pertenece (Player o NPC)
var entity_type: String # "Player" o "NPC"
var inventory_id: int = -1 # ID del inventario en la base de datos
var max_slots: int = 10
var max_weight_kg: float = 100.0
var items: Dictionary = {} # {"item_id": {"quantity": X, "item_data": {}}}
var current_weight: float = 0.0

# Referencia al DataLoader para sincronizar con la base de datos
var data_loader: DataLoader 

signal inventory_changed(new_items: Dictionary) # Emite el inventario actualizado
signal item_added(item_id: int, quantity: int)
signal item_removed(item_id: int, quantity: int)

func _ready():
	if debug_mode: print(str("[DEBUG] InventoryComponent: _ready() para ", entity_type, " ID: ", entity_id))
	data_loader = get_node_or_null("/root/MainScene/World_Node/DataLoader")
	if not data_loader:
		if debug_mode: print("-----> ¡ERROR! InventoryComponent: DataLoader no encontrado.")

func initialize_inventory(p_entity_id: int, p_entity_type: String, p_inventory_id: int, p_max_slots: int, p_max_weight_kg: float, p_items: Dictionary = {}):
	entity_id = p_entity_id
	entity_type = p_entity_type
	inventory_id = p_inventory_id
	max_slots = p_max_slots
	max_weight_kg = p_max_weight_kg
	items = p_items # El inventario inicial del backend

	_calculate_current_weight() # Calcular el peso inicial
	if debug_mode: print(str("[DEBUG] InventoryComponent: Inicializado para ", entity_type, " ID: ", entity_id, ". Slots: ", max_slots, ", Peso: ", current_weight, "/", max_weight_kg))
	emit_signal("inventory_changed", items)

# 🎒 FUNCIÓN MEJORADA: Soporte para múltiples formatos de entrada
func add_item(item_data_or_id, quantity_or_data = null, extra_data = {}):
	# Permitir múltiples formas de llamar la función:
	# 1. add_item(item_id: int, quantity: int, item_data: Dictionary)  [método original]
	# 2. add_item(item_data: Dictionary)  [método nuevo para pickup]
	
	var item_type_id: int
	var quantity: int 
	var item_data: Dictionary
	
	if typeof(item_data_or_id) == TYPE_DICTIONARY:
		# Nuevo formato: add_item(item_data: Dictionary)
		item_data = item_data_or_id
		item_type_id = item_data.get("tipo_objeto_id", -1)
		quantity = item_data.get("cantidad", 1)
		
		# Agregar datos faltantes para compatibilidad
		if not item_data.has("peso_unidad"):
			item_data["peso_unidad"] = 0.2  # Peso por defecto
		if not item_data.has("es_apilable"):
			item_data["es_apilable"] = true  # Por defecto apilable
	else:
		# Formato original: add_item(item_id: int, quantity: int, item_data: Dictionary)
		item_type_id = item_data_or_id
		quantity = quantity_or_data if quantity_or_data != null else 1
		item_data = extra_data

	# --- VALIDACIONES ---
	if quantity <= 0: 
		if debug_mode: print("[DEBUG] InventoryComponent: Cantidad inválida: ", quantity)
		return false
	
	if item_type_id <= 0:
		if debug_mode: print("[DEBUG] InventoryComponent: ID de objeto inválido: ", item_type_id)
		return false

	# Verificar peso
	var item_weight_unit = item_data.get("peso_unidad", 1.0)
	var total_add_weight = item_weight_unit * quantity

	if current_weight + total_add_weight > max_weight_kg:
		if debug_mode: print(str("[DEBUG] InventoryComponent: No hay suficiente capacidad de peso para añadir ", quantity, "x", item_type_id, " (peso: ", total_add_weight, ")"))
		return false

	# Verificar slots
	var is_stackable = item_data.get("es_apilable", false)
	var occupied_slots = _count_occupied_slots()

	if not is_stackable:
		if occupied_slots + quantity > max_slots:
			if debug_mode: print(str("[DEBUG] InventoryComponent: No hay suficientes slots para añadir ", quantity, "x", item_type_id))
			return false
	elif not items.has(item_type_id) and occupied_slots + 1 > max_slots:
		if debug_mode: print(str("[DEBUG] InventoryComponent: No hay suficientes slots para añadir nuevo tipo apilable ", item_type_id))
		return false

	# --- AGREGAR ITEM ---
	if items.has(item_type_id):
		items[item_type_id].quantity += quantity
	else:
		items[item_type_id] = {
			"quantity": quantity, 
			"item_data": item_data
		}

	_calculate_current_weight()
	if debug_mode: print(str("[DEBUG] InventoryComponent: ✅ Añadido ", quantity, "x ", item_data.get("nombre", "Item"), " (ID:", item_type_id, "). Peso actual: ", current_weight))
	
	emit_signal("item_added", item_type_id, quantity)
	emit_signal("inventory_changed", items)

	# TODO: Sincronizar con el backend si el inventario cambia
	return true

func remove_item(item_type_id: int, quantity: int):
	if quantity <= 0 or not items.has(item_type_id): 
		if debug_mode: print(str("[DEBUG] InventoryComponent: No se puede remover ", quantity, "x", item_type_id))
		return false

	var removed_quantity = min(quantity, items[item_type_id].quantity)
	items[item_type_id].quantity -= removed_quantity

	if items[item_type_id].quantity <= 0:
		items.erase(item_type_id)

	_calculate_current_weight()
	if debug_mode: print(str("[DEBUG] InventoryComponent: Removido ", removed_quantity, "x Item ", item_type_id, ". Peso actual: ", current_weight))
	
	emit_signal("item_removed", item_type_id, removed_quantity)
	emit_signal("inventory_changed", items)

	return true

func get_item_count(item_type_id: int):
	return items.get(item_type_id, {}).get("quantity", 0)

func has_item(item_type_id: int) -> bool:
	return items.has(item_type_id) and items[item_type_id].quantity > 0

func get_total_items() -> int:
	var total = 0
	for item_id in items:
		total += items[item_id].quantity
	return total

func get_free_slots() -> int:
	return max_slots - _count_occupied_slots()

func get_free_weight() -> float:
	return max_weight_kg - current_weight

# 📦 FUNCIÓN PARA UI: Obtener contenidos del inventario
func get_inventory_contents() -> Array:
	var contents = []
	
	for item_type_id in items:
		var item_entry = items[item_type_id]
		var item_data = item_entry.get("item_data", {})
		var quantity = item_entry.get("quantity", 1)
		
		contents.append({
			"id": item_type_id,
			"nombre": item_data.get("nombre", "Objeto Desconocido"),
			"descripcion": item_data.get("descripcion", "Sin descripción"),
			"cantidad": quantity,
			"peso_unidad": item_data.get("peso_unidad", 1.0),
			"tipo_objeto": item_data.get("tipo_objeto", "RECURSO"),
			"es_apilable": item_data.get("es_apilable", false),
			"peso_total": item_data.get("peso_unidad", 1.0) * quantity
		})
	
	# Ordenar por nombre para mejor presentación
	contents.sort_custom(func(a, b): return a["nombre"] < b["nombre"])
	
	return contents

# 🔍 FUNCIÓN PARA DEBUG: Mostrar estado del inventario
func print_inventory_status():
	print("=== INVENTARIO DEBUG ===")
	print(str("Entity: ", entity_type, " ID: ", entity_id))
	print(str("Slots: ", _count_occupied_slots(), "/", max_slots))
	print(str("Peso: ", current_weight, "/", max_weight_kg, " kg"))
	print("Items:")
	for item_id in items:
		var item = items[item_id]
		var item_data = item.item_data
		print(str("  - ", item_data.get("nombre", "Unknown"), " x", item.quantity, " (ID: ", item_id, ")"))
	print("========================")

# --- FUNCIONES PRIVADAS ---

func _calculate_current_weight():
	current_weight = 0.0
	for item_id in items:
		var item_data = items[item_id].item_data
		var quantity = items[item_id].quantity
		var item_weight_unit = item_data.get("peso_unidad", 1.0)
		current_weight += item_weight_unit * quantity

func _count_occupied_slots() -> int:
	var occupied_slots = 0
	for id in items:
		if items[id].get("item_data", {}).get("es_apilable", false):
			occupied_slots += 1 # Un slot por tipo de item apilable
		else:
			occupied_slots += items[id].quantity # Un slot por cada item no apilable
	return occupied_slots

# --- FUNCIONES DE CALLBACK PARA SINCRONIZACIÓN (TODO) ---

# func _on_inventory_sync_success(data, status_code):
#     if debug_mode: print(str("[DEBUG] InventoryComponent: Inventario sincronizado con éxito. Status: ", status_code))

# func _on_inventory_sync_failed(status_code, error_data):
#     if debug_mode: print(str("-----> ERROR! InventoryComponent: Falló la sincronización del inventario. Status: ", status_code, ", Error: ", error_data))
