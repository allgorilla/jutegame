# StatusWindow.gd
extends CanvasLayer
signal closed

@onready var main_content = $MainContent

func _ready():
	# 背景ボタン（どこをクリックしても反応するボタン）を接続
	$BackgroundButton.pressed.connect(_on_close_requested)

	main_content.scale = Vector2.ZERO
	
	# 2. アニメーション：0.2秒かけて (1, 1) に拡大
	var tween = create_tween()
	# TRANS_BACK を使うと、少しだけ大きく膨らんでから戻る「ぷるん」とした動きになります
	tween.tween_property(main_content, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _on_close_requested():
	closed.emit()    # 酒場シーンへ「閉じたよ」と伝える
	queue_free()     # 自分を消す
