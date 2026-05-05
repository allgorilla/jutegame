extends Node
var last_player_pos = Vector2(0, 0) # 最後にいた座標を保存する

# プレイヤーの全データを辞書で持つのが拡張しやすくて便利です
var player_data = {} #
var world_list = {} # IDをキーにした辞書
var party_list = [null, null, null, null, null, null, null, null] #

# FirebaseのURL
const FIREBASE_URL = "https://jutegame-4ea50-default-rtdb.firebaseio.com/players.json"

# サーバー/ローカルからロードしたデータを反映する関数
func sync_player_data(data: Dictionary):
	player_data = data

func fetch_world_list():
	# HTTPRequestノードを動的に作成
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# リクエスト送信
	var error = http_request.request(FIREBASE_URL)
	if error != OK:
		push_error("HTTPリクエストの開始に失敗しました")
		http_request.queue_free()
		return

	# 結果を待機（シグナルをawaitで受け取る）
	var result = await http_request.request_completed
	
	# 完了後にノードを削除
	http_request.queue_free()

	# レスポンスの解析 (result[1] はレスポンスコード, result[3] はボディデータ)
	if result[1] == 200:
		var json = JSON.new()
		var parse_err = json.parse(result[3].get_string_from_utf8())
		if parse_err == OK:
			# world_list を受信したデータ（IDがキーの辞書）で上書き
			world_list = json.get_data()
			print("世界リストを取得しました: ", world_list.size(), "件")
		else:
			print("JSON解析エラー")
	else:
		print("通信エラー: ", result[1])
