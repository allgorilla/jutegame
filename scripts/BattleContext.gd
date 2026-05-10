extends Node

# 戦闘中の動的な状態（コンテキスト）を管理するクラス
# Autoload (Singleton) として登録することを推奨

# パーティごとの情報を格納する構造体（Dictionary）
var player_party = {
	"party_name": "",
	"front_units": [],
	"back_units": []
}

var enemy_party = {
	"party_name": "",
	"front_units": [],
	"back_units": []
}

# 戦闘全体のログやフラグ
var turn_count: int = 1
var is_battle_over: bool = false

# 外部（BattleManager等）から呼び出すメインのセットアップ関数
func setup_battle(player_raw_data: Dictionary, enemy_raw_data: Dictionary):
	_reset()
	
	# プレイヤー側とエネミー側、それぞれ共通のサブ関数で初期化
	_setup_party_context(player_party, player_raw_data)
	_setup_party_context(enemy_party, enemy_raw_data)
	
	print("BattleContext: Setup complete.")
	print("Player: ", player_party.party_name, " (F:", player_party.front_units.size(), " B:", player_party.back_units.size(), ")")
	print("Enemy: ", enemy_party.party_name, " (F:", enemy_party.front_units.size(), " B:", enemy_party.back_units.size(), ")")

# サブ関数：指定されたパーティオブジェクトにデータを流し込む
func _setup_party_context(party_obj: Dictionary, raw_data: Dictionary):
	party_obj.party_name = raw_data.get("party_name", "不明な軍団")
	
	var units = raw_data.get("unit_list", [])
	for unit in units:
		# ユニットの基本データに動的パラメータを付与
		var battle_unit = _create_battle_unit_state(unit)
		
		# 配置情報に基づいて前後配列に振り分け
		if unit.position.row == "front":
			party_obj.front_units.append(battle_unit)
		else:
			party_obj.back_units.append(battle_unit)

func _create_battle_unit_state(unit_data: Dictionary) -> Dictionary:
	# マスターデータをコピーし、戦闘中に変化する値を追加
	var state = unit_data.duplicate(true)
	state["current_hp"] = unit_data.get("hp", 10)
	state["current_mp"] = unit_data.get("mp", 0)
	state["is_dead"] = false
	state["buffs"] = []
	return state

func _reset():
	player_party = {"party_name": "", "front_units": [], "back_units": []}
	enemy_party = {"party_name": "", "front_units": [], "back_units": []}
	turn_count = 1
	is_battle_over = false
