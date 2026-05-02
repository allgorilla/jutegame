# NetworkManager.gd
extends Node

const DB_URL = "https://jutegame-4ea50-default-rtdb.firebaseio.com/"
var http_request: HTTPRequest
var current_saving_data: Dictionary = {}
signal load_finished(success: bool)

# 通信状態を管理
enum State { 
	IDLE, 
	FETCHING_NEXT_ID, 
	REGISTERING_PLAYER, 
	UPDATING_NEXT_ID,
	FETCHING_PLAYER_DATA,
	FETCHING_NEXT_ID_FOR_INCREMENT
}
var current_state = State.IDLE
var is_processing_new_registration = false

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	randomize()

func _request_new_game(data: Dictionary):
	current_saving_data = data
	# 新規登録フロー開始のフラグを立てる
	is_processing_new_registration = true
	current_state = State.FETCHING_NEXT_ID
	
	var url = DB_URL + "metadata/next_id.json"
	http_request.request(url, [], HTTPClient.METHOD_GET)
	
func _on_request_completed(_result, response_code, _headers, body):

	var response_text = body.get_string_from_utf8()
	if response_code == 400:
		print("--- Firebaseエラー詳細 ---")
		print(response_text)
		print("-------------------------")
		return

	match current_state:
		State.FETCHING_NEXT_ID:
			var next_id = response_text.to_int()
			if next_id == 0: next_id = 1001
			_register_new_player(next_id)
			
		State.REGISTERING_PLAYER:
			if is_processing_new_registration:
				print("新規登録成功。サーバーのIDカウンターを更新します。")
				_update_next_id_on_server()
			else:
				print("既存データの上書き完了。")
				current_state = State.IDLE

		State.UPDATING_NEXT_ID:
			# ここで初めて is_pc を確認する
			# 自分が操作するメインキャラ(PC)の時だけローカルにIDを刻む
			if current_saving_data.get("is_pc", false):
				var final_id = int(current_saving_data["my_id"])
				_save_id_locally(final_id)
				print("プレイヤーPCの登録とローカル保存が完了しました")
			else:
				print("NPCキャラの世界リスト登録が完了しました")
			
			is_processing_new_registration = false # フラグを戻す
			current_state = State.IDLE
			load_finished.emit(true)

		State.FETCHING_PLAYER_DATA:
			var player_data = JSON.parse_string(response_text)
			if player_data:
				Global.player_data = player_data
				current_state = State.IDLE
				load_finished.emit(true)
			else:
				load_finished.emit(false)

		State.FETCHING_NEXT_ID_FOR_INCREMENT:
			var current_id = response_text.to_int()
			var next_val = current_id + 1
			
			current_state = State.UPDATING_NEXT_ID
			var url = DB_URL + "metadata/next_id.json"
			var headers = ["Content-Type: application/json"]
			http_request.request(url, headers, HTTPClient.METHOD_PUT, JSON.stringify(next_val))

# ID更新だけを担当する関数
func _update_next_id_on_server():
	# 状態を ID取得 に一時的に戻して、最新の next_id を取りに行く
	current_state = State.FETCHING_NEXT_ID_FOR_INCREMENT
	var url = DB_URL + "metadata/next_id.json"
	http_request.request(url, [], HTTPClient.METHOD_GET)

# 実際にIDを割り当てて登録する内部関数

func _register_new_player(new_id: int):
	current_state = State.REGISTERING_PLAYER

	current_saving_data["my_id"] = new_id

	# もし「自分自身」の登録なら、Globalにも反映しておく
	if current_saving_data.get("is_pc", false): # 判定用のフラグがあると便利です
		Global.player_data["my_id"] = new_id

	var player_url = DB_URL + "players/" + str(new_id) + ".json"
	var json_data = JSON.stringify(current_saving_data)
	
	http_request.request(player_url, [], HTTPClient.METHOD_PUT, json_data)

func _save_id_locally(id_val: int):
	var data = {"my_id": id_val}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

# CONTINUEから呼ばれる関数
func load_existing_game():
	if not FileAccess.file_exists("user://save_data.json"):
		print("エラー：ローカルセーブが見つかりません")
		return
	
	# ローカルから自分のIDを読み取る
	var file = FileAccess.open("user://save_data.json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.parse_string(content)
	if json == null or not json.has("my_id"):
		print("エラー：セーブデータの中身が不正です:", content)
		return

	var my_id = int(json["my_id"])
	
	# ★重要：ここでのURL組み立てをチェック
	# URLの末尾に .json が漏れていたり、スラッシュが重複していないか確認
	var url = DB_URL + "players/" + str(my_id) + ".json"
	
	print("--- CONTINUEリクエスト送信 ---")
	print("読み込んだID:", my_id)
	print("生成されたURL:", url)
	print("----------------------------")
	
	current_state = State.FETCHING_PLAYER_DATA
	
	# リクエスト送信
	var err = http_request.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		print("HTTPRequestを開始できませんでした。エラーコード:", err)

func save_character_data(data: Dictionary, path: String = "players"):
	if data.get("my_id", 0) == 0:
		# IDがない場合はデータごと渡す
		_request_new_game(data) 
	else:
		_overwrite_existing_data(data, path)


# 上書き保存用の関数
func _overwrite_existing_data(data: Dictionary, path: String):
	current_state = State.REGISTERING_PLAYER
	var char_id = data["my_id"]
	var url = DB_URL + path + "/" + str(char_id) + ".json"
	
	var json_data = JSON.stringify(data)
	http_request.request(url, [], HTTPClient.METHOD_PUT, json_data)
