extends Node

# 戦闘シーンに引き継ぐデータを保持する変数
# マップシーンでセットされ、バトルシーンの初期化時に参照される
var next_battle_data: Dictionary = {}

# データをクリアする関数（戦闘終了時などに呼び出す）
func clear_battle_data():
	next_battle_data = {}
