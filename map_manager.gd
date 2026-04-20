extends Node2D

const TILE_SIZE = 80
@export var map_bg: Texture2D
@export var map_event: Texture2D
@export var player: Sprite2D

# 座標ごとの通行可否を保存する辞書（Dictionary）
# キー: Vector2(x, y), 値: bool (true=歩ける)
var walkability_map = {}

# 現在のプレイヤーのグリッド座標（初期位置で設定）
var current_grid_pos = Vector2.ZERO

# プレイヤーの初期位置を保持する変数
var player_start_grid_pos = Vector2.ZERO

# 移動中かどうかを管理するフラグ
var is_moving = false

func _ready():
	generate_world()
	# プレイヤーの信号を、自分の「_on_player_move_requested」関数に繋ぐ
	if player:
		player.move_requested.connect(_on_player_move_requested)

func generate_world():
	if map_bg:
		var img = map_bg.get_image()
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var color = img.get_pixel(x, y)
				var grid_pos = Vector2(x, y)
				
				# 通行判定データの保存
				if color.r > 0.9 and color.g > 0.9 and color.b > 0.9:
					walkability_map[grid_pos] = true
				else:
					walkability_map[grid_pos] = false
				
				# タイルの生成（ここで共通関数を呼び出す）
				if color.a > 0:
					spawn_tile(x, y, color)
	
	if map_event:
		find_player_start_position()

# 移動リクエストが来た時の処理
func _on_player_move_requested(direction: Vector2):
	# ② すでに移動中なら、次の入力は無視する
	if is_moving:
		return
	
	# ① 移動が可能か判定
	var target_grid_pos = current_grid_pos + direction
	if walkability_map.get(target_grid_pos) == true:
		# 移動確定なのでロックをかける
		is_moving = true
		current_grid_pos = target_grid_pos
		
		# ② スクロールアニメーションの開始
		start_scroll_animation()
	else:
		# 移動不可の場合は、ここで終了（必要なら「壁にぶつかった」演出をここに入れる）
		print("移動不可")

func start_scroll_animation():
	# 目標となる position を計算
	var target_pos = (-current_grid_pos * TILE_SIZE) - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	# Tweenを作成して、0.2秒かけて滑らかに移動させる
	var tween = create_tween()
	# transition型とease型を指定すると「動き出し」や「止まり際」がより自然になります
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# positionプロパティを target_pos まで変化させる
	tween.tween_property(self, "position", target_pos, 0.2)
	
	# ③ アニメーションが終了したら、入力を受け付けるようにする
	tween.finished.connect(func(): is_moving = false)

func find_player_start_position():
	var img = map_event.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.r == 0 and color.g == 0 and color.b > 0.9 and color.a > 0.9:
				current_grid_pos = Vector2(x, y)
				update_map_position()
				return

# 座標更新処理を共通化
func update_map_position():
	# 「今いるタイルの位置」を画面中央(0,0)に持ってくる
	var base_pos = -current_grid_pos * TILE_SIZE
	
	# タイルの中心を(0,0)に合わせるための、常に一定のオフセット
	# (背景が右上にずれていた問題も、これで中心に収束します)
	var center_offset = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	position = base_pos - center_offset

# タイル生成のロジックをここに集約
func spawn_tile(x, y, color):
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = color
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	tile.z_index = 0
	add_child(tile)

func spawn_object(x, y, color):
	# 例えば「純粋な赤 (#ff0000)」をプレイヤーの開始地点とする
	if color.to_html(false) == "ff0000":
		if player:
			player.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	else:
		# それ以外は「動くオブジェクト」として配置
		var obj = ColorRect.new()
		# 背景タイルより少し小さくすると「上に乗ってる感」が出ます
		obj.size = Vector2(TILE_SIZE * 0.8, TILE_SIZE * 0.8)
		obj.color = color
		obj.position = Vector2(x * TILE_SIZE + 8, y * TILE_SIZE + 8)
		obj.z_index = 2 # キャラと同じか少し上
		add_child(obj)
