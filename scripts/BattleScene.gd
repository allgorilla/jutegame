extends Node2D

# バトルシーンのメインスクリプト
# 起動時に BattleManager から敵軍データを取得して初期化する

func _ready():
	await SceneManager.fade_in_scene()
	
	# BattleManager (Autoload) からデータを取得
	var battle_data = BattleManager.next_battle_data
	
	if battle_data.is_empty():
		print("警告: 戦闘データが見つかりません。テスト用デフォルトで起動します。")
		# デバッグ用に何かデフォルトを入れる場合はここに記述
		return

	_initialize_battle(battle_data)

# 受け取ったデータに基づいてシーンを構築
func _initialize_battle(data: Dictionary):
	print("--- バトル開始 ---")
	print("敵軍名: ", data.party_name)
	
	# 各ユニットの配置
	for unit in data.unit_list:
		var unit_name = unit.name
		var pos_data = unit.position # {"row": "front/back", "index": 0~3}
		
		print("ユニット配置: ", unit_name, " 位置: ", pos_data)
		_spawn_enemy_unit(unit, pos_data)

# ユニットのスプライト等を生成して配置する処理（仮）
func _spawn_enemy_unit(unit_stats: Dictionary, pos_info: Dictionary):
	# TODO: ここで敵のスプライト（キャラチップや立ち絵）をインスタンス化
	# 座標計算の例:
	# var x = 800 if pos_info.row == "front" else 1000
	# var y = 200 + (pos_info.index * 100)
	pass

# 逃げる・勝利などでシーンを去る時の処理
func _exit_battle():
	# データをクリアしておく
	BattleManager.clear_battle_data()
	# マップシーンに戻るなどの処理
	# get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
