extends Node
class_name TileSpawner

const TILE_SIZE = 64.0

# 1タイルのスプライトを生成
func spawn_tile(parent: Node, x: int, y: int, tex: Texture2D):
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	sprite.z_index = 1
	parent.add_child(sprite)

# 木（または特定の1タイル装飾）を生成
func spawn_tree(parent: Node, x: int, y: int, tex: Texture2D):
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	sprite.z_index = 1
	parent.add_child(sprite)

# 巨大オブジェクト（レイアウト）を生成
func spawn_layout(parent: Node, x: int, y: int, tex: Texture2D, grid_size: Vector2):
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	
	# スケール調整
	var target_size = grid_size * TILE_SIZE
	var tex_size = tex.get_size()
	sprite.scale = target_size / tex_size
	
	sprite.z_index = 1
	parent.add_child(sprite)
