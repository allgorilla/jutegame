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
@onready var spawner = TileSpawner.new() # 子ノードとして管理

func _ready():
	add_child(spawner) # Spawnerを自分自身に登録
	
	# 解析
	data.parse_maps(map_move, map_event, map_layout, map_object, layout_data_table)
	# 配置
	_setup_world()

func _setup_world():
	# プレイヤー位置、通行判定の設定...
	current_grid_pos = data.player_start_pos
	update_map_position()
	walkability_map = data.walkability_map
	
	# --- ここから描画（Spawnerに丸投げ） ---
	
	# 1. 地面タイルの配置
	for obj in data.object_tiles:
		var tex = _get_texture_by_hex(obj.hex)
		if tex:
			spawner.spawn_tile(self, obj.pos.x, obj.pos.y, tex)
	
	# 2. 木の配置
	for pos in data.tree_positions:
		spawner.spawn_tree(self, pos.x, pos.y, tree_tex)
		
	# 3. 巨大オブジェクトの配置
	for obj in data.layout_objects:
		spawner.spawn_layout(self, obj.pos.x, obj.pos.y, obj.tex, obj.size)

	# プレイヤーの準備
	if player:
		player.play("idle")
		player.move_requested.connect(_on_player_move_requested)

# ヘルパー関数：色からテクスチャを返す
func _get_texture_by_hex(hex: String) -> Texture2D:
	match hex:
		"ff8000": return grass_tex
		"ffffff": return road_tex
		"808080": return wall_tex
	return null

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

func update_map_position():
	var base_pos = -current_grid_pos * TILE_SIZE
	var center_offset = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	position = base_pos - center_offset
