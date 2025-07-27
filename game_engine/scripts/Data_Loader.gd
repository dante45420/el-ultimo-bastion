# el-ultimo-bastion/game_engine/scripts/Data_Loader.gd
# VERSIÓN REVISADA CON CALLBACKS ESPECÍFICOS POR SOLICITUD
extends Node
class_name DataLoader

var http_request_node: HTTPRequest
var api_base_url: String = "http://127.0.0.1:5000/api/v1/admin"

var request_queue: Array = []
var is_processing_queue: bool = false
var current_request_callback_success: Callable # Callback para la solicitud actual
var current_request_callback_failed: Callable # Callback para la solicitud actual

# Ya no necesitamos señales genéricas si usamos Callables
# signal request_completed_success(data, status_code)
# signal request_failed(status_code, error_data)

func _ready():
	print("[DEBUG] DataLoader: _ready() INICIADO. (NUEVA VERSIÓN CON CALLBACKS)")
	http_request_node = HTTPRequest.new()
	add_child(http_request_node)
	http_request_node.request_completed.connect(self._on_request_completed)
	print("[DEBUG] DataLoader: Nodo HTTPRequest creado y señal conectada.")

# El método _make_request ahora acepta Callables para éxito y fallo
func _make_request(method: String, endpoint: String, body: Dictionary = {}, headers: PackedStringArray = [], 
				   on_success: Callable = Callable(), on_failed: Callable = Callable()):
	var request_details = {
		"method": method, "endpoint": endpoint,
		"body": body, "headers": headers,
		"on_success": on_success,
		"on_failed": on_failed
	}
	print(str("[DEBUG] DataLoader: Encolando nueva solicitud: ", method, " a ", endpoint))
	request_queue.append(request_details)
	_process_next_in_queue()

func _process_next_in_queue():
	if is_processing_queue or request_queue.is_empty():
		return

	is_processing_queue = true
	var next_request = request_queue.pop_front()

	# Guardamos los callbacks para la solicitud que estamos procesando
	current_request_callback_success = next_request.on_success
	current_request_callback_failed = next_request.on_failed

	var url = api_base_url + next_request.endpoint
	var full_headers = PackedStringArray(["Content-Type: application/json"]) + next_request.headers
	var request_body_str = JSON.stringify(next_request.body) if not next_request.body.is_empty() else ""

	var http_method = HTTPClient.METHOD_GET
	match next_request.method.to_upper():
		"POST": http_method = HTTPClient.METHOD_POST
		"PUT": http_method = HTTPClient.METHOD_PUT
		"DELETE": http_method = HTTPClient.METHOD_DELETE

	print(str("[DEBUG] DataLoader: PROCESANDO solicitud a URL: ", url))
	var error = http_request_node.request(url, full_headers, http_method, request_body_str)

	if error != OK:
		print(str("-----> ¡ERROR CRÍTICO! DataLoader: La función .request() falló inmediatamente con el código de error: ", error, ". Esto suele significar que la URL es inalcanzable o hay un problema de red/firewall."))
		is_processing_queue = false
		# Llamamos al callback de fallo si está disponible
		if current_request_callback_failed.is_valid():
			current_request_callback_failed.call(0, {"error": "Request failed immediately: " + str(error)})
		_process_next_in_queue()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	print(str("[DEBUG] DataLoader: _on_request_completed disparado. Resultado: ", result, ", Código de Respuesta: ", response_code))

	if result != HTTPRequest.RESULT_SUCCESS:
		print(str("-----> ¡ERROR CRÍTICO! DataLoader: El resultado de la solicitud NO FUE EXITOSO. Código de resultado: ", result, ". Esto indica un problema de red fundamental (DNS, conexión rechazada, timeout)."))
		if current_request_callback_failed.is_valid():
			current_request_callback_failed.call(0, {"error": "Request failed with result code: " + str(result)})
		is_processing_queue = false
		_process_next_in_queue()
		return

	var response_text = body.get_string_from_utf8()
	var response_json = JSON.parse_string(response_text)

	print(str("[DEBUG] DataLoader: Respuesta recibida del servidor (código ", response_code, "): ", response_text.left(150), "...")) # Truncar para no llenar la consola

	if response_code >= 200 and response_code < 300:
		print("[DEBUG] DataLoader: La solicitud fue exitosa. Llamando a callback de éxito.")
		if current_request_callback_success.is_valid():
			current_request_callback_success.call(response_json, response_code)
	else:
		print(str("-----> ¡ERROR! DataLoader: El servidor devolvió un código de error: ", response_code, ". Llamando a callback de fallo."))
		if current_request_callback_failed.is_valid():
			current_request_callback_failed.call(response_code, response_json)

	is_processing_queue = false
	_process_next_in_queue()

# Los métodos públicos ahora aceptan los Callables
func get_mundos_list(on_success: Callable, on_failed: Callable):
	_make_request("GET", "/mundos", {}, [], on_success, on_failed)

func get_instancias_npc_by_mundo(mundo_id: int, on_success: Callable, on_failed: Callable):
	_make_request("GET", "/instancias_npc_by_mundo/" + str(mundo_id), {}, [], on_success, on_failed)

func get_bastion_by_user_id(user_id: int, on_success: Callable, on_failed: Callable):
	_make_request("GET", "/bastiones_by_user/" + str(user_id), {}, [], on_success, on_failed)

func update_bastion_game_state(bastion_id: int, game_state_data: Dictionary, on_success: Callable = Callable(), on_failed: Callable = Callable()):
	_make_request("PUT", "/bastiones/" + str(bastion_id) + "/sync_game_state", game_state_data, [], on_success, on_failed)
