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
var SceneChangerScene = preload("res://scenes/SceneChanger.tscn")

func _ready():
	# NetworkManagerに保存されたデータを参照する
	if Global.player_data.has("name"):
		var p_name = Global.player_data["name"]
		print("MainMapに到着しました。現在のプレイヤー: ", p_name) 

	# 1. まずは「見えない裏側」で世界の解析と構築をすべて終わらせる
	# (この間、画面はまだ SceneChanger の黒い幕で覆われています)
	data.parse_maps(map_move, map_event, map_layout, map_object) 
	
	if Global.last_player_pos != Vector2.ZERO:
		current_grid_pos = Global.last_player_pos 
	else:
		current_grid_pos = data.player_start_pos 
	
	add_child(spawner) 
	_setup_world() # ここでタイルやオブジェクトがすべて配置される 
	
	# 2. すべての配置が終わった「後」で、共通マネージャーを使って明るくする
	await SceneManager.fade_in_scene()

func _setup_world():
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
	if is_moving: return
	var next_grid_pos = current_grid_pos + direction
	if not walkability_map.get(next_grid_pos, false): return
	
	is_moving = true
	var target_position = position - (direction * TILE_SIZE)
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.2)
	await tween.finished
	
	current_grid_pos = next_grid_pos
	# 移動完了後にトリガー判定
	_check_tile_trigger(current_grid_pos)
	
	is_moving = false

# トリガー判定を統合
func _check_tile_trigger(pos: Vector2):
	var info = data.get_trigger_info(pos)
	
	if info.type == "none":
		return

	# 移動ロック
	is_moving = true
	Global.last_player_pos = pos

	match info.type:
		"event":
			# 施設遷移
			SceneManager.change_scene_with_fade(info.target)
			
		"battle":
			# 戦闘準備：EncounterMaster(Autoload) からデータを引いて BattleManager(Autoload) にセット
			var battle_data = EncounterMaster.get_battle_setup_data(info.target)
			if not battle_data.is_empty():
				BattleManager.next_battle_data = battle_data
				BattleContext.setup_context(battle_data)
				SceneManager.change_scene_with_fade("res://scenes/BattleScene.tscn")
			else:
				push_error("Battle data failed to load for: ", info.target)
				is_moving = false

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
