extends CanvasLayer
signal closed

const CHARACTER_SLOT_SCENE = preload("res://scenes/CharacterSlot.tscn")

@onready var main_content = $MainContent
@onready var v_box = $MainContent/ScrollContainer/VBoxContainer

func _ready():
	# 1. アニメーション処理
	main_content.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(main_content, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# 2. ★ここでデータを最新にする（Globalに任せる）
	await Global.fetch_world_list()
	
	# 3. 準備ができてからスロットを生成する[cite: 4]
	setup_party_list()

func setup_party_list():
	# 既存のスロットをクリア（再描画時用）
	for child in v_box.get_children():
		child.queue_free()
	
	# Globalの最新データを元に8個生成[cite: 4]
	for i in range(8):
		var slot = CHARACTER_SLOT_SCENE.instantiate()
		v_box.add_child(slot)
		
		# スロットにデータを流し込む処理をここに追加
		var char_id = Global.party_list[i]
		print(char_id)
		print(Global.world_list.has(char_id))
		if char_id != null and Global.world_list.has(char_id):
			slot.display_character(Global.world_list[char_id])
		else:
			slot.display_character(null)

func _on_decide_button_pressed():
	closed.emit()
	queue_free()

func _on_cancel_button_pressed():
	closed.emit()
	queue_free()
