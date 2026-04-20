extends Node2D

const TILE_SIZE = 80

@export var map_bg: Texture2D    # 背景（地面など）
@export var map_event: Texture2D # イベント・オブジェクト（開始地点など）
@export var player: Sprite2D     # プレイヤーへの参照

# プレイヤーの初期位置を保持する変数
var player_start_grid_pos = Vector2.ZERO

func _ready():
	generate_world()
	# プレイヤーの信号を、自分の「_on_player_move_requested」関数に繋ぐ
	if player:
		player.move_requested.connect(_on_player_move_requested)

# 信号を受け取った時の処理
func _on_player_move_requested(direction: Vector2):
	# プレイヤーが「右(1, 0)」に行きたいなら、
	# マップ全体は「左(-1, 0)」にタイル1枚分ずれる
	var move_vector = -direction * TILE_SIZE
	
	# マップ全体を移動させる（Tweenを使うと滑らかになりますが、まずはパッと移動）
	position += move_vector

func generate_world():
	# 1. まずイベントマップを走査して「プレイヤーの開始位置」を特定する
	if map_event:
		find_player_start_position()
	
	# 2. 背景を描画する
	if map_bg:
		spawn_background_tiles()

func find_player_start_position():
	var img = map_event.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			
			# 青色 (0, 0, 255) を判定。
			# color.b > 0.9 などで判定すると、微細な色の違いによる誤差を防げます。
			if color.r == 0 and color.g == 0 and color.b > 0.9 and color.a > 0.9:
				# グリッド座標を保存
				player_start_grid_pos = Vector2(x, y)
				
				# 実際の座標に変換してプレイヤーを配置
				if player:
					player.position = player_start_grid_pos * TILE_SIZE
					# キャラをタイルの中心に置く場合は + Vector2(40, 40) を足す
					player.position += Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
				
				# 開始地点が見つかったらこのループは抜けてOK（1箇所のみ想定）
				return

func spawn_background_tiles():
	var img = map_bg.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.a > 0:
				var tile = ColorRect.new()
				tile.size = Vector2(TILE_SIZE, TILE_SIZE)
				tile.color = color
				tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				add_child(tile)
