extends Node2D

const TILE_SIZE = 64.0  # 警告回避のためfloatに変更
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

var data = MapData.new() # 解析クラスのインスタンス

func _ready():
	# 1. 解析の実行（重い処理をMapDataに任せる）
	data.parse_maps(map_move, map_event, map_layout, map_object, layout_data_table)
	
	# 2. 解析結果を使って描画（MapManagerは「配置」に専念）
	_setup_world()

func _setup_world():

	# プレイヤー位置の設定
	current_grid_pos = data.player_start_pos
	update_map_position()
	
	# 通行判定のコピー
	walkability_map = data.walkability_map
	
	# 1タイルオブジェクト（草地・壁など）の配置
	for obj in data.object_tiles:
		var tex: Texture2D = null
		
		# 色に応じてテクスチャを選択（ロジックは以前のmatch文と同じ）
		match obj.hex:
			"ff8000": tex = grass_tex # オレンジ
			"ffffff": tex = road_tex  # 白
			"808080": tex = wall_tex  # グレー
		
		if tex:
			spawn_tile_sprite(obj.pos.x, obj.pos.y, tex)
	# 木の配置
	for pos in data.tree_positions:
		spawn_tree(pos.x, pos.y)
		
	# 巨大オブジェクトの配置
	for obj in data.layout_objects:
		spawn_layout_sprite(obj.pos.x, obj.pos.y, obj.tex, obj.size)

	# プレイヤーの準備
	if player:
		player.play("idle")
		player.move_requested.connect(_on_player_move_requested)

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
