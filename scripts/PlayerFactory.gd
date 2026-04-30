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
	
	# 3. 辞書データにまとめて返す
	var data = {
		"name": player_name,
		"rarity": rarity,
		"atk": atk,
		"int": int_val,
		"cost": 10,
		"my_id": 0,
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
