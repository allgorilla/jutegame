extends Node
var last_player_pos = Vector2(0, 0) # 最後にいた座標を保存する

# プレイヤーの全データを辞書で持つのが拡張しやすくて便利です
var player_data = {
	"name": "",
	"atk": 0,
	"int": 0,
	"gold": 0,
	"soldiers": []
}

# サーバー/ローカルからロードしたデータを反映する関数
func sync_player_data(data: Dictionary):
	player_data = data
