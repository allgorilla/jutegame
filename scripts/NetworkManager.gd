# NetworkManager.gd
extends Node

const DB_URL = "https://jutegame-4ea50-default-rtdb.firebaseio.com/"
var http_request: HTTPRequest
var current_player_data: Dictionary = {}

# 通信状態を管理
enum State { 
	IDLE, 
	FETCHING_NEXT_ID, 
	REGISTERING_PLAYER, 
	UPDATING_NEXT_ID,
	FETCHING_PLAYER_DATA
}
var current_state = State.IDLE
var pending_char_name = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# NEW GAMEから呼ばれる入り口
func request_new_game(user_name: String):
	pending_char_name = user_name
	current_state = State.FETCHING_NEXT_ID
	
	# まずは次に使うべきIDを取得しにいく
	var url = DB_URL + "metadata/next_id.json"
	http_request.request(url, [], HTTPClient.METHOD_GET)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code != 200 and response_code != 201:
		print("通信エラー:", response_code)
		return

	var response_text = body.get_string_from_utf8()

	match current_state:
		State.FETCHING_NEXT_ID:
			var next_id = response_text.to_int()
			if next_id == 0: next_id = 1001
			_register_new_player(next_id)
			
		State.REGISTERING_PLAYER:
			print("1. プレイヤー登録完了。次にIDを更新します...")
			# ★重要: ここで登録したばかりのデータを current_player_data に入れておく
			# (これをしないと、MainMapへ行った時に名前などが表示されません)
			# ここでは request_new_game で渡された名前などの情報を変数に保持している前提です
			
			_update_next_id()
			
		State.UPDATING_NEXT_ID:
			print("★2. 全ての登録＆ID更新が完了しました！")
			current_state = State.IDLE
			# NEW GAMEフローの最後。ここで遷移！
			_change_to_main_map()

		State.FETCHING_PLAYER_DATA:
			var player_data = JSON.parse_string(response_text)
			if player_data:
				print("★データ読み込み成功！: ", player_data["name"])
				current_player_data = player_data
				current_state = State.IDLE
				# CONTINUEフローの最後。ここで遷移！
				_change_to_main_map()
			else:
				print("エラー：データが見つかりません")

# シーン遷移用の共通関数
func _change_to_main_map():
	# シーンのパスが正しいか確認してください
	get_tree().change_scene_to_file("res://scenes/MainMap.tscn")

func _update_next_id():
	current_state = State.UPDATING_NEXT_ID
	
	# ローカルファイルから現在のIDを読み取る
	var file = FileAccess.open("user://save_data.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	var next_val = int(json["my_id"]) + 1
	
	var url = DB_URL + "metadata/next_id.json"
	
	# 【重要】JSON.stringify() を使って、確実に「数値」としてシリアライズする
	var json_data = JSON.stringify(next_val) 
	
	# ヘッダーにContent-Typeを指定（念のため）
	var headers = ["Content-Type: application/json"]
	
	print("サーバーのnext_idを更新中... 値:", next_val)
	http_request.request(url, headers, HTTPClient.METHOD_PUT, json_data)

# 実際にIDを割り当てて登録する内部関数
func _register_new_player(new_id: int):
	current_state = State.REGISTERING_PLAYER
	
	# 1. プレイヤーデータの保存
	var player_url = DB_URL + "players/" + str(new_id) + ".json"
	var player_data = {
		"name": pending_char_name,
		"atk": 3, "int": 5, "cost": 10 # 初期ステータス
	}
	
	# ★自分の変数にも保存しておく
	current_player_data = player_data
	current_player_data["my_id"] = new_id
	
	http_request.request(player_url, [], HTTPClient.METHOD_PUT, JSON.stringify(player_data))
	
	# 2. 次のIDを更新（本来は別々に送るか、Firebaseの特殊命令を使います）
	var next_id_url = DB_URL + "metadata/next_id.json"
	var next_id_req = HTTPRequest.new() # 重複を避けるため別のノードで送信
	add_child(next_id_req)
	next_id_req.request(next_id_url, [], HTTPClient.METHOD_PUT, str(new_id + 1))
	
	# 3. ローカルにIDを保存
	_save_id_locally(new_id)

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

# NetworkManager.gd

# タイトル画面から呼ばれる：とりあえず手元でキャラを作るだけ
func setup_local_player(player_name: String):
	current_player_data = {
		"name": player_name,
		"atk": 10,
		"int": 10,
		"cost": 0
	}
	# IDはまだないので 0 か null にしておく
	current_player_data["my_id"] = 0
	
	# 一旦ローカルに保存（中途半端な状態で落としても名前を忘れないため）
	_save_id_locally(0) 
	
	# 通信を介さず即座にメインマップへ
	_change_to_main_map()

# 王様の「セーブ」から呼ばれるメイン関数
func save_player_data():
	if current_player_data.get("my_id", 0) == 0:
		# IDが0（未登録）なら、これまでの新規登録フローを開始
		print("新規登録を開始します...")
		request_new_game(current_player_data["name"])
	else:
		# すでにIDがあるなら、そのIDの場所を最新データで上書きする
		_overwrite_existing_player()

# 上書き保存用の関数
func _overwrite_existing_player():
	current_state = State.REGISTERING_PLAYER # 状態は「登録中」を流用
	
	var my_id = int(current_player_data["my_id"])
	var url = DB_URL + "players/" + str(my_id) + ".json"
	
	print("既存のデータを上書き中... ID:", my_id)
	
	# PUTメソッドで現在の current_player_data をそのまま送信
	var json_data = JSON.stringify(current_player_data)
	http_request.request(url, [], HTTPClient.METHOD_PUT, json_data)
