extends Control

@onready var message_label = $UI/MessageWindow/MessageLabel

func _ready():
	# 1. 最初は文字をセットし、表示割合を 0（何も見えない状態）にする
	message_label.text = "ゆうしゃよ、よくぞまいった！"
	message_label.visible_ratio = 0
	
	# 2. 少し待ってからメッセージ表示開始
	await get_tree().create_timer(1.0).timeout
	show_message()

func show_message():
	# 3. Tween（トゥイーン）を作成
	var tween = create_tween()
	
	# 1文字 0.1秒 で計算する例
	var duration = message_label.text.length() * 0.1
	tween.tween_property(message_label, "visible_ratio", 1.0, duration)
	
	# 5. アニメーションが終わるのを待つ（必要に応じて）
	await tween.finished
	print("メッセージ表示完了！")
