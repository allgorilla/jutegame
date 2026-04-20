extends Sprite2D

# スワイプと判定する最小距離
const MIN_SWIPE_DISTANCE = 50.0

# 画面に触れた位置を保持する変数
var touch_start_pos = Vector2.ZERO

# 子ノードのAnimationPlayerを取得
@onready var anim = $PlayerWalk

func _ready():
	# 起動時に自動でアニメーションを開始
	if anim.has_animation("walk"):
		anim.play("walk")
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			touch_start_pos = event.position
		else:
			# 指を離した瞬間の位置との差分を計算
			var diff = event.position - touch_start_pos
			
			# スワイプ距離が十分なら向きを判定
			if diff.length() >= MIN_SWIPE_DISTANCE:
				handle_direction(diff)
func handle_direction(diff: Vector2):
	# X（横）の移動量が Y（縦）より大きい場合、左右スワイプとみなす
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			# 右スワイプ
			flip_h = true  # 画像を左右反転
		else:
			# 左スワイプ
			flip_h = false # 画像を元に戻す
	
	# スワイプのたびにアニメーションを再生（または継続）
	if anim.has_animation("walk"):
		anim.play("walk")
func play_walk_animation():
	if anim.has_animation("walk"):
		anim.play("walk")
