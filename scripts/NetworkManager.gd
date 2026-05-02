extends Node

const DB_URL = "https://jutegame-4ea50-default-rtdb.firebaseio.com/"
var http_request: HTTPRequest
var current_saving_data: Dictionary = {}

signal load_finished(success: bool)
signal all_save_finished

enum State { 
	IDLE, 
	FETCHING_NEXT_ID, 
	REGISTERING_DATA, 
	UPDATING_ID_COUNTER,
	FETCHING_PLAYER_DATA,
	INCREMENTING_COUNTER
}
var current_state = State.IDLE
var is_processing_new_registration = false

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	randomize()

# --- 公開メソッド ---

## 新規、または上書き保存の入り口
func save_character_data(data: Dictionary, path: String = "players"):
	if int(data.get("my_id", 0)) == 0:
		_start_new_registration_flow(data) 
	else:
		_overwrite_existing_data(data, path)

## ゲームデータのロード
func load_existing_game():
	var my_id = _get_local_saved_id()
	if my_id <= 0: return

	current_state = State.FETCHING_PLAYER_DATA
	var url = "%splayers/%d.json" % [DB_URL, my_id]
	http_request.request(url, [], HTTPClient.METHOD_GET)

# --- 内部フロー制御 ---

func _start_new_registration_flow(data: Dictionary):
	current_saving_data = data
	is_processing_new_registration = true
	current_state = State.FETCHING_NEXT_ID
	
	var url = DB_URL + "metadata/next_id.json"
	http_request.request(url, [], HTTPClient.METHOD_GET)

func _overwrite_existing_data(data: Dictionary, path: String):
	current_state = State.REGISTERING_DATA
	is_processing_new_registration = false
	
	# .0 問題を int() キャストで防ぎ、文字列フォーマットで安全にURL生成
	var url = "%s%s/%d.json" % [DB_URL, path, int(data["my_id"])] 
	http_request.request(url, [], HTTPClient.METHOD_PUT, JSON.stringify(data))

func _on_request_completed(_result, response_code, _headers, body):
	var response_text = body.get_string_from_utf8().strip_edges()
	
	if response_code >= 400:
		print("Firebase Error: ", response_text)
		load_finished.emit(false)
		return

	match current_state:
		State.FETCHING_NEXT_ID:
			var next_id = response_text.to_int()
			if response_text == "null" or next_id == 0:
				next_id = 1001
			_execute_registration(next_id)
			
		State.REGISTERING_DATA:
			if is_processing_new_registration:
				_increment_server_counter()
			else:
				_finalize_process()

		State.UPDATING_ID_COUNTER:
			if current_saving_data.get("is_pc", false):
				_save_id_locally(int(current_saving_data["my_id"]))
			_finalize_process()

		State.FETCHING_PLAYER_DATA:
			var player_data = JSON.parse_string(response_text)
			if player_data:
				Global.player_data = player_data
				_finalize_process()
			else:
				load_finished.emit(false)

		State.INCREMENTING_COUNTER:
			var next_val = response_text.to_int() + 1
			current_state = State.UPDATING_ID_COUNTER
			var url = DB_URL + "metadata/next_id.json"
			http_request.request(url, [], HTTPClient.METHOD_PUT, str(next_val))

# --- ヘルパー ---

func _execute_registration(new_id: int):
	current_state = State.REGISTERING_DATA
	current_saving_data["my_id"] = new_id
	var url = "%splayers/%d.json" % [DB_URL, new_id]
	http_request.request(url, [], HTTPClient.METHOD_PUT, JSON.stringify(current_saving_data))

func _increment_server_counter():
	current_state = State.INCREMENTING_COUNTER
	var url = DB_URL + "metadata/next_id.json"
	http_request.request(url, [], HTTPClient.METHOD_GET)

func _finalize_process():
	current_state = State.IDLE
	is_processing_new_registration = false
	load_finished.emit(true)
	all_save_finished.emit()


func _save_id_locally(id_val: int):
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"my_id": id_val}))
	file.close()

func _get_local_saved_id() -> int:
	if not FileAccess.file_exists("user://save_data.json"): return 0
	var file = FileAccess.open("user://save_data.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	return int(json.get("my_id", 0)) if json else 0
