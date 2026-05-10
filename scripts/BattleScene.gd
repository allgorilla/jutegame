extends Node2D

# バトルシーンのメインスクリプト
# 起動時に BattleManager から敵軍データを取得して初期化する

@onready var units_container

func _ready():
	# 1. まずデータを取得する
	var battle_data = BattleManager.next_battle_data
	
	# 2. 画面が暗いうちに初期化（ロード）を走らせる 
	if not battle_data.is_empty():
		_initialize_battle(battle_data)
	else:
		print("警告: 戦闘データが見つかりません。")
		return

	# 3. ロードが完了し、ノードが準備できてからフェードインを開始する
	await SceneManager.fade_in_scene()


# 受け取ったデータに基づいてシーンを構築
func _initialize_battle(data: Dictionary):
	# プレイヤー側
	_draw_array(BattleContext.player_party.front_units,"PlayerContainer", "Line1", "Line2")
	_draw_array(BattleContext.player_party.back_units,"PlayerContainer", "Line3", "Line4")
	# エネミー側
	_draw_array(BattleContext.enemy_party.front_units,"EnemyContainer", "Line1", "Line2")
	_draw_array(BattleContext.enemy_party.back_units,"EnemyContainer", "Line3", "Line4")

func _draw_array(units: Array, container:String, line_a:String, line_b:String):
	var units_count = units.size()
	for i in range(2):
		var line_visible = false
		var line_string = line_a if i==0 else line_b

		for j in range(4):
			var current_index = (i * 4) + j
			var is_visible = current_index < units_count
			
			var slot = get_node(container + "/" + line_string + "/HBoxContainer/UnitSlot" + str(j+1))
			var image = slot.get_node("Image") # TextureRect または Sprite2D
			
			slot.visible = is_visible
			if is_visible:
				line_visible = true
				image.texture = _setup_unit_visual(units[current_index])
				
				# 1. エネミー側なら画像を左右反転（Hフリップ）
				if container == "EnemyContainer":
					if "flip_h" in image: # Sprite2Dの場合
						image.flip_h = true
					elif image is TextureRect: # TextureRectの場合
						# TextureRectはプロパティがないので、ScaleのXを-1にして反転させる
						# 中央基準で反転させるため、PivotOffsetを中央にする必要がある
						image.pivot_offset = image.size / 2
						image.scale.x = -1
				else:
					# プレイヤー側は反転を戻す（念のため）
					if "flip_h" in image: image.flip_h = false
					elif image is TextureRect: image.scale.x = 1

				# 2. 後列（Line3, Line4）なら透明度を50%に
				# string.match を使って、行の名前に "Line3" か "Line4" が含まれるか判定
				if line_string.match("Line3") or line_string.match("Line4"):
					image.modulate = Color(0.5, 0.5, 0.75, 1) if container == "PlayerContainer" else Color(0.75, 0.5, 0.5, 1)
				else:
					image.modulate = Color(0.75, 0.75, 1, 1) if container == "PlayerContainer" else Color(1, 0.75, 0.75, 1)

				# ----------------------

		get_node(container + "/" + line_string).visible = line_visible

func _setup_unit_visual(unit_data: Dictionary):
	var unit_id = unit_data.get("my_id")
	var data = UnitMaster.get_unit_data(unit_id)
	if data.is_empty(): return null # テクスチャがない場合はnullを返す
	
	# パスを組み立ててロード
	var path = "res://assets/image/units/" + data["image_id"] + ".png"
	var texture = load(path)
	
	return texture

# 逃げる・勝利などでシーンを去る時の処理
func _exit_battle():
	# データをクリアしておく
	BattleManager.clear_battle_data()
	# マップシーンに戻るなどの処理
	# get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
