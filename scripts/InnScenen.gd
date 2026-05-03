extends Control

enum Phase { INTRO, SHOW_PARTY, POST_RESULT, AGAIN_ASK, EXIT }
var current_phase = Phase.INTRO

@export var recruitment_cost: int = 50 

@onready var message_panel = $CanvasLayer/Panel
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide
@onready var command_window = $CanvasLayer/CommandWindow

func _ready():
	_setup_initial_ui()
	message_panel.gui_input.connect(_on_panel_gui_input)
	
	await SceneManager.fade_in_scene()
	_proceed_flow()

func _proceed_flow():
	match current_phase:
		Phase.INTRO:
			await MessageManager.display_text("やどやです。\nメンバーのいれかえをしますか？")
			current_phase = Phase.SHOW_PARTY
			command_window.show()
			
		Phase.SHOW_PARTY:
			await _execute_recruitment_sequence() # ガチャ工程を別関数に抽出
			current_phase = Phase.POST_RESULT
			_proceed_flow()

		Phase.POST_RESULT:
			await MessageManager.display_text("あたらしい なかまとは\nやどや でごうりゅうしてね！")
			current_phase = Phase.AGAIN_ASK
			
		Phase.AGAIN_ASK:
			await MessageManager.display_text("もうひとり しょうかい しちゃう？", false)
			command_window.show()
			
		Phase.EXIT:
			await MessageManager.display_text("やどやを たちさった。")
			SceneManager.change_scene_with_fade("res://scenes/MainMap.tscn")

# --- ガチャメインシーケンス ---

func _execute_recruitment_sequence():
	var npc_data = PlayerFactory.create_character_data()
	npc_data["is_pc"] = false
	
	# 保存処理開始（マウス入力を一時無効化）
	_start_async_save_process.call_deferred(npc_data)

	# 演出
	var tween = create_tween()
	await tween.finished
	
	# 通信待ち
	await NetworkManager.all_save_finished
	message_panel.hide()

	# ステータス表示
	var status_ui = preload("res://scenes/StatusWindow.tscn").instantiate()
	status_ui.set_data(npc_data)
	add_child(status_ui)
	await status_ui.closed

	# 完了報告
	message_panel.show()
	await MessageManager.display_text("あたらしいなかまが くわわった！")

# --- 通信ヘルパー ---

func _start_async_save_process(npc_data: Dictionary):
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE # 通信中の誤タップ防止
	
	_consume_gold()

	# 1. NPC保存
	NetworkManager.save_character_data(npc_data)
	await NetworkManager.load_finished
	await get_tree().process_frame

	# 2. PCのリスト更新
	_update_inn_list(int(NetworkManager.current_saving_data.get("my_id", 0)))

	# 3. PCデータ上書き保存
	var pc_id = int(Global.player_data.get("my_id", 0))
	if pc_id > 0:
		NetworkManager.save_character_data(Global.player_data)
		await NetworkManager.load_finished
	
	message_panel.mouse_filter = Control.MOUSE_FILTER_STOP

# --- ユーティリティ ---

func _update_inn_list(new_id: int):
	if new_id <= 0: return
	var list = Global.player_data.get("inn_list", [])
	if not new_id in list:
		list.append(new_id)
		Global.player_data["inn_list"] = list

func _setup_initial_ui():
	command_window.hide()
	next_guide.hide()
	MessageManager.setup_ui(message_label, next_guide)

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if MessageManager.current_state == MessageManager.MsgState.WAIT_TAP:
			_proceed_flow()

func _on_pay_button_pressed():
	if int(Global.player_data.get("gold", 0)) < recruitment_cost:
		MessageManager.display_text("あら、おかねが たりないみたいね…")
		return
	command_window.hide()
	current_phase = Phase.RESULT
	_proceed_flow()

func _on_leave_button_pressed():
	command_window.hide()
	current_phase = Phase.EXIT
	_proceed_flow()

func _consume_gold():
	var gold = int(Global.player_data.get("gold", 0))
	Global.player_data["gold"] = gold - recruitment_cost
	update_ui()

func update_ui():
	var gold = int(Global.player_data.get("gold", 0))
