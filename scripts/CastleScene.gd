extends Control

enum State { READING, WAIT_TAP, COMMAND, FINISHED }
var current_state = State.READING

@onready var command_window = $CanvasLayer/CommandWindow # 枠
@onready var message_panel = $CanvasLayer/Panel # メッセージ枠本体
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide

func _ready():
	command_window.hide()
	next_guide.hide()
	# 以前実装したフェードイン処理 
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade")
		await anim.animation_finished
	
	# 共通マネージャーで王様のセリフを表示
	_show_message("ゆうしゃよ、よくぞまいった！")
	message_panel.gui_input.connect(_on_panel_gui_input)

# メッセージ表示とNEXTガイドの制御をまとめた内部関数
func _show_message(txt):
	next_guide.hide() # 表示中はガイドを隠す
	current_state = State.READING
	
	# 共通処理で文字を表示
	await MessageManager.display_text(message_label, txt)
	
	# 表示完了後にガイドを出して点滅開始
	next_guide.show()
	MessageManager.start_next_animation(next_guide)
	current_state = State.WAIT_TAP

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 文字を読んでいる最中のタップをガード（お好みでスキップ処理を入れてもOK）
		if MessageManager.current_state == MessageManager.MsgState.WAIT_TAP:
			_show_message("ここまでのぼうけんを、きろくしておくかね？")
			await get_tree().create_timer(1.2).timeout
			show_commands()
		elif MessageManager.current_state == MessageManager.MsgState.READING:
			return
		elif current_state == State.FINISHED:
			return_to_map()

func show_commands():
	current_state = State.COMMAND
	command_window.show()

# --- ボタンの処理 ---

func _on_save_button_pressed():
	command_window.hide()
	
	# --- 実際のセーブ処理を組み込み ---
	NetworkManager.save_player_data()
	# --------------------------------
	
	_show_message("たしかにセーブしたぞい。ではゆくがよい、ゆうしゃよ！")
	current_state = State.FINISHED

func _on_back_button_pressed():
	command_window.hide()
	# もどる選択時のメッセージを表示
	_show_message("セーブしないともうすか。ではゆくがよい、ゆうしゃよ！")
	current_state = State.FINISHED

# マップへ戻る
func return_to_map():
	get_tree().change_scene_to_file("res://scenes/MainMap.tscn")
