extends Control
@export var recruitment_cost: int = 50 

@onready var current_gold_label = $StatusPanel/VBox/GoldLine/ValueLabel
@onready var cost_label = $StatusPanel/VBox/CostLine/ValueLabel
@onready var message_label = $CanvasLayer/Panel/MessageLabel
@onready var next_guide = $CanvasLayer/Panel/NextGuide

var messages = [
	"マリィ：\nここは さかば よ！\nたびのなかまを しょうかい するわ！",
	"マリィ：\nしょうかいりょうは ５０ゴールド よ！"
]
var current_msg_index = 0

func _ready():
	update_ui()
	# 昨日のフェードイン処理（明るくする）
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade")
		await anim.animation_finished
	_show_message()

func _input(event):
	if event.is_action_pressed("ui_accept"): # SpaceやEnter
		_advance_message()

func _show_message():
	message_label.text = messages[current_msg_index]
	# 最後のメッセージならガイドを変えるなどの演出
	next_guide.visible = true

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

# マップに戻るボタンの処理
func _on_return_button_pressed():
	# メインマップシーンへ遷移
	get_tree().change_scene_to_file("res://scenes/MainMap.tscn")
