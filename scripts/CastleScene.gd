extends Control

# 酒場シーンと同様に、進行フェーズを enum で一元管理
enum Phase { INTRO, QUESTION, COMMAND, FINISHED }
var current_phase = Phase.INTRO

@onready var command_window = $CanvasLayer/CommandWindow
@onready var message_panel = $CanvasLayer/Panel
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide

func _ready():
	command_window.hide()
	next_guide.hide()
	
	# 1. UIのセットアップ（MessageManagerにラベルとガイドを登録） 
	MessageManager.setup_ui(message_label, next_guide)
	
	# 2. 共通マネージャーで明るくする
	await SceneManager.fade_in_scene()
	
	# 3. 入力イベントを接続し、最初のフローを開始
	message_panel.gui_input.connect(_on_panel_gui_input)
	_proceed_flow()

# シーン進行のメインロジック（酒場シーンの設計を継承）
func _proceed_flow():
	match current_phase:
		Phase.INTRO:
			# ① 挨拶：引数はテキストのみでOK 
			await MessageManager.display_text("ゆうしゃよ、よくぞまいった！")
			current_phase = Phase.QUESTION
			
		Phase.QUESTION:
			# ② 問いかけ：次はコマンドなので第2引数に false を渡してガイドを隠す 
			await MessageManager.display_text("ここまでのぼうけんを、きろくしておくかね？", false)
			_show_commands()
			
		Phase.FINISHED:
			# ③ 退城処理
			_return_to_map()

# パネルクリック時の処理
func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# メッセージが止まっている（WAIT_TAP）時だけ次へ進む 
		if MessageManager.current_state == MessageManager.MsgState.WAIT_TAP:
			_proceed_flow()

# コマンド表示
func _show_commands():
	current_phase = Phase.COMMAND
	command_window.show()

# --- ボタンのシグナル処理 ---

func _on_save_button_pressed():
	command_window.hide()
	# セーブ実行（NetworkManagerなどは環境に合わせて呼び出し）
	if has_node("/root/NetworkManager"):
		get_node("/root/NetworkManager").save_player_data()
	
	current_phase = Phase.FINISHED
	await MessageManager.display_text("たしかにセーブしたぞい。ではゆくがよい、ゆうしゃよ！")

func _on_back_button_pressed():
	command_window.hide()
	current_phase = Phase.FINISHED
	await MessageManager.display_text("セーブしないともうすか。ではゆくがよい、ゆうしゃよ！")

func _return_to_map():
	# 共通マネージャーでフェードアウトしながら遷移
	SceneManager.change_scene_with_fade("res://scenes/MainMap.tscn")
