extends Control

func _ready():
	# 前のシーンから引き継がれたSceneChangerを探す
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade") # 逆再生して明るくする
		await anim.animation_finished
		changer.queue_free() # 用が済んだら消す
