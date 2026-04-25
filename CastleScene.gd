extends Control

@onready var message_label = $UI/MessageWindow/MessageLabel

func _ready():
	# 最初は空にしておく
	message_label.text = ""
	
	# 少し間を置いてから喋り出す（演出）
	await get_tree().create_timer(0.5).timeout
	start_dialogue()

func start_dialogue():
	message_label.text = "ゆうしゃよ、よくぞまいった！"
