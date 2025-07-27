# res://components/InventoryComponent.gd
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

func add_item(item_type_id: int, quantity: int, item_data: Dictionary = {}):
	if quantity <= 0: return false

	# Simulación de obtener peso de la base de datos (idealmente vendría de TipoObjeto)
	var item_weight_unit = item_data.get("peso_unidad", 1.0) # Obtener peso_unidad del item_data
	var total_add_weight = item_weight_unit * quantity

	if current_weight + total_add_weight > max_weight_kg:
		if debug_mode: print(str("[DEBUG] InventoryComponent: No hay suficiente capacidad de peso para añadir ", quantity, "x", item_type_id))
		return false

	# Si el item es apilable, solo actualiza la cantidad. Si no, ocupa un slot nuevo por cada item
	var is_stackable = item_data.get("es_apilable", false)

	# Contar slots ocupados actualmente
	var occupied_slots = 0
	for id in items:
		if items[id].get("item_data", {}).get("es_apilable", false):
			occupied_slots += 1 # Un slot por tipo de item apilable
		else:
			occupied_slots += items[id].quantity # Un slot por cada item no apilable

	if not is_stackable:
		if occupied_slots + quantity > max_slots:
			if debug_mode: print(str("[DEBUG] InventoryComponent: No hay suficientes slots para añadir ", quantity, "x", item_type_id))
			return false
	elif not items.has(item_type_id) and occupied_slots + 1 > max_slots:
		if debug_mode: print(str("[DEBUG] InventoryComponent: No hay suficientes slots para añadir ", quantity, "x", item_type_id, " (nuevo tipo apilable)."))
		return false

	if items.has(item_type_id):
		items[item_type_id].quantity += quantity
	else:
		items[item_type_id] = {"quantity": quantity, "item_data": item_data} # Guardar también el data del item

	_calculate_current_weight()
	if debug_mode: print(str("[DEBUG] InventoryComponent: Añadido ", quantity, "x Item ", item_type_id, ". Peso actual: ", current_weight))
	emit_signal("item_added", item_type_id, quantity)
	emit_signal("inventory_changed", items)

	# TODO: Sincronizar con el backend si el inventario cambia
	# if data_loader and entity_type == "Bastion": # Solo sincronizamos inventario del Bastion por ahora
	#     data_loader.update_bastion_inventory(inventory_id, items, Callable(self, "_on_inventory_sync_success"), Callable(self, "_on_inventory_sync_failed"))
	return true

func remove_item(item_type_id: int, quantity: int):
	if quantity <= 0 or not items.has(item_type_id): return false

	var removed_quantity = min(quantity, items[item_type_id].quantity)
	items[item_type_id].quantity -= removed_quantity

	if items[item_type_id].quantity <= 0:
		items.erase(item_type_id)

	_calculate_current_weight()
	if debug_mode: print(str("[DEBUG] InventoryComponent: Removido ", removed_quantity, "x Item ", item_type_id, ". Peso actual: ", current_weight))
	emit_signal("item_removed", item_type_id, removed_quantity)
	emit_signal("inventory_changed", items)

	# TODO: Sincronizar con el backend
	return true

func get_item_count(item_type_id: int):
	return items.get(item_type_id, {}).get("quantity", 0)

func _calculate_current_weight():
	current_weight = 0.0
	for item_id in items:
		var item_data = items[item_id].item_data
		var quantity = items[item_id].quantity
		var item_weight_unit = item_data.get("peso_unidad", 1.0)
		current_weight += item_weight_unit * quantity

# TODO: Funciones de callback para sincronización con DB
# func _on_inventory_sync_success(data, status_code):
#     if debug_mode: print(str("[DEBUG] InventoryComponent: Inventario sincronizado con éxito. Status: ", status_code))
# func _on_inventory_sync_failed(status_code, error_data):
#     if debug_mode: print(str("-----> ERROR! InventoryComponent: Falló la sincronización del inventario. Status: ", status_code, ", Error: ", error_data))
