# PlayerFactory.gd
class_name PlayerFactory

static func create_initial_data(player_name: String) -> Dictionary:
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
		"atk": atk,
		"int": int_val,
		"cost": 10,
		"my_id": 0
	}
	
	print("--- キャラクター生成結果 ---")
	print("名前: ", player_name)
	print("ATK : ", atk, " / INT : ", int_val)
	print("---------------------------")
	
	return data
