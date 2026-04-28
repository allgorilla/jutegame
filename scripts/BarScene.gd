extends Control

func _ready():
	# 昨日のフェードイン処理（明るくする）
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade")
		await anim.animation_finished

# マップに戻るボタンの処理
func _on_return_button_pressed():
	# メインマップシーンへ遷移
	get_tree().change_scene_to_file("res://scenes/MainMap.tscn")
