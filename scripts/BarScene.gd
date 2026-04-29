extends Control

# ステートを細かく定義
enum Phase { INTRO, COST_INFO, RESULT, POST_RESULT, AGAIN_ASK, EXIT }
var current_phase = Phase.INTRO

@export var recruitment_cost: int = 50 

@onready var current_gold_label = $StatusPanel/VBox/GoldLine/ValueLabel
@onready var cost_label = $StatusPanel/VBox/CostLine/ValueLabel
@onready var message_panel = $CanvasLayer/Panel
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide

# 追加：コマンドウィンドウとその中のボタン
@onready var command_window = $CanvasLayer/CommandWindow
@onready var pay_button = $CanvasLayer/CommandWindow/PayButton
@onready var leave_button = $CanvasLayer/CommandWindow/LeaveButton

func _ready():
	command_window.hide()
	update_ui()
	
	# 【重要】MessageManagerにUIを覚えさせる 
	MessageManager.setup_ui(message_label, next_guide)
	
	# 共通マネージャーで明るくする
	await SceneManager.fade_in_scene()
	
	message_panel.gui_input.connect(_on_panel_gui_input)
	
	# 最初の挨拶を開始
	_proceed_flow()

# シーン進行のメインロジック
func _proceed_flow():
	match current_phase:
		Phase.INTRO:
			# ① 挨拶 (引数はテキストのみでOK) 
			await MessageManager.display_text("ここは さかば よ！\nたびのなかまを しょうかい するわ！")
			current_phase = Phase.COST_INFO
			
		Phase.COST_INFO:
			# ② 料金説明＋選択肢（ガイドなし） 
			await MessageManager.display_text("しょうかいりょうは ５０ゴールド よ！", false)
			_show_commands()
			
		Phase.RESULT:
			# ③ 支払い後の結果
			_consume_gold()
			await MessageManager.display_text("あたらしいなかまが くわわった！")
			current_phase = Phase.POST_RESULT
			
		Phase.POST_RESULT:
			# ④ 合流案内
			await MessageManager.display_text("きにいってもらえたかしら。\nあたらしいなかまとは やどや でごうりゅうしてね！")
			current_phase = Phase.AGAIN_ASK
			
		Phase.AGAIN_ASK:
			# ⑤ もう一度聞く
			await MessageManager.display_text("もうひとり しょうかい しちゃう？", false)
			_show_commands()
			
		Phase.EXIT:
			# ⑥ 退店処理
			await MessageManager.display_text("またいらしてね！")
			SceneManager.change_scene_with_fade("res://scenes/MainMap.tscn")

# パネルクリック時の処理
func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# メッセージが止まっている（WAIT_TAP）ときだけ次へ進む 
		if MessageManager.current_state == MessageManager.MsgState.WAIT_TAP:
			_proceed_flow()

func _show_commands():
	command_window.show()

# --- ボタンのシグナル処理 ---

func _on_pay_button_pressed():
	var current_gold = Global.player_data.get("gold", 0)
	if current_gold < recruitment_cost:
		# お金が足りない場合のメッセージ演出も共通処理で可能
		MessageManager.display_text("あら、おかねが たりないみたいね…")
		return
		
	command_window.hide()
	current_phase = Phase.RESULT
	_proceed_flow()

func _on_leave_button_pressed():
	command_window.hide()
	current_phase = Phase.EXIT
	_proceed_flow()

# --- UI更新・計算系 ---

func _consume_gold():
	var current_gold = Global.player_data.get("gold", 0)
	Global.player_data["gold"] = current_gold - recruitment_cost
	update_ui()

func update_ui():
	var current_gold = Global.player_data.get("gold", 0)
	current_gold_label.text = "%4d G" % current_gold
	cost_label.text = "%4d G" % recruitment_cost
