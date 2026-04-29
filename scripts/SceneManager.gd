# SceneManager.gd
extends Node

var SceneChangerScene = preload("res://scenes/SceneChanger.tscn")

# 指定のシーンへフェード付きで遷移する（暗転までを担当）
func change_scene_with_fade(target_scene_path: String):
	var changer = SceneChangerScene.instantiate()
	get_tree().root.add_child(changer)
	
	var anim = changer.get_node("AnimationPlayer")
	anim.play("fade")
	await anim.animation_finished
	
	get_tree().change_scene_to_file(target_scene_path)

# シーン開始時に「明るくする」共通処理
func fade_in_scene():
	# ルートに追加されている SceneChanger を探す
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		# 逆再生（明るくする演出）
		anim.play_backwards("fade")
		await anim.animation_finished
		# 演出が終わったら、幕（キャンバスレイヤー）を消去する
		changer.queue_free()
