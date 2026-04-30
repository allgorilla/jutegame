# StatusWindow.gd
extends CanvasLayer
signal closed

func _ready():
	# 背景ボタン（どこをクリックしても反応するボタン）を接続
	$BackgroundButton.pressed.connect(_on_close_requested)
	
func _on_close_requested():
	closed.emit()    # 酒場シーンへ「閉じたよ」と伝える
	queue_free()     # 自分を消す
