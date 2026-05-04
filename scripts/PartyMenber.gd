extends CanvasLayer
signal closed

const CHARACTER_SLOT_SCENE = preload("res://scenes/CharacterSlot.tscn")

@onready var main_content = $MainContent
@onready var v_box = $MainContent/ScrollContainer/VBoxContainer

func _ready():
	# アニメーション処理
	main_content.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(main_content, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# シーン開始時にスロットを生成する
	setup_party_list()

func setup_party_list():
	# 一旦、VBoxContainerの中身を完全に空にする
	# for child in v_box.get_children():
	#	child.queue_free()
	
	for i in range(8):
		var slot = load("res://scenes/CharacterSlot.tscn").instantiate()
		# ★ここが重要：v_box（VBoxContainer）に対して追加する
		v_box.add_child(slot)

func _on_decide_button_pressed():
	closed.emit()
	queue_free()

func _on_cancel_button_pressed():
	closed.emit()
	queue_free()
