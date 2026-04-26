extends Node

# FirebaseのURL（末尾の /players/ までは共通）
const BASE_URL = "https://jutegame-4ea50-default-rtdb.firebaseio.com/players/"

# 通信用のノードを動的に作成
var http_request: HTTPRequest

func _ready():
	# HTTPRequestノードを自分自身に追加
	http_request = HTTPRequest.new()
	add_child(http_request)
	# 通信が終わった時に呼ばれる関数を接続
	http_request.request_completed.connect(_on_request_completed)

# セーブ実行関数（王様のセーブ処理からこれを呼ぶ）
func save_player_data(char_name: String, cost: int, atk: int, intell: int, pw: String):
	# URLを組み立て（名前.json にするのがFirebaseのルール）
	var url = BASE_URL + char_name.uri_encode() + ".json"
	
	# 送信するデータを辞書形式で作成
	var data = {
		"password": pw,
		"cost": cost,
		"atk": atk,
		"int": intell
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	print("サーバーへ送信中...: ", char_name)
	# PUTメソッドでデータを送信（上書き保存）
	http_request.request(url, headers, HTTPClient.METHOD_PUT, json_data)

# 通信結果の受け取り
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("★サーバー保存に成功しました！")
	else:
		var response = body.get_string_from_utf8()
		print("エラー発生！ コード:", response_code, " 内容:", response)
