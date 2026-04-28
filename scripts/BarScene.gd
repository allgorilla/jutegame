extends Control
@export var recruitment_cost: int = 50 

@onready var current_gold_label = $StatusPanel/VBox/GoldLine/ValueLabel
@onready var cost_label = $StatusPanel/VBox/CostLine/ValueLabel

func _ready():
	update_ui()
	# 昨日のフェードイン処理（明るくする）
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade")
		await anim.animation_finished

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
