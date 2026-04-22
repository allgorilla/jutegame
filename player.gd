extends AnimatedSprite2D

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
		# 【修正】左スワイプ(diff.x < 0)を「右への移動(1)」として扱う
		dir.x = -1 if diff.x > 0 else 1
		# 進行方向（dir.x）に合わせてキャラを反転
		flip_h = (dir.x > 0) 
	else:
		# 【修正】上スワイプ(diff.y < 0)を「下への移動(1)」として扱う
		dir.y = -1 if diff.y > 0 else 1

	if anim.has_animation("walk"):
		anim.play("walk")

	# この「反転したdir」を渡すことで、MapManagerの計算と合致する
	move_requested.emit(dir)
