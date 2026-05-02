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
@onready var command_window = $CanvasLayer/CommandWindow
@onready var pay_button = $CanvasLayer/CommandWindow/PayButton
@onready var leave_button = $CanvasLayer/CommandWindow/LeaveButton
@onready var progress_bar = $CanvasLayer/ProgressBar

func _ready():
	command_window.hide()
	next_guide.hide()
	progress_bar.hide()
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
			# コマンドを隠し、プログレスバーを表示（仮定）
			progress_bar.show()
			progress_bar.value = 0
			
			# 3秒間で 0 から 100 へアニメーションさせる
			var tween = create_tween()
			# set_trans(Tween.TRANS_QUART) などを足すと「徐々に加速」などの味付けも可能
			tween.tween_property(progress_bar, "value", 100, 1.0)
			
			# アニメーション終了を待つ
			await tween.finished
			
			progress_bar.hide()
			message_panel.hide()
			
			# 1. まずキャラクターデータを生成
			var character_data = PlayerFactory.create_character_data()

			# 2. シーンを読み込んで実体化（インスタンス化）する
			var status_ui = preload("res://scenes/StatusWindow.tscn").instantiate()
			
			# 3. 【重要】実体化した status_ui に対してデータを渡す
			status_ui.set_data(character_data)

			# 4. 画面（ツリー）に追加する
			add_child(status_ui)

			# 5. 閉じられるまで待機
			await status_ui.closed			
			# ③ 支払い後の結果
			message_panel.show()
			_consume_gold()

			# サーバー上の所持金を更新する。
			NetworkManager.save_player_data()
			
			await MessageManager.display_text("あたらしいなかまが くわわった！")
			current_phase = Phase.POST_RESULT
			
		Phase.POST_RESULT:
			# ④ 合流案内
			await MessageManager.display_text("あたらしい なかまとは\nやどや でごうりゅうしてね！")
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

# BarScene.gd 内での処理イメージ

func _show_status_window(data):
	# 1. ステータス画面のシーンを読み込んでインスタンス化
	var status_scene = preload("res://scenes/StatusWindow.tscn").instantiate()
	
	# 2. 酒場シーン（自分自身）の子として画面に追加
	add_child(status_scene)
	
	# 3. データを渡す
	status_scene.set_data(data)
	
	# 4. ステータス画面が閉じられるのを待つ（シグナルを利用）
	await status_scene.closed 
	
	# 5. 閉じたらフローを再開
	_proceed_flow()
