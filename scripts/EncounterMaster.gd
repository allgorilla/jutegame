extends Node

# パーティ編成（軍の情報）を管理するモジュール
# マップの赤ドットから参照されるPartyIDに基づき、戦闘に必要な全ての情報を集約する

# パーティ構成のルール:
# 1. 最大8人まで。
# 2. 前列(front)に最低1人いなければ、後列(back)に配置できない（バリデーションでチェック）。

const PARTY_TABLE = {
	"shadow_squad_01": {
		"party_name": "影の追跡者たち",
		"units": ["1189", "1190", "1203"],
		"formation": {
			"0": {"unit_id": "1189", "row": "front", "index": 1},
			"1": {"unit_id": "1190", "row": "back", "index": 0},
			"2": {"unit_id": "1203", "row": "back", "index": 2}
		},
		"ai_id": "standard_enemy_ai",
		"loot_id": "forest_common_loot"
	},
	"regis_full_army": {
		"party_name": "レギス一世と影の軍団",
		"units": ["1189", "1190", "1191", "1192", "1193", "1194", "1195", "1197"],
		"formation": {
			"0": {"unit_id": "1189", "row": "front", "index": 0},
			"1": {"unit_id": "1190", "row": "front", "index": 1},
			"2": {"unit_id": "1191", "row": "front", "index": 2},
			"3": {"unit_id": "1192", "row": "front", "index": 3},
			"4": {"unit_id": "1193", "row": "front", "index": 1}, # レギス一世
			"5": {"unit_id": "1194", "row": "back", "index": 0},
			"6": {"unit_id": "1195", "row": "back", "index": 2},
			"7": {"unit_id": "1197", "row": "back", "index": 3}
		},
		"ai_id": "boss_legion_ai",
		"loot_id": "royal_legend_loot"
	},
	"frost_legion": {
		"party_name": "氷獄の騎士団",
		"units": ["1198", "1199", "1200", "1203", "1204", "1205", "1206", "1206"],
		"formation": {
			"0": {"unit_id": "1198", "row": "front", "index": 0}, # 氷のウルス
			"1": {"unit_id": "1199", "row": "front", "index": 1}, # テイル直し
			"2": {"unit_id": "1200", "row": "back", "index": 2}, # クロス裂き
			"3": {"unit_id": "1203", "row": "back", "index": 3}, # ヴォイド磨ぎ
			"4": {"unit_id": "1204", "row": "back", "index": 0},  # カオス拭い
			"5": {"unit_id": "1205", "row": "back", "index": 1},  # ダーク拭い
			"6": {"unit_id": "1206", "row": "back", "index": 2},  # 忍者ルミナ
			"7": {"unit_id": "1206", "row": "back", "index": 3}   # 怒れるシャドウ
		},
		"ai_id": "tactical_freeze_ai",
		"loot_id": "glacier_rare_loot"
	},	
	"chaos_duo": {
		"party_name": "混沌の二人組",
		"units": ["1192", "1200"],
		"formation": {
			"0": {"unit_id": "1192", "row": "front", "index": 0},
			"1": {"unit_id": "1200", "row": "front", "index": 2}
		},
		"ai_id": "aggressive_ai",
		"loot_id": "chaos_drop"
	}
}

# バトルシーン開始時に呼び出すメインインターフェース
func get_battle_setup_data(party_id: String) -> Dictionary:
	if not PARTY_TABLE.has(party_id):
		push_error("EncounterMaster: Party ID not found -> ", party_id)
		return {}

	var raw = PARTY_TABLE[party_id]
	
	# バリデーション: 前列に1人以上いるか確認
	if not _validate_formation(raw.formation):
		push_error("EncounterMaster: Invalid formation for ", party_id, ". Front row must have at least 1 unit.")
		return {}
	
	var setup_data = {
		"party_name": raw.party_name,
		"unit_list": [],
		"ai_data": {},
		"reward_data": {}
	}

	# formationのキーを回して配置順にリストを作成
	# 同じユニットIDが複数いる場合も、ユニークなインスタンス情報として扱う
	for f_key in raw.formation:
		var f_info = raw.formation[f_key]
		var stats = UnitMaster.get_unit_data(f_info.unit_id)
		
		if stats.is_empty(): continue
		
		# 配置情報を付与
		stats["position"] = {
			"row": f_info.row,
			"index": f_info.index
		}
		
		setup_data.unit_list.append(stats)
	
	return setup_data

# 前列に最低1人いるかチェックする内部関数
func _validate_formation(formation: Dictionary) -> bool:
	for f_key in formation:
		if formation[f_key].row == "front":
			return true
	return false

# 指定したIDのパーティが存在するか確認
func has_party(party_id: String) -> bool:
	return PARTY_TABLE.has(party_id)
