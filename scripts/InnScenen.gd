extends Control

enum Phase { INTRO, EDIT_PARTY, EXIT }
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

# --- ユーティリティ ---

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
