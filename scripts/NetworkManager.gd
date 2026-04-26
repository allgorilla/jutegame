# NetworkManager.gd
extends Node

const DB_URL = "https://jutegame-4ea50-default-rtdb.firebaseio.com/"
var http_request: HTTPRequest

# 通信状態を管理
enum State { 
	IDLE, 
	FETCHING_NEXT_ID, 
	REGISTERING_PLAYER, 
	UPDATING_NEXT_ID,
	FETCHING_PLAYER_DATA  # ← これを追記
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
			var next_id = body.get_string_from_utf8().to_int()
			if next_id == 0: next_id = 1001
			_register_new_player(next_id)
			
		State.REGISTERING_PLAYER:
			print("1. プレイヤー登録完了。次にIDを更新します...")
			# ここで次のIDを保存している変数を参照して更新処理へ
			_update_next_id()
			
		State.UPDATING_NEXT_ID:
			print("★2. 全ての登録＆ID更新が完了しました！")
			current_state = State.IDLE

		State.FETCHING_PLAYER_DATA:
			var player_data = JSON.parse_string(response_text)
			if player_data:
				print("★おかえりなさい、", player_data["name"], "さん！")
				print("ステータス: ATK", player_data["atk"], " / INT", player_data["int"])
				# ここで MainMap へシーン遷移させる処理を入れる
			else:
				print("エラー：サーバーにデータが存在しません")


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
		"atk": 10, "int": 10, "cost": 0 # 初期ステータス
	}
	http_request.request(player_url, [], HTTPClient.METHOD_PUT, JSON.stringify(player_data))
	
	# 2. 次のIDを更新（本来は別々に送るか、Firebaseの特殊命令を使います）
	var next_id_url = DB_URL + "metadata/next_id.json"
	var next_id_req = HTTPRequest.new() # 重複を避けるため別のノードで送信
	add_child(next_id_req)
	next_id_req.request(next_id_url, [], HTTPClient.METHOD_PUT, str(new_id + 1))
	
	# 3. ローカルにIDを保存
	_save_id_locally(new_id)

func _save_id_locally(my_id: int):
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	var data = {"my_id": my_id}
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
