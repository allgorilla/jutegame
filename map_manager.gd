extends Node2D

const TILE_SIZE = 64.0  # 警告回避のためfloatに変更
@export var map_bg: Texture2D
@export var map_move: Texture2D   # 追加：移動可能範囲
@export var map_event: Texture2D
@export var map_object: Texture2D  # ③：追加
@export var player: Sprite2D

# タイル素材の読み込み
var grass_tex = preload("res://image/grass.png")
var road_tex = preload("res://image/road.png")
var wall_tex = preload("res://image/wall.png")

var walkability_map = {}
var current_grid_pos = Vector2.ZERO
var is_moving = false # 移動中の入力ロック用

func _ready():
	generate_walkability_map()
	generate_world()
	# ③ map_objectの読み込みを追加
	if map_object:
		generate_objects()
		
	if map_event:
		find_player_start_position()
	
	if player:
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

func find_player_start_position():
	var img = map_event.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			# 青ドット判定
			if color.r == 0 and color.g == 0 and color.b > 0.9 and color.a > 0.9:
				current_grid_pos = Vector2(x, y)
				update_map_position()
				return

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
