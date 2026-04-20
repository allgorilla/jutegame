extends Sprite2D

# 「この方向に1マス動かして！」という信号を定義
signal move_requested(direction: Vector2)

const MIN_SWIPE_DISTANCE = 50.0
var touch_start_pos = Vector2.ZERO

@onready var anim = $PlayerWalk

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			touch_start_pos = event.position
		else:
			var diff = event.position - touch_start_pos
			if diff.length() >= MIN_SWIPE_DISTANCE:
				handle_swipe(diff)

func handle_swipe(diff: Vector2):
	var dir = Vector2.ZERO
	
	if abs(diff.x) > abs(diff.y):
		dir.x = 1 if diff.x > 0 else -1
		flip_h = (dir.x > 0) # 右スワイプで反転
	else:
		dir.y = 1 if diff.y > 0 else -1

	# アニメーションを再生
	if anim.has_animation("walk"):
		anim.play("walk")

	# MapManagerに向かって「dir方向に動かして」と信号を送る
	move_requested.emit(dir)
