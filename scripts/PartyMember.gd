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
		# --- 削除の実行 ---
		temp_party_list[index] = null
		
		# 該当するスロットだけ再描画する
		var slot = v_box.get_child(index)
		_update_slot_display(slot, index)
	else:
		# --- 追加の実行（今後の実装用） ---
		print("スロット ", index, " 番に追加画面を開きます")
	
	update_total_cost()

# 表示更新用の共通関数を作っておくと便利です
func _update_slot_display(slot, index):
	var char_id = temp_party_list[index]
	if char_id != null and Global.world_list.has(char_id):
		slot.display_character(Global.world_list[char_id])
	else:
		slot.display_character(null)


func update_total_cost():
	var total = 0
	var party_cost = str(int(Global.player_data.get("leader_rank")))
	for char_id in temp_party_list:
		if char_id != null:
			var data = Global.world_list.get(char_id)
			if data:
				total += int(data.get("cost", 0))
	
	cost_label.text = str(total) + "/" + party_cost
