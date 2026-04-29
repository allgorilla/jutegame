# SceneManager.gd
extends Node

var SceneChangerScene = preload("res://scenes/SceneChanger.tscn")

# 画面を暗くして、指定したシーンへ遷移する
func change_scene_with_fade(target_scene_path: String):
	# 1. 幕（SceneChanger）を生成して追加
	var changer = SceneChangerScene.instantiate()
	get_tree().root.add_child(changer)
	
	var anim = changer.get_node("AnimationPlayer")
	
	# 2. 暗転アニメーションを実行
	anim.play("fade")
	await anim.animation_finished
	
	# 3. シーンを切り替え
	get_tree().change_scene_to_file(target_scene_path)
	
	# ※ 切り替え先の _ready() 等でフェードアウト（明るくする）を行う想定です

# 今のシーンのまま、単に暗くしたり明るくしたりするだけの関数
func fade_in():
	var changer = SceneChangerScene.instantiate()
	get_tree().root.add_child(changer)
	var anim = changer.get_node("AnimationPlayer")
	anim.play("fade")
	await anim.animation_finished

func fade_out():
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade")
		await anim.animation_finished
		changer.queue_free()
