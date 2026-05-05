extends CanvasLayer
signal closed

const CHARACTER_SLOT_SCENE = preload("res://scenes/CharacterSlot.tscn")

@onready var main_content = $MainContent
@onready var v_box = $MainContent/ScrollContainer/VBoxContainer
@onready var cost_label = $MainContent/CostArea/CostLabel

# 編集中のパーティを保持する一時的な配列
var temp_party_list = []

func _ready():
	# 1. アニメーション処理
	main_content.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(main_content, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# 2. ★ここでデータを最新にする（Globalに任せる）
	await Global.fetch_world_list()
	# 起動時に Global の現在のパーティをコピーする
	temp_party_list = Global.party_list.duplicate()
	# 3. 準備ができてからスロットを生成する
	setup_party_list()
	update_total_cost()

func setup_party_list():
	# 既存のスロットをクリア（再描画時用）
	for child in v_box.get_children():
		child.queue_free()
	
	# Globalの最新データを元に8個生成
	for i in range(8):
		var slot = CHARACTER_SLOT_SCENE.instantiate()
		v_box.add_child(slot)
	
		slot.slot_index = i # 何番目かを教える
		
		# ★重要：スロットのシグナルを、親の関数に接続する
		slot.action_triggered.connect(_on_slot_action_triggered)
		
		# 描画処理
		_update_slot_display(slot, i)

func _on_decide_button_pressed():
	# 決定：一時リストの内容を Global に反映させる
	Global.party_list = temp_party_list.duplicate()
	closed.emit()
	queue_free()

func _on_cancel_button_pressed():
	# キャンセル：何もしない（Globalは元のまま）
	closed.emit()
	queue_free()
	
# シグナルを受け取った時の処理
func _on_slot_action_triggered(index: int):
	if temp_party_list[index] != null:
		temp_party_list[index] = null
		_update_slot_display(v_box.get_child(index), index)
		update_total_cost()
	else:
# --- 追加処理：選択画面を開く ---
		var selector = preload("res://scenes/CharacterSelector.tscn").instantiate()
		add_child(selector)
		
		# 現在の状態を渡してセットアップ
		var max_cost = int(Global.player_data.get("leader_rank", 0))
		var current_cost = _calculate_current_total()
		selector.setup(temp_party_list, max_cost, current_cost)
		
		# キャラが選ばれた時の反応
		selector.character_selected.connect(func(char_id):
			# 1. 一時リストを更新
			temp_party_list[index] = str(int(char_id))
			# 2. そのスロットの見た目を更新
			var slot = v_box.get_child(index)
			_update_slot_display(slot, index)
			# 3. コスト表示を更新
			update_total_cost()
			print("キャラクターID: ", char_id, " をスロット ", index, " に追加しました")
		)
# 表示更新用の共通関数を作っておくと便利です
func _update_slot_display(slot, index):
	var char_id = temp_party_list[index]
	if char_id != null and Global.world_list.has(char_id):
		slot.display_character(Global.world_list[char_id])
	else:
		slot.display_character(null)

# コスト計算用の補助関数
func _calculate_current_total() -> int:
	var total = 0
	for id in temp_party_list:
		if id != null:
			var data = Global.world_list.get(id)
			if data: total += int(data.get("cost", 0))
	return total

func update_total_cost():
	var total = 0
	var party_cost = str(int(Global.player_data.get("leader_rank", 0)))
	for char_id in temp_party_list:
		if char_id != null:
			var data = Global.world_list.get(char_id)
			if data:
				total += int(data.get("cost", 0))
	
	cost_label.text = str(total) + "/" + party_cost
