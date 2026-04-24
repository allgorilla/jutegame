extends Control

func _ready():
	# 昨日のフェードイン処理（明るくする）
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade")
		await anim.animation_finished
		# ※ここでは queue_free せずに、戻る時までとっておくのもアリです

# 「戻る」ボタンのシグナル（pressed）に接続
func _on_button_pressed():
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	
	if changer:
		# 1. 再び暗くする
		var anim = changer.get_node("AnimationPlayer")
		anim.play("fade")
		await anim.animation_finished
		
		# 2. 元のマップシーンへ戻る（シーンのファイルパスを指定）
		get_tree().change_scene_to_file("res://PlayerController.tscn")
	else:
		# フェードなしで戻る場合
		get_tree().change_scene_to_file("res://PlayerController.tscn")
