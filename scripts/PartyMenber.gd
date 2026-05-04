extends CanvasLayer
signal closed

@onready var main_content = $MainContent

func _ready():
	# アニメーション処理
	main_content.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(main_content, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_decide_button_pressed():
	closed.emit()
	queue_free()

func _on_cancel_button_pressed():
	closed.emit()
	queue_free()
