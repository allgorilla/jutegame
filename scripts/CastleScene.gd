extends Control

# シーンの進行フェーズのみを管理
enum Phase { INTRO, QUESTION, COMMAND, FINISHED }
var current_phase = Phase.INTRO

@onready var command_window = $CanvasLayer/CommandWindow
@onready var message_panel = $CanvasLayer/Panel
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide


func _ready():
	command_window.hide()
	next_guide.hide()
	
	# 共通マネージャーで明るくする
	await SceneManager.fade_in_scene() # 
	
	message_panel.gui_input.connect(_on_panel_gui_input)
	_show_castle_message("ゆうしゃよ、よくぞまいった！") #

# 内部共通：メッセージ表示とNEXT演出
func _show_castle_message(txt: String, show_guide: bool = true):
	next_guide.hide()
	await MessageManager.display_text(message_label, txt)
	
	# ガイドを表示しても良い設定の時だけ表示・アニメ開始
	if show_guide:
		next_guide.show()
		MessageManager.start_next_animation(next_guide)

# パネルクリック時の挙動を整理
func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if MessageManager.current_state == MessageManager.MsgState.READING:
			return

		match current_phase:
			Phase.INTRO:
				current_phase = Phase.QUESTION
				# 次はコマンド選択なので、ガイドは不要（false を渡す）
				await _show_castle_message("ここまでのぼうけんを、きろくしておくかね？", false)
				
				# セリフ完了後、少し待ってからコマンドを表示
				await get_tree().create_timer(0.5).timeout
				_show_commands()
				
			Phase.FINISHED:
				_return_to_map()

# コマンド表示
func _show_commands():
	current_phase = Phase.COMMAND
	next_guide.hide() # コマンド中はガイドを消す
	command_window.show()

# --- ボタンの処理 ---

func _on_save_button_pressed():
	command_window.hide()
	NetworkManager.save_player_data() # [cite: 1, 4]
	
	current_phase = Phase.FINISHED
	_show_castle_message("たしかにセーブしたぞい。ではゆくがよい、ゆうしゃよ！")

func _on_back_button_pressed():
	command_window.hide()
	current_phase = Phase.FINISHED
	_show_castle_message("セーブしないともうすか。ではゆくがよい、ゆうしゃよ！")

func _return_to_map():
	# 突然切り替わるのではなく、暗転してからマップへ
	SceneManager.change_scene_with_fade("res://scenes/MainMap.tscn")
