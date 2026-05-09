extends RefCounted
class_name MapData

# --- 素材データの定義 ---
var layout_data_table = {
	Vector2(26, 25): preload("res://assets/image/layout_king.png"),
	Vector2(31, 27): preload("res://assets/image/layout_bar.png"),
	Vector2(35, 27): preload("res://assets/image/layout_shop.png"),
	Vector2(31, 30): preload("res://assets/image/layout_rest.png"),
	Vector2(35, 30): preload("res://assets/image/layout_guild.png"),
}

var event_table = {
	Vector2(27.0, 27.0): "res://scenes/CastleScene.tscn",
	Vector2(32.0, 28.0): "res://scenes/BarScene.tscn",
	Vector2(36.0, 28.0): "res://scenes/ShopScene.tscn",
	Vector2(32.0, 31.0): "res://scenes/InnScene.tscn",
	Vector2(36.0, 31.0): "res://scenes/GuildScene.tscn"
}

# 赤ドット用：座標とPartyIDの紐付け
var battle_table = {
	Vector2(34.0, 39.0): "regis_full_army",
}

var grass_tex = preload("res://assets/image/grass.png")
var road_tex = preload("res://assets/image/road.png")
var wall_tex = preload("res://assets/image/wall.png")
var tree_tex = preload("res://assets/image/tree.png")

# --- 解析結果を格納する変数 ---
var walkability_map = {}
var layout_objects = []
var player_start_pos = Vector2.ZERO
var tree_positions = []
var object_tiles = []
var event_positions = [] # マゼンタドット
var enemy_positions = [] # 赤ドット

func parse_maps(map_move: Texture2D, map_event: Texture2D, map_layout: Texture2D, map_object: Texture2D):
	if map_move: _parse_move(map_move)
	if map_event: _parse_event(map_event)
	if map_layout: _parse_layout(map_layout)
	if map_object: _parse_objects(map_object)
	
	_validate_tables()

# イベントドットの解析
func _parse_event(tex: Texture2D):
	var img = tex.get_image()
	event_positions.clear()
	enemy_positions.clear()
	
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.a < 0.1: continue
			
			var pos = Vector2(x, y)
			# 青：初期位置
			if color.is_equal_approx(Color(0, 0, 1, 1)): player_start_pos = pos
			# 緑：木
			elif color.is_equal_approx(Color(0, 1, 0, 1)): tree_positions.append(pos)
			# マゼンダ：施設
			elif color.is_equal_approx(Color(1, 0, 1, 1)): event_positions.append(pos)
			# 赤：エネミー
			elif color.is_equal_approx(Color(1, 0, 0, 1)): enemy_positions.append(pos)

# 整合性チェック
func _validate_tables():
	for pos in event_positions:
		if not event_table.has(pos):
			push_error("【未登録イベント】マゼンダ座標の登録不足: ", pos)
	for pos in enemy_positions:
		if not battle_table.has(pos):
			push_error("【未登録エネミー】赤座標の登録不足: ", pos)

# --- 上位から呼ばれる判定用関数 ---
func get_trigger_info(pos: Vector2) -> Dictionary:
	if event_table.has(pos):
		return {"type": "event", "target": event_table[pos]}
	if battle_table.has(pos):
		return {"type": "battle", "target": battle_table[pos]}
	return {"type": "none", "target": ""}

# --- 既存の解析サブ関数群 (省略せず保持) ---
func _parse_move(tex):
	var img = tex.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			walkability_map[Vector2(x, y)] = (color.r > 0.9 and color.g > 0.9 and color.b > 0.9)

func _parse_objects(tex):
	var img = tex.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.a == 0: continue
			var hex = color.to_html(false)
			if hex != "000000": object_tiles.append({"pos": Vector2(x, y), "hex": hex})

func _parse_layout(tex):
	var img = tex.get_image()
	var scanned = []
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var gp = Vector2(x, y)
			if gp in scanned: continue
			var color = img.get_pixel(x, y)
			if color.r > 0.9 and color.g < 0.1 and color.b < 0.1:
				var size = _measure_blue_area(img, x, y, scanned)
				if layout_data_table.has(gp):
					layout_objects.append({"pos": gp, "tex": layout_data_table[gp], "size": size})

func _measure_blue_area(img, sx, sy, sl):
	var w = 1; var h = 1
	while sx + w < img.get_width() and img.get_pixel(sx + w, sy).b > 0.9: w += 1
	while sy + h < img.get_height() and img.get_pixel(sx, sy + h).b > 0.9: h += 1
	for ny in range(sy, sy + h):
		for nx in range(sx, sx + w): sl.append(Vector2(nx, ny))
	return Vector2(w, h)
