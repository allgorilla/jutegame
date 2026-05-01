# PlayerFactory.gd
class_name PlayerFactory

enum Rarity { C, UC, R, SR }

static func create_initial_data(player_name: String) -> Dictionary:
	# レアリティを決定
	var rarity = _pick_rarity()
	
	# 1. まずは ATK を 1～4 で決める
	var atk = randi_range(1, 4)
	var int_val = 0
	
	# 2. ATK の値に応じて INT の範囲を分岐させる
	match atk:
		1:
			int_val = randi_range(1, 10)
		2:
			int_val = randi_range(1, 8)
		3:
			int_val = randi_range(1, 6)
		4:
			int_val = randi_range(1, 4)
	
	# 3. スキルを抽選する。
	var skill_id = "NONE"
	if rarity >= 1: # UC以上なら抽選
		skill_id = SkillFactory.get_random_skill_id( rarity )
		
	# 4. 辞書データにまとめて返す
	var data = {
		"my_id": 0,
		"name": player_name,
		"cost": 10,
		"rarity": rarity,
		"atk": atk,
		"int": int_val,
		"skill_id": skill_id,
		"gold": 500,
		"soldiers": []
	}
	
	print("--- キャラクター生成結果 ---")
	print("名前: ", player_name)
	print("ATK : ", atk, " / INT : ", int_val)
	print("所持金: ", data["gold"], " G") # デバッグ表示も追加
	print("---------------------------")
	
	return data

static func _pick_rarity() -> int:
	var roll = randf() # 0.0 から 1.0 の間で抽選
	
	if roll < 0.02:    # 2%
		return Rarity.SR
	elif roll < 0.20:  # 2% + 18% = 20%
		return Rarity.R
	elif roll < 0.60:  # 20% + 40% = 60%
		return Rarity.UC
	else:              # 残り 40%
		return Rarity.C
