extends Control

enum Phase { INTRO, EDIT_PARTY, POST_RESULT, AGAIN_ASK, EXIT }
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
			command_window.show()
			
		Phase.EDIT_PARTY:
			await _edit_party_member()
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

func _edit_party_member():

	# ステータス表示
	var party_member_ui = preload("res://scenes/PartyMember.tscn").instantiate()
	add_child(party_member_ui)
	await party_member_ui.closed
	current_phase = Phase.INTRO

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

func _on_edit_button_pressed():
	command_window.hide()
	current_phase = Phase.EDIT_PARTY
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
