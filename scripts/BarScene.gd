extends Control

enum Phase { INTRO, COST_INFO, RESULT, POST_RESULT, AGAIN_ASK, EXIT }
var current_phase = Phase.INTRO

@export var recruitment_cost: int = 50 

@onready var current_gold_label = $StatusPanel/VBox/GoldLine/ValueLabel
@onready var cost_label = $StatusPanel/VBox/CostLine/ValueLabel
@onready var message_panel = $CanvasLayer/Panel
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide
@onready var command_window = $CanvasLayer/CommandWindow
@onready var progress_bar = $CanvasLayer/ProgressBar

func _ready():
	command_window.hide()
	next_guide.hide()
	progress_bar.hide()
	update_ui()
	MessageManager.setup_ui(message_label, next_guide)
	
	await SceneManager.fade_in_scene()
	message_panel.gui_input.connect(_on_panel_gui_input)
	_proceed_flow()

func _proceed_flow():
	match current_phase:
		Phase.INTRO:
			await MessageManager.display_text("ここは さかば よ！\nたびのなかまを しょうかい するわ！")
			current_phase = Phase.COST_INFO
			
		Phase.COST_INFO:
			await MessageManager.display_text("しょうかいりょうは ５０ゴールド よ！", false)
			command_window.show()
			
		Phase.RESULT:
			var npc_data = PlayerFactory.create_character_data()
			npc_data["is_pc"] = false

			# 通信処理をバックグラウンドで開始
			_start_async_save_process.call_deferred(npc_data)

			# 演出開始
			progress_bar.show()
			progress_bar.value = 0
			var tween = create_tween()
			tween.tween_property(progress_bar, "value", 100, 2)
			await tween.finished
			
			# 演出終了後、通信の完了を「一度だけ」待つ
			# （通信が先に終わっていれば即座に通過します）
			await NetworkManager.all_save_finished

			progress_bar.hide()
			message_panel.hide()

			# ステータス画面の表示
			var status_ui = preload("res://scenes/StatusWindow.tscn").instantiate()
			status_ui.set_data(npc_data)
			add_child(status_ui)
			await status_ui.closed

			message_panel.show()
			await MessageManager.display_text("あたらしいなかまが くわわった！")
			current_phase = Phase.POST_RESULT

		Phase.POST_RESULT:
			await MessageManager.display_text("あたらしい なかまとは\nやどや でごうりゅうしてね！")
			current_phase = Phase.AGAIN_ASK
			
		Phase.AGAIN_ASK:
			await MessageManager.display_text("もうひとり しょうかい しちゃう？", false)
			command_window.show()
			
		Phase.EXIT:
			await MessageManager.display_text("またいらしてね！")
			SceneManager.change_scene_with_fade("res://scenes/MainMap.tscn")

# --- 通信ヘルパー（ここを整理） ---

func _start_async_save_process(npc_data: Dictionary):
	# 1. ローカル所持金を減らす
	_consume_gold()

	# 2. NPC保存（新規登録フロー）
	NetworkManager.save_character_data(npc_data)
	await NetworkManager.load_finished
	
	# 通信連続実行のためのインターバル
	await get_tree().process_frame

	# 3. NPCのIDをPCのリストに追加
	var new_npc_id = int(NetworkManager.current_saving_data.get("my_id", 0))
	if new_npc_id > 0:
		if not Global.player_data.has("inn_list"):
			Global.player_data["inn_list"] = []
		if not new_npc_id in Global.player_data["inn_list"]:
			Global.player_data["inn_list"].append(new_npc_id)

	# 4. PC（自分）の上書き保存
	# IDは int() キャストで .0 問題を確実に防止
	var pc_id = int(Global.player_data.get("my_id", 0))
	if pc_id > 0:
		NetworkManager.save_character_data(Global.player_data)
		await NetworkManager.load_finished
	
	# すべて完了した合図を送る
	NetworkManager.all_save_finished.emit()

# --- ユーティリティ ---

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if MessageManager.current_state == MessageManager.MsgState.WAIT_TAP:
			_proceed_flow()

func _on_pay_button_pressed():
	if Global.player_data.get("gold", 0) < recruitment_cost:
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
	Global.player_data["gold"] = int(Global.player_data.get("gold", 0)) - recruitment_cost
	update_ui()

func update_ui():
	var gold = int(Global.player_data.get("gold", 0))
	current_gold_label.text = "%4d G" % gold
	cost_label.text = "%4d G" % recruitment_cost
