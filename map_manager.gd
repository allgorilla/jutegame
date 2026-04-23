extends Node2D

const TILE_SIZE = 64.0  # 警告回避のためfloatに変更
@export var map_bg: Texture2D
@export var map_move: Texture2D   # 追加：移動可能範囲
@export var map_event: Texture2D
@export var map_object: Texture2D
@export var map_layout: Texture2D
@export var player: AnimatedSprite2D

# --- ④用のデータテーブル（座標をキーにする） ---
# ここにデバッグプリントで出た内容をコピーして貼り付けていきます
var layout_data_table = {
	Vector2(26.0, 25.0): preload("res://image/layout_king.png"),
	Vector2(31.0, 27.0): preload("res://image/layout_bar.png"),
	Vector2(35.0, 27.0): preload("res://image/layout_shop.png"),
	Vector2(31.0, 30.0): preload("res://image/layout_rest.png"),
	Vector2(35.0, 30.0): preload("res://image/layout_guild.png"),
	
}

# タイル素材の読み込み
var grass_tex = preload("res://image/grass.png")
var road_tex = preload("res://image/road.png")
var wall_tex = preload("res://image/wall.png")
var tree_tex = preload("res://image/tree.png")

var walkability_map = {}
var current_grid_pos = Vector2.ZERO
var is_moving = false # 移動中の入力ロック用

func _ready():
	generate_walkability_map()
	generate_world()
	# ③ map_objectの読み込みを追加
	if map_object:
		generate_objects()
		
	if map_layout:
		generate_layout_objects()
	
	if map_event:
		process_map_event() # 名前を汎用的なものに変更

	if player:
		# 起動と同時にアニメーションを開始（エディタでAutoplayをオンにしていれば不要ですが、念のため）
		player.play("idle")
		player.move_requested.connect(_on_player_move_requested)

# 新設：map_moveから通行可能データを読み込む
func generate_walkability_map():
	if not map_move:
		print("警告: map_moveが設定されていません")
		return
		
	var img = map_move.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			var grid_pos = Vector2(x, y)
			# 白(1,1,1)なら通行可能、それ以外（黒など）は不可
			if color.r > 0.9 and color.g > 0.9 and color.b > 0.9:
				walkability_map[grid_pos] = true
			else:
				walkability_map[grid_pos] = false

# ③：map_objectからタイル画像を配置する
func generate_objects():
	var img = map_object.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.a == 0: continue # 透明ならスキップ
			
			var hex = color.to_html(false)
			var tex: Texture2D = null
			
			# 色に応じてテクスチャを選択
			match hex:
				"ff8000": tex = grass_tex # オレンジ：草むら
				"ffffff": tex = road_tex  # 白：道路
				"808080": tex = wall_tex  # グレー：城壁
				"000000": continue        # 黒：予約スペースなのでスキップ
			
			if tex:
				spawn_tile_sprite(x, y, tex)

# ④：巨大オブジェクトのスキャンと配置
func generate_layout_objects():
	var img = map_layout.get_image()
	var width = img.get_width()
	var height = img.get_height()
	var scanned_pixels = [] # 重複処理防止用

	print("--- 巨大オブジェクトのスキャンを開始 ---")

	# 左上から右下へスキャン
	for y in range(height):
		for x in range(width):
			var grid_pos = Vector2(x, y)
			if grid_pos in scanned_pixels: continue
			
			var color = img.get_pixel(x, y)
			
			# 赤ドット(R=1, G=0, B=0)を起点として発見
			if color.r > 0.9 and color.g < 0.1 and color.b < 0.1:
				# 1. サイズを計測（隣接する青ドットを数える）
				var obj_size = measure_blue_area(img, x, y, scanned_pixels)
				
				# 2. 座標をキーにデータテーブルをサーチ
				if layout_data_table.has(grid_pos):
					var tex = layout_data_table[grid_pos]
					spawn_layout_sprite(x, y, tex, obj_size)
				else:
					# 3. 未登録の場合、登録用コードの形式でデバッグプリントを出す
					# これをそのまま辞書にコピペできるようにしています
					print("警告: Vector2", grid_pos, ": preload(), # 登録がありません")

	print("--- スキャン終了 ---")

