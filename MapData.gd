extends RefCounted
class_name MapData

# --- 素材データの定義（こちらに移動） ---
var layout_data_table = {
	Vector2(26, 25): preload("res://image/layout_king.png"),
	Vector2(31, 27): preload("res://image/layout_bar.png"),
	Vector2(35, 27): preload("res://image/layout_shop.png"),
	Vector2(31, 30): preload("res://image/layout_rest.png"),
	Vector2(35, 30): preload("res://image/layout_guild.png"),
}

var grass_tex = preload("res://image/grass.png")
var road_tex = preload("res://image/road.png")
var wall_tex = preload("res://image/wall.png")
var tree_tex = preload("res://image/tree.png")

# --- 解析結果を格納する変数 ---
var walkability_map = {}
var layout_objects = []
var player_start_pos = Vector2.ZERO
var tree_positions = []
var object_tiles = []

# 解析メイン関数（引数から layout_table を削除できます）
func parse_maps(map_move: Texture2D, map_event: Texture2D, map_layout: Texture2D, map_object: Texture2D):
	if map_move:
		_parse_move(map_move)
	if map_event:
		_parse_event(map_event)
	if map_layout:
		_parse_layout(map_layout) # クラス内のテーブルを使うので引数不要
	if map_object:
		_parse_objects(map_object)

# 通行判定の解析
func _parse_move(tex: Texture2D):
	var img = tex.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			# 白(1,1,1)なら通行可能
			walkability_map[Vector2(x, y)] = (color.r > 0.9 and color.g > 0.9 and color.b > 0.9)

# イベント（初期位置・木）の解析
func _parse_event(tex: Texture2D):
	var img = tex.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.a < 0.1: continue
			
			# 青：プレイヤー初期位置
			if color.r < 0.1 and color.g < 0.1 and color.b > 0.9:
				player_start_pos = Vector2(x, y)
			# 緑：木
			elif color.r < 0.1 and color.g > 0.9 and color.b < 0.1:
				tree_positions.append(Vector2(x, y))

# 1タイルオブジェクトの解析
func _parse_objects(tex: Texture2D):
	var img = tex.get_image()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			if color.a == 0: continue
			
			var hex = color.to_html(false)
			# 黒(000000)以外をリストに追加
			if hex != "000000":
				object_tiles.append({"pos": Vector2(x, y), "hex": hex})

# 巨大オブジェクトの解析
func _parse_layout(tex: Texture2D):
	var img = tex.get_image()
	var scanned_pixels = []
	var layout_table = self.layout_data_table
	
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var grid_pos = Vector2(x, y)
			if grid_pos in scanned_pixels: continue
			
			var color = img.get_pixel(x, y)
			if color.r > 0.9 and color.g < 0.1 and color.b < 0.1:
				# サイズ計測（MapData内で完結）
				var obj_size = _measure_blue_area(img, x, y, scanned_pixels)
				
				if layout_table.has(grid_pos):
					layout_objects.append({
						"pos": grid_pos,
						"tex": layout_table[grid_pos],
						"size": obj_size
					})
				else:
					# 逆引き用警告
					print("警告: Vector2", grid_pos, ": preload(\"\"), # 登録がありません")

# サイズ計測ロジック（中身は以前と同じ）
func _measure_blue_area(img: Image, start_x: int, start_y: int, scanned_list: Array) -> Vector2:
	var w = 1
	var h = 1
	while start_x + w < img.get_width() and img.get_pixel(start_x + w, start_y).b > 0.9:
		w += 1
	while start_y + h < img.get_height() and img.get_pixel(start_x, start_y + h).b > 0.9:
		h += 1
	for ny in range(start_y, start_y + h):
		for nx in range(start_x, start_x + w):
			scanned_list.append(Vector2(nx, ny))
	return Vector2(w, h)
