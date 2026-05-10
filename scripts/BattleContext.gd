extends Node

# 戦闘中の動的な状態（コンテキスト）を管理するクラス
# Autoload (Singleton) として登録することを推奨

var party_name: String = ""
var front_units: Array = []
var back_units: Array = []

# 戦闘全体のログやフラグ
var turn_count: int = 1
var is_battle_over: bool = false

# EncounterMaster等からの生データをコンテキスト用に変換してセットする
func setup_context(raw_data: Dictionary):
	_reset()
	
	self.party_name = raw_data.get("party_name", "不明な軍団")
	
	# 生のユニットリストを前後配列に振り分ける
	var units = raw_data.get("unit_list", [])
	for unit in units:
		# ユニットの基本データに、戦闘中のHP等の動的パラメータを付与
		var battle_unit = _create_battle_unit_state(unit)
		
		if unit.position.row == "front":
			front_units.append(battle_unit)
		else:
			back_units.append(battle_unit)
	
	print("BattleContext: Setup complete. Front:", front_units.size(), " Back:", back_units.size())

func _create_battle_unit_state(unit_data: Dictionary) -> Dictionary:
	# マスターデータ(不変)をコピーし、戦闘中に変化する値(動的)を追加する
	var state = unit_data.duplicate(true)
	state["current_hp"] = unit_data.get("hp", 10)
	state["current_mp"] = unit_data.get("mp", 0)
	state["is_dead"] = false
	state["buffs"] = []
	return state

func _reset():
	party_name = ""
	front_units = []
	back_units = []
	turn_count = 1
	is_battle_over = false

# 特定のユニットが倒れた時に配列から除去、またはフラグを立てる等の処理もここで行う
func check_unit_death():
	# 例: HP0のユニットを処理するロジックなど
	pass
