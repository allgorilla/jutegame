extends Node

# ユニット（PC/エネミー共通）のマスターデータを管理するモジュール
# IDをキーにして、個体の基礎ステータスを返却する
const UNIT_TABLE = {
	"1189": {
		"cost": 25, "is_pc": false, "leader_rank": 80, "magic": 1, "my_id": 1189,
		"name": "怒れるシャドウ", "power": 10, "rarity": 0, "skill_id": "NONE",
		"image_id": "01" # 割り当て
	},
	"1190": {
		"cost": 20, "is_pc": false, "leader_rank": 80, "magic": 2, "my_id": 1190,
		"name": "ベイン呻き", "power": 8, "rarity": 2, "skill_id": "FRONT_TRIUMPH",
		"image_id": "02"
	},
	"1191": {
		"cost": 10, "is_pc": false, "leader_rank": 80, "magic": 2, "my_id": 1191,
		"name": "新兵オズ", "power": 2, "rarity": 1, "skill_id": "FRONT_SACRIFICE",
		"image_id": "03"
	},
	"1192": {
		"cost": 10, "is_pc": false, "leader_rank": 80, "magic": 3, "my_id": 1192,
		"name": "邪悪なカオス", "power": 4, "rarity": 3, "skill_id": "FRONT_PHOENIX",
		"image_id": "04"
	},
	"1193": {
		"cost": 30, "is_pc": false, "leader_rank": 80, "magic": 2, "my_id": 1193,
		"name": "美しきユリス", "power": 10, "rarity": 1, "skill_id": "MANA_REMNANT",
		"image_id": "05"
	},
	"1194": {
		"cost": 25, "is_pc": false, "leader_rank": 80, "magic": 10, "my_id": 1194,
		"name": "レギス一世", "power": 7, "rarity": 0, "skill_id": "NONE",
		"image_id": "06"
	},
	"1195": {
		"cost": 30, "is_pc": false, "leader_rank": 80, "magic": 3, "my_id": 1195,
		"name": "盗賊タルト", "power": 11, "rarity": 0, "skill_id": "NONE",
		"image_id": "07"
	},
	"1197": {
		"cost": 10, "is_pc": false, "leader_rank": 80, "magic": 3, "my_id": 1197,
		"name": "邪神イリス", "power": 3, "rarity": 0, "skill_id": "NONE",
		"image_id": "08"
	},
	"1198": {
		"cost": 25, "is_pc": false, "leader_rank": 80, "magic": 3, "my_id": 1198,
		"name": "ヴォイド磨ぎ", "power": 10, "rarity": 0, "skill_id": "NONE",
		"image_id": "09"
	},
	"1199": {
		"cost": 30, "is_pc": false, "leader_rank": 80, "magic": 8, "my_id": 1199,
		"name": "氷のウルス", "power": 10, "rarity": 1, "skill_id": "LUMINOUS_PURGE",
		"image_id": "10"
	},
	"1200": {
		"cost": 10, "is_pc": false, "leader_rank": 80, "magic": 8, "my_id": 1200,
		"name": "カオス拭い", "power": 2, "rarity": 1, "skill_id": "ABSOLUTE_ZERO",
		"image_id": "11"
	},
	"1203": {
		"cost": 20, "is_pc": false, "leader_rank": 80, "magic": 2, "my_id": 1203,
		"name": "忍者ルミナ", "power": 5, "rarity": 1, "skill_id": "FRONT_RAT_BITE",
		"image_id": "12"
	},
	"1204": {
		"cost": 20, "is_pc": false, "leader_rank": 80, "magic": 4, "my_id": 1204,
		"name": "ダーク拭い", "power": 5, "rarity": 1, "skill_id": "THUNDER_AMBUSH",
		"image_id": "01" # 重複
	},
	"1205": {
		"cost": 20, "is_pc": false, "leader_rank": 80, "magic": 4, "my_id": 1205,
		"name": "テイル直し", "power": 6, "rarity": 2, "skill_id": "BERSERK",
		"image_id": "02" # 重複
	},
	"1206": {
		"cost": 30, "is_pc": false, "leader_rank": 80, "magic": 5, "my_id": 1206,
		"name": "クロス裂き", "power": 11, "rarity": 1, "skill_id": "SLOW",
		"image_id": "03" # 重複
	}
}

# 指定されたIDのユニットデータを取得する
func get_unit_data(unit_id) -> Dictionary:
	var id_str = str(unit_id)
	if not UNIT_TABLE.has(id_str):
		push_error("Unit ID not found in UnitMaster: ", id_str)
		return {}
	
	# 元データを保護するため複製を返す
	return UNIT_TABLE[id_str].duplicate()

# 複数のIDから一括取得
func get_units_batch(unit_ids: Array) -> Array:
	var list = []
	for id in unit_ids:
		var data = get_unit_data(id)
		if not data.is_empty():
			list.append(data)
	return list

# IDの存在確認
func has_unit(unit_id) -> bool:
	return UNIT_TABLE.has(str(unit_id))
