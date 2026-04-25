extends Control

enum State { READING, WAIT_TAP, COMMAND }
var current_state = State.READING

@onready var message_label = $UI/MessageWindow/MessageLabel
@onready var command_window = $UI/CommandWindow # 最初は hide() しておく

func _ready():
	command_window.hide()
	display_text("ゆうしゃよ、よくぞまいった！")

func display_text(txt):
	current_state = State.READING
	message_label.text = txt
	message_label.visible_ratio = 0
	var tween = create_tween()
	tween.tween_property(message_label, "visible_ratio", 1.0, 1.0)
	await tween.finished
	current_state = State.WAIT_TAP

# 画面全体の透明ボタンが押されたとき
func _on_screen_button_pressed():
	match current_state:
		State.WAIT_TAP:
			# 次のセリフへ
			display_text("ここまでのぼうけんを、きろくしておくかね？")
			await get_tree().create_timer(1.2).timeout # 文字が出終わるのを待つ
			show_commands()
		State.READING:
			# （オプション）文字表示中に押したら一瞬で全文出す処理
			pass

func show_commands():
	current_state = State.COMMAND
	command_window.show()
	# ここでボタンにフォーカスを当てたり、アニメーションさせたりする
