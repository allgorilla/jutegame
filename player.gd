extends Sprite2D

# スワイプと判定する最小距離
const MIN_SWIPE_DISTANCE = 50.0

# 画面に触れた位置を保持する変数
var touch_start_pos = Vector2.ZERO

# 子ノードのAnimationPlayerを取得
@onready var anim = $PlayerWalk

func _input(event):
	# マウス（またはスマホのタッチ）操作を検知
	if event is InputEventMouseButton:
		if event.pressed:
			# 画面に触れた瞬間の座標を記録
			touch_start_pos = event.position
		else:
			# 指を離した瞬間に、スワイプ距離を計算
			var diff = event.position - touch_start_pos
			
			# 一定以上の距離が動いていたら「移動操作」とみなす
			if diff.length() >= MIN_SWIPE_DISTANCE:
				play_walk_animation()

func play_walk_animation():
	if anim.has_animation("walk"):
		anim.play("walk")
