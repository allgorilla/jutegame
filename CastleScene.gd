extends Control

enum State { READING, WAIT_TAP, COMMAND, FINISHED }
var current_state = State.READING

@onready var message_label = $UI/MessageWindow/MessageLabel
@onready var command_window = $UI/CommandWindow # 枠
@onready var screen_button = $UI/ScreenButton # 画面全体の透明ボタン

func _ready():
	# テスト：名前「Hero1」、パスワード「pass」でデータを送ってみる
	NetworkManager.save_player_data("Hero1", 30, 50, 10, "pass")
	
	command_window.hide()
	# 最初のメッセージ
	display_text("ゆうしゃよ、よくぞまいった！")
	current_state = State.WAIT_TAP

func display_text(txt):
	current_state = State.READING
	message_label.text = txt
	message_label.visible_ratio = 0
	var duration = txt.length() * 0.1 # 文字数に合わせて速度調整
	var tween = create_tween()
	tween.tween_property(message_label, "visible_ratio", 1.0, duration)
	await tween.finished

# 画面全体タップ（透明ボタン）
func _on_screen_button_pressed():
	if current_state == State.WAIT_TAP:
		# 最初のセリフが終わってタップされたら、次の問いかけへ
		display_text("ここまでのぼうけんを、きろくしておくかね？")
		current_state = State.WAIT_TAP
		await get_tree().create_timer(1.2).timeout
		show_commands()
	elif current_state == State.FINISHED:
		# 全ての会話が終わってタップされたらマップに戻る
		return_to_map()

func show_commands():
	current_state = State.COMMAND
	command_window.show()
	# コマンド選択中は画面全体の透明ボタンを無効化（誤爆防止）
	screen_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

# --- ボタンの処理 ---

func _on_save_button_pressed():
	command_window.hide()
	screen_button.mouse_filter = Control.MOUSE_FILTER_STOP
	# セーブ後のメッセージを表示
	display_text("たしかにセーブしたぞい。ではゆくがよい、ゆうしゃよ！")
	current_state = State.FINISHED

func _on_back_button_pressed():
	command_window.hide()
	screen_button.mouse_filter = Control.MOUSE_FILTER_STOP
	# もどる選択時のメッセージを表示
	display_text("セーブしないともうすか。ではゆくがよい、ゆうしゃよ！")
	current_state = State.FINISHED

# マップへ戻る
func return_to_map():
	get_tree().change_scene_to_file("res://PlayerController.tscn")
