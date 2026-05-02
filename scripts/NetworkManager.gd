# NetworkManager.gd
extends Node

const DB_URL = "https://jutegame-4ea50-default-rtdb.firebaseio.com/"
var http_request: HTTPRequest
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
var pending_char_name = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	randomize()

# NEW GAMEから呼ばれる入り口
func request_new_game(user_name: String):
	pending_char_name = user_name
	current_state = State.FETCHING_NEXT_ID
	
	# まずは次に使うべきIDを取得しにいく
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
			# 登録中（REGISTERING_PLAYER）が終わった際の挙動
			if pending_char_name != "":
				# 名前がセットされている = 新規登録フローの途中
				print("新規プレイヤー登録成功。IDを加算します。")
				pending_char_name = "" # フラグをクリア
				_update_next_id_on_server()
			else:
				# 名前がない = 既存データの上書き保存完了
				print("プレイヤーデータの上書き保存に成功しました。")
				current_state = State.IDLE
			# 必要に応じて load_finished シグナルを流用、
			# または新しく save_finished(true) を定義して emit

		State.UPDATING_NEXT_ID:
			# ID更新も成功したら、最後にローカル保存して終了
			var final_id = int(Global.player_data["my_id"])
			_save_id_locally(final_id)
			print("全ての登録プロセスが完了しました")
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
	
	# 自分の変数にIDを反映し、最新の状態をセット
	Global.player_data["my_id"] = new_id
	# ※pending_char_name などは setup_local_player 時点で 
	# Global.player_data["name"] に入っている前提です。

	# 1. まずはプレイヤーデータを保存
	var player_url = DB_URL + "players/" + str(new_id) + ".json"
	var json_data = JSON.stringify(Global.player_data)
	
	# 既存の http_request を使い回す（完了後に次の通信へ飛ばす）
	http_request.request(player_url, [], HTTPClient.METHOD_PUT, json_data)
	
	# ★ ここで ID更新リクエストを同時に送らず、
	# _on_request_completed の REGISTERING_PLAYER 終了時に次を送るようにします。

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

# 王様の「セーブ」から呼ばれるメイン関数
func save_player_data():
	if Global.player_data.get("my_id", 0) == 0:
		# IDが0（未登録）なら、これまでの新規登録フローを開始
		print("新規登録を開始します...")
		request_new_game(Global.player_data["name"])
	else:
		# すでにIDがあるなら、そのIDの場所を最新データで上書きする
		_overwrite_existing_player()

# 上書き保存用の関数
func _overwrite_existing_player():
	current_state = State.REGISTERING_PLAYER # 状態は「登録中」を流用
	
	var my_id = int(Global.player_data["my_id"])
	var url = DB_URL + "players/" + str(my_id) + ".json"
	
	print("既存のデータを上書き中... ID:", my_id)
	
	# PUTメソッドで現在の Global.player_data をそのまま送信
	var json_data = JSON.stringify(Global.player_data)
	http_request.request(url, [], HTTPClient.METHOD_PUT, json_data)
