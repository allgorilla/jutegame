extends Control
@export var recruitment_cost: int = 50 

@onready var current_gold_label = $StatusPanel/VBox/GoldLine/ValueLabel
@onready var cost_label = $StatusPanel/VBox/CostLine/ValueLabel
@onready var message_panel = $CanvasLayer/Panel
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide

var messages = [
	"ここは さかば よ！\nたびのなかまを しょうかい するわ！",
	"しょうかいりょうは ５０ゴールド よ！"
]
var current_msg_index = 0

func _ready():
	update_ui()
	next_guide.hide()
	# 昨日のフェードイン処理（明るくする）
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade")
		await anim.animation_finished
	_show_message()
	message_panel.gui_input.connect(_on_panel_gui_input)

func _show_message():
	# NEXTガイドを隠して文字表示開始
	next_guide.hide()
	
	var txt = messages[current_msg_index]
	
	# 1. 文字を表示
	await MessageManager.display_text(message_label, txt)
	
	# 2. 表示が終わったら点滅開始
	next_guide.show()
	MessageManager.start_next_animation(next_guide)

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 文字を読んでいる最中のタップをガード（お好みでスキップ処理を入れてもOK）
		if MessageManager.current_state == MessageManager.MsgState.READING:
			return
			
		_advance_message()

func _advance_message():
	current_msg_index += 1
	
	if current_msg_index < messages.size():
		_show_message()
	else:
		# 全てのメッセージが終わった後の処理
		print("メッセージ終了。仲間紹介画面へ、または通信開始。")
		_on_message_finished()

func _on_message_finished():
	# メッセージ枠を消す、または仲間選択UIを出す
	$CanvasLayer/Panel.hide()
	# ここで紹介料のチェックや通信処理（NetworkManagerへの依頼）へ繋げる

func update_ui():
	# 所持金の表示
	var current_gold = Global.player_data.get("gold", 0)
	current_gold_label.text = "%4d G" % current_gold
	# %4d で右詰め整形して表示
	
	# 変数 recruitment_cost の値を反映
	# %d は整数、%4d と書くと「4桁分のスペースを確保して右詰め」になります
	cost_label.text = "%4d G" % recruitment_cost
