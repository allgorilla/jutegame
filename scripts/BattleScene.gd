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
	var front_count = BattleContext.front_units.size()
	for i in range(1, 3): # Line 1, 2
		var line_visible = false
		for j in range(1, 5): # Slot 1, 2, 3, 4
			var current_index = (i - 1) * 4 + j
			var is_visible = current_index <= front_count
			
			var slot_node = "EnemyContainer/Line" + str(i) + "/HBoxContainer/UnitSlot" + str(j)
			var slot = get_node(slot_node)
			var image = get_node(slot_node + "/Image")
			slot.visible = is_visible
			if is_visible:
				line_visible = true
				image.texture = _setup_unit_visual(current_index-1)

		get_node("EnemyContainer/Line" + str(i)).visible = line_visible

	# --- バックユニット（Line3, 4）の処理 ---
	var back_count = BattleContext.back_units.size()
	for i in range(3, 5): # Line 3, 4
		var line_visible = false
		for j in range(1, 5): # Slot 1, 2, 3, 4
			# Line3のSlot1を「1番目」としてカウントするための計算
			var current_index = (i - 3) * 4 + j
			var is_visible = current_index <= back_count
			
			var slot = get_node("EnemyContainer/Line" + str(i) + "/HBoxContainer/UnitSlot" + str(j))
			slot.visible = is_visible
			if is_visible: line_visible = true
			
		get_node("EnemyContainer/Line" + str(i)).visible = line_visible


func _setup_unit_visual(index: int):
	var unit_data = BattleContext.front_units[index]
	var unit_id = unit_data.get("my_id")
	var data = UnitMaster.get_unit_data(unit_id)
	if data.is_empty(): return
	
	# "res://path/to/assets/01.png" のようなパスを組み立てる
	var path = "res://assets/image/units/" + data["image_id"] + ".png"
	var texture = load(path)
	
	return texture

# 逃げる・勝利などでシーンを去る時の処理
func _exit_battle():
	# データをクリアしておく
	BattleManager.clear_battle_data()
	# マップシーンに戻るなどの処理
	# get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
