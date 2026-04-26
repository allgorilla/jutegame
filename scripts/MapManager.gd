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
	if NetworkManager.current_player_data.has("name"):
		var p_name = NetworkManager.current_player_data["name"]
		print("MainMapに到着しました。現在のプレイヤー: ", p_name)
		
		# もしMainMapにラベル(NameLabelなど)があるなら表示を更新
		# $NameLabel.text = p_name + " の冒険"

	# 1. まずは「見えない裏側」で世界の解析と構築をすべて終わらせる
	# (この間、画面はまだ SceneChanger の黒い幕で覆われています)
	data.parse_maps(map_move, map_event, map_layout, map_object)
	
	if Global.last_player_pos != Vector2.ZERO:
		current_grid_pos = Global.last_player_pos
	else:
		current_grid_pos = data.player_start_pos
	
	add_child(spawner)
	_setup_world() # ここでタイルやオブジェクトがすべて配置される
	
	# 2. すべての配置が終わった「後」で、フェードを解除して幕を開ける
	var changer = get_tree().root.get_node_or_null("SceneChanger")
	if changer:
		var anim = changer.get_node("AnimationPlayer")
		anim.play_backwards("fade") # 明るくする
		await anim.animation_finished # 明るくなるのを待つ
		changer.queue_free() # 最後に幕を捨てる

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
	
	# 1. 次の座標を計算
	var next_grid_pos = current_grid_pos + direction
	
	# 2. 通行判定（白タイルかどうか等）
	if not walkability_map.get(next_grid_pos, false):
		return
	
	# 3. 移動開始
	is_moving = true
	var target_position = position - (direction * TILE_SIZE)
	
	# 4. Tweenでスクロールアニメーション実行
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.2)
	
	# ★ここが重要：アニメーションが終わるまでここで待つ！
	await tween.finished
	
	# 5. 内部的な座標データを更新
	current_grid_pos = next_grid_pos
	
	# 6. 移動が終わって、キャラがマスに乗った「後」で判定！
	_check_event_trigger(current_grid_pos)
	
	# イベントが発生しなかった場合のためにフラグを下ろす
	# (イベント発生時はシーンが切り替わるので気にしなくてOK)
	is_moving = false

func _check_event_trigger(pos: Vector2):
	if pos in data.event_positions:
		# 1. 辞書に登録されているかチェック
		if not data.event_table.has(pos):
			# 未登録なら警告を出して処理を中断（またはデフォルトへ）
			push_warning("【警告】未登録のイベント座標を踏みました: ", pos, "。MapDataのevent_tableに追加してください。")
			is_moving = false # 動けるように戻す
			return 

		# 2. 登録がある場合のみ遷移処理へ
		is_moving = true
		var target_scene_path = data.event_table[pos]
		
		# フェード処理の開始
		var changer = SceneChangerScene.instantiate()
		get_tree().root.add_child(changer)
		
		var anim = changer.get_node("AnimationPlayer")
		anim.play("fade")
		await anim.animation_finished
		
		Global.last_player_pos = pos
		get_tree().change_scene_to_file(target_scene_path)

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