# 青ドットを計測してサイズ(タイル数)を返す
func measure_blue_area(img: Image, start_x: int, start_y: int, scanned_list: Array) -> Vector2:
	var w = 1
	var h = 1
	
	# 横幅を計測 (右方向に青ドットが続く限り)
	while start_x + w < img.get_width():
		var c = img.get_pixel(start_x + w, start_y)
		if c.r < 0.1 and c.g < 0.1 and c.b > 0.9: # 青
			w += 1
		else:
			break
			
	# 高さを計測 (下方向に青ドットが続く限り)
	while start_y + h < img.get_height():
		var c = img.get_pixel(start_x, start_y + h)
		if c.r < 0.1 and c.g < 0.1 and c.b > 0.9: # 青
			h += 1
		else:
			break
	
	# 占有範囲をスキャン済みリストに登録
	for ny in range(start_y, start_y + h):
		for nx in range(start_x, start_x + w):
			scanned_list.append(Vector2(nx, ny))
			
	return Vector2(w, h)

# 巨大オブジェクト用のスプライト生成
func spawn_layout_sprite(x, y, tex, grid_size):
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	
	# 画像のサイズを指定されたタイル数分に引き延ばす（または合わせる）
	# 元画像が 128x128 等で、タイル3x2分なら、サイズを調整
	var target_size = grid_size * TILE_SIZE
	var tex_size = tex.get_size()
	sprite.scale = target_size / tex_size
	
	# オブジェクトレイヤー(1)よりさらに手前、キャラ(2)より奥
	sprite.z_index = 1 
	add_child(sprite)

func generate_world():
	if map_bg:
		var img = map_bg.get_image()
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var color = img.get_pixel(x, y)
				if color.a > 0:
					spawn_tile(x, y, color)

# 画像を配置するための新しい関数
func spawn_tile_sprite(x, y, tex):
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false # 左上基準で配置
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	# 背景(0)より手前、キャラ(2以降を想定)より奥に設定
	sprite.z_index = 1 
	add_child(sprite)
	
func _on_player_move_requested(direction: Vector2):
	if is_moving:
		return
		
	var target_grid_pos = current_grid_pos + direction
	
	# walkability_map（map_move由来）を参照して判定
	if walkability_map.get(target_grid_pos) == true:
		is_moving = true
		current_grid_pos = target_grid_pos
		start_scroll_animation()

func start_scroll_animation():
	var target_pos = (-current_grid_pos * TILE_SIZE) - Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_pos, 0.2)
	tween.finished.connect(func(): is_moving = false)

# map_eventのスキャンと処理
func process_map_event():
	var img = map_event.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.a < 0.1: continue # 透明はスキップ

			# --- 青ドット：プレイヤーの初期位置 ---
			if color.r < 0.1 and color.g < 0.1 and color.b > 0.9:
				current_grid_pos = Vector2(x, y)
				update_map_position()
				
			# --- 緑ドット：tree.png を配置 ---
			elif color.r < 0.1 and color.g > 0.9 and color.b < 0.1:
				spawn_tree(x, y)

# 木を配置する専用関数
func spawn_tree(x, y):
	var sprite = Sprite2D.new()
	sprite.texture = tree_tex
	sprite.centered = false
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	
	# 背景(0)より手前、キャラ(2)より奥
	# もし木に隠れるようにしたければキャラより高く設定しますが、
	# まずは他のオブジェクトと同じ 1 で設定します
	sprite.z_index = 1 
	add_child(sprite)

func update_map_position():
	var base_pos = -current_grid_pos * TILE_SIZE
	var center_offset = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	position = base_pos - center_offset

func spawn_tile(x, y, color):
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = color
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)
