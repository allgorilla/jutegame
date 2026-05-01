# PlayerFactory.gd
class_name PlayerFactory

enum Rarity { C, UC, R, SR }

## 初期プレイヤーデータの生成
static func create_initial_data(player_name: String) -> Dictionary:
	# 共通ロジックでベースデータを生成
	var data = _generate_base_stats()
	
	# プレイヤー固有の情報を上書き・追加
	data["name"] = player_name
	data["gold"] = 500
	data["soldiers"] = []
	
	_print_debug_log(data)
	return data

## 酒場で雇うNPCキャラクター用の生成
static func create_character_data() -> Dictionary:
	# 共通ロジックでベースデータを生成
	var data = _generate_base_stats()
	
	# NPC専用：NameFactoryから名前を取得
	data["name"] = NameFactory.generate_name()
	
	# NPCには gold や soldiers は含めない
	return data

## 内部用：ステータスとスキルの抽選ロジック（共通化）
static func _generate_base_stats() -> Dictionary:
	var rarity = _pick_rarity()
	
	# POWERとMAGICの決定
	var power = randi_range(1, 4)
	var magic_val = 0
	
	match power:
		1: magic_val = randi_range(1, 10)
		2: magic_val = randi_range(1, 8)
		3: magic_val = randi_range(1, 6)
		4: magic_val = randi_range(1, 4)
	
	# スキルの抽選
	var skill_id = "NONE"
	if rarity >= Rarity.UC:
		skill_id = SkillFactory.get_random_skill_id(rarity)
		
	return {
		"my_id": 0,
		"cost": 10,
		"rarity": rarity,
		"power": power,
		"magic": magic_val,
		"skill_id": skill_id
	}

static func _pick_rarity() -> int:
	var roll = randf()
	if roll < 0.02: return Rarity.SR
	elif roll < 0.20: return Rarity.R
	elif roll < 0.60: return Rarity.UC
	else: return Rarity.C

static func _print_debug_log(data: Dictionary) -> void:
	print("--- キャラクター生成結果 ---")
	print("名前: ", data["name"])
	print("POWER : ", data["power"], " / MAGIC : ", data["magic"])
	if data.has("gold"):
		print("所持金: ", data["gold"], " G")
	print("---------------------------")
