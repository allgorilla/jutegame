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
	data["inn_list"] = []
	
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
	var costs = [10, 15, 20, 25, 30]
	var cost = costs.pick_random()
	var rarity = _pick_rarity()
	var base_power: int
	
	# --- POWERの決定 ---
	var extra_power = randi_range(1, 4)
	match cost:
		10: base_power = 0
		15: base_power = 2
		20: base_power = 4
		25: base_power = 6
		30: base_power = 8
	var total_power = base_power + extra_power

	# --- MAGICの決定 ---
	# 戦闘力(extra_power)に応じた魔力最大値を定義 
	var magic_max_table = {1: 10, 2: 8, 3: 6, 4: 4}
	var magic_max = magic_max_table[extra_power]
	var magic_val = randi_range(1, magic_max)
	
	# --- 低スペック補正の判定 ---
	# 魔力が最大値の半分以下であった場合は「低スペック補正」を与える 
	var has_low_spec_bonus = magic_val <= (magic_max / 2)
	
	# --- ボーナスの抽選 ---
	var bonuses = _generate_bonuses(rarity, has_low_spec_bonus)
	
	# スキルの抽選
	var skill_id = "NONE"
	if rarity >= Rarity.UC:
		skill_id = SkillFactory.get_random_skill_id(rarity)
		
	return {
		"my_id": 0,
		"cost": cost,
		"rarity": rarity,
		"power": total_power,
		"magic": magic_val,
		"skill_id": skill_id,
		"bonuses": bonuses, # 追加
		"leader_rank": 80
	}

static func _pick_rarity() -> int:
	var roll = randf()
	if roll < 0.10: return Rarity.SR
	elif roll < 0.35: return Rarity.R
	elif roll < 0.65: return Rarity.UC
	else: return Rarity.C

static func _pick_cost() -> int:
	var roll = randf()
	if roll < 0.05: return 30
	elif roll < 0.20: return 25
	elif roll < 0.40: return 20
	elif roll < 0.70: return 15
	else: return 10

## ボーナス抽選用サブ関数
static func _generate_bonuses(rarity: int, low_spec: bool) -> Array:
	var result = []
	var bonus_pool = [
		"HPボーナス", "先制ボーナス", "反撃ボーナス", "加護ボーナス",
		"格上ボーナス", "回復ボーナス", "マナボーナス", "復讐ボーナス"
	]
	
	# 付与数の決定 
	var count = 0
	if rarity == Rarity.R: count = 1
	elif rarity == Rarity.SR: count = 2
	
	if low_spec: count += 1 # 低スペック補正で+1 
	
	# 最大3つまで 
	count = min(count, 3)
	
	# 重複ありで抽選
	bonus_pool.shuffle()
	for i in range(count):
		result.append(bonus_pool.pick_random()) # pop_back ではなく pick_random を使う
		
	return result



static func _print_debug_log(data: Dictionary) -> void:
	print("--- キャラクター生成結果 ---")
	print("名前: ", data["name"])
	print("POWER : ", data["power"], " / MAGIC : ", data["magic"])
	if data.has("gold"):
		print("所持金: ", data["gold"], " G")
	print("---------------------------")
