extends Node2D

# バトルシーンのメインスクリプト
# 起動時に BattleManager から敵軍データを取得して初期化する

@onready var units_container

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
	# --- フロントユニット（Line1, 2）の処理 ---
	_draw_array(BattleContext.front_units,"Line1","Line2")
	_draw_array(BattleContext.back_units,"Line3","Line4")

func _draw_array(units: Array, line_a:String, line_b:String):
	var units_count = units.size()
	for i in range(2):
		var line_visible = false
		var line_string = line_a if i==0 else line_b

		for j in range(4):
			var current_index = (i * 4) + j
			var is_visible = current_index < units_count
			
			var slot = get_node("EnemyContainer/" + line_string + "/HBoxContainer/UnitSlot" + str(j+1))
			var image = slot.get_node("Image") # slotからの相対パスで書ける
			slot.visible = is_visible
			if is_visible:
				line_visible = true
				image.texture = _setup_unit_visual(units[current_index])

		get_node("EnemyContainer/" + line_string).visible = line_visible

func _setup_unit_visual(unit_data: Dictionary):
	var unit_id = unit_data.get("my_id")
	var data = UnitMaster.get_unit_data(unit_id)
	if data.is_empty(): return null # テクスチャがない場合はnullを返す
	
	# パスを組み立ててロード [cite: 4]
	var path = "res://assets/image/units/" + data["image_id"] + ".png"
	var texture = load(path)
	
	return texture

# 逃げる・勝利などでシーンを去る時の処理
func _exit_battle():
	# データをクリアしておく
	BattleManager.clear_battle_data()
	# マップシーンに戻るなどの処理
	# get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
