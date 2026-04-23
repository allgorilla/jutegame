extends Node2D

const TILE_SIZE = 64.0

# 外部からの画像指定だけ残す
@export var map_move: Texture2D
@export var map_event: Texture2D
@export var map_layout: Texture2D
@export var map_object: Texture2D
@export var player: AnimatedSprite2D

var data: MapData = MapData.new() 
@onready var spawner: TileSpawner = TileSpawner.new()

var walkability_map = {}
var current_grid_pos = Vector2.ZERO
var is_moving = false

func _ready():
	add_child(spawner)
	# 解析（素材データはMapData側が持っているので、渡す必要がなくなりました）
	data.parse_maps(map_move, map_event, map_layout, map_object)
	_setup_world()

func _setup_world():
	current_grid_pos = data.player_start_pos
	update_map_position()
	walkability_map = data.walkability_map
	
	# 1タイルオブジェクト
	for obj in data.object_tiles:
		var tex = _get_texture_from_data(obj.hex)
		if tex:
			spawner.spawn_tile(self, obj.pos.x, obj.pos.y, tex)
	
	# 木
	for pos in data.tree_positions:
		spawner.spawn_tree(self, pos.x, pos.y, data.tree_tex) # dataから取得
		
	# 巨大オブジェクト
	for obj in data.layout_objects:
		spawner.spawn_layout(self, obj.pos.x, obj.pos.y, obj.tex, obj.size)

	# プレイヤー設定
	if player:
		player.play("idle")
		player.move_requested.connect(_on_player_move_requested)

# MapData側のテクスチャを参照する
func _get_texture_from_data(hex: String) -> Texture2D:
	match hex:
		"ff8000": return data.grass_tex
		"ffffff": return data.road_tex
		"808080": return data.wall_tex
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
